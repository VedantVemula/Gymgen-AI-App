import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymgen_ai/services/mongo_api_service.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const _onboardingKey = 'onboarding_completed';
  static const _profileKeyPrefix = 'profile_';
  static const _workoutLogsKeyPrefix = 'workout_logs_';
  static const _nutritionKeyPrefix = 'nutrition_';
  static const _progressKeyPrefix = 'progress_';
  static const _statsKeyPrefix = 'stats_';
  static const _workoutPlanKeyPrefix = 'workout_plan_';
  static const _chatKeyPrefix = 'chat_';
  static const _waterKeyPrefix = 'water_';
  static const _assessmentHistoryKeyPrefix = 'assessment_history_';

  static const _pollEvery = Duration(seconds: 15);

  final _api = MongoApiService.instance;

  // Prevents a background refresh from overwriting data you just saved.
  int _pendingWrites = 0;
  int _writeEpoch = 0;

  Future<void> _write(Future<void> Function() action) async {
    _pendingWrites++;
    _writeEpoch++;
    try {
      await action();
    } finally {
      _pendingWrites--;
      _writeEpoch++;
    }
  }

  Map<String, dynamic>? _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  List<Map<String, dynamic>>? _asList(Object? v) => v is List
      ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : null;

  /// Re-checks the server every 15s and emits only when data changed
  /// (for example, edited from another device).
  Stream<T> _poll<T>(Future<T> Function() fetch) {
    late final StreamController<T> controller;
    Timer? timer;
    String? last;
    var busy = false;

    Future<void> tick() async {
      if (busy || _pendingWrites > 0) return;
      busy = true;
      final epoch = _writeEpoch;
      try {
        final value = await fetch();
        if (controller.isClosed ||
            epoch != _writeEpoch ||
            _pendingWrites > 0) {
          return;
        }
        final encoded = jsonEncode(value);
        if (encoded == last) return;
        last = encoded;
        controller.add(value);
      } catch (_) {
        // Offline or server down: try again next time.
      } finally {
        busy = false;
      }
    }

    controller = StreamController<T>(
      onListen: () => timer = Timer.periodic(_pollEvery, (_) => tick()),
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }

  // ---------- Onboarding ----------

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // ---------- Profile ----------

  Future<void> saveProfile(String uid, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_profileKeyPrefix$uid', jsonEncode(data));
    await _write(() => _api.put(uid, 'profile', data, merge: true));
  }

  Future<Map<String, dynamic>?> loadProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final cloud = _asMap(await _api.get(uid, 'profile'));
      if (cloud != null) {
        await prefs.setString('$_profileKeyPrefix$uid', jsonEncode(cloud));
        return cloud;
      }
    } catch (_) {
      // Fall back to the copy saved on this device.
    }
    return _decodeMap(prefs.getString('$_profileKeyPrefix$uid'));
  }

  Stream<Map<String, dynamic>?> watchProfile(String uid) =>
      _poll<Map<String, dynamic>?>(
          () async => _asMap(await _api.get(uid, 'profile')));

  Stream<Map<String, dynamic>?> watchMapData(String uid, String docKey) =>
      _poll<Map<String, dynamic>?>(
          () async => _asMap(await _api.get(uid, docKey)));

  Stream<List<Map<String, dynamic>>> watchListData(
          String uid, String docKey) =>
      _poll<List<Map<String, dynamic>>>(() async =>
          _asList(await _api.get(uid, docKey)) ?? <Map<String, dynamic>>[]);

  Future<Map<String, dynamic>?> loadProfileForUser(
    String uid,
    String email,
  ) async {
    var cloudReachable = true;
    final prefs = await SharedPreferences.getInstance();

    try {
      final cloud = _asMap(await _api.get(uid, 'profile'));
      if (cloud != null) {
        await prefs.setString('$_profileKeyPrefix$uid', jsonEncode(cloud));
        return cloud;
      }
    } catch (_) {
      cloudReachable = false;
    }

    // Nothing in MongoDB yet: adopt a profile saved on this device.
    final existing = _decodeMap(prefs.getString('$_profileKeyPrefix$uid'));
    if (existing != null) {
      final migrated = {...existing, 'uid': uid, 'email': email};
      if (cloudReachable) await saveProfile(uid, migrated);
      return migrated;
    }

    final normalizedEmail = email.trim().toLowerCase();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_profileKeyPrefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final profile = jsonDecode(raw) as Map<String, dynamic>;
        final savedEmail =
            (profile['email'] as String? ?? '').trim().toLowerCase();
        if (savedEmail == normalizedEmail) {
          final migrated = {...profile, 'uid': uid, 'email': email};
          if (cloudReachable) await saveProfile(uid, migrated);
          return migrated;
        }
      } catch (_) {
        // Ignore malformed entries.
      }
    }
    return null;
  }

  // ---------- Generic helpers ----------

  Future<void> _saveList(String uid, String docKey, String localKey,
      List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localKey, jsonEncode(items));
    await _write(() => _api.put(uid, docKey, items));
  }

  Future<List<Map<String, dynamic>>> _loadList(
      String uid, String docKey, String localKey) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final cloud = _asList(await _api.get(uid, docKey));
      if (cloud != null) {
        await prefs.setString(localKey, jsonEncode(cloud));
        return cloud;
      }
      // Nothing in MongoDB yet: upload what this device already has.
      final cached = _decodeList(prefs.getString(localKey));
      if (cached.isNotEmpty) await _api.put(uid, docKey, cached);
      return cached;
    } catch (_) {
      return _decodeList(prefs.getString(localKey));
    }
  }

  Future<void> _saveMap(String uid, String docKey, String localKey,
      Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localKey, jsonEncode(data));
    await _write(() => _api.put(uid, docKey, data));
  }

  Future<Map<String, dynamic>?> _loadMap(
      String uid, String docKey, String localKey) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final cloud = _asMap(await _api.get(uid, docKey));
      if (cloud != null) {
        await prefs.setString(localKey, jsonEncode(cloud));
        return cloud;
      }
      final cached = _decodeMap(prefs.getString(localKey));
      if (cached != null) await _api.put(uid, docKey, cached);
      return cached;
    } catch (_) {
      return _decodeMap(prefs.getString(localKey));
    }
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  // ---------- Workouts ----------

  Future<void> saveWorkoutLogs(String uid, List<Map<String, dynamic>> logs) =>
      _saveList(uid, 'workoutLogs', '$_workoutLogsKeyPrefix$uid', logs);

  Future<List<Map<String, dynamic>>> loadWorkoutLogs(String uid) =>
      _loadList(uid, 'workoutLogs', '$_workoutLogsKeyPrefix$uid');

  Future<void> saveWorkoutPlan(String uid, Map<String, dynamic> plan) =>
      _saveMap(uid, 'workoutPlan', '$_workoutPlanKeyPrefix$uid', plan);

  Future<Map<String, dynamic>?> loadWorkoutPlan(String uid) =>
      _loadMap(uid, 'workoutPlan', '$_workoutPlanKeyPrefix$uid');

  Future<void> saveWorkoutSession(String uid, Map<String, dynamic> session) =>
      _saveMap(uid, 'workoutSession', 'workout_session_$uid', session);

  Future<Map<String, dynamic>?> loadWorkoutSession(String uid) =>
      _loadMap(uid, 'workoutSession', 'workout_session_$uid');

  Future<void> saveWorkoutProgress(
          String uid, Map<String, dynamic> progress) =>
      _saveMap(uid, 'workoutProgress', 'workout_progress_$uid', progress);

  Future<Map<String, dynamic>?> loadWorkoutProgress(String uid) =>
      _loadMap(uid, 'workoutProgress', 'workout_progress_$uid');

  Future<void> clearWorkoutSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('workout_session_$uid');
    await _write(() => _api.put(uid, 'workoutSession', {
          'active': false,
          'updatedAt': DateTime.now().toIso8601String(),
        }));
  }

  // ---------- Nutrition ----------

  String _nutritionKey(String uid, String dateStr) =>
      '$_nutritionKeyPrefix${uid}_$dateStr';

  Future<void> saveNutritionEntries(
          String uid, String dateStr, List<Map<String, dynamic>> entries) =>
      _saveList(
          uid, 'nutrition_$dateStr', _nutritionKey(uid, dateStr), entries);

  Future<List<Map<String, dynamic>>> loadNutritionEntries(
          String uid, String dateStr) =>
      _loadList(uid, 'nutrition_$dateStr', _nutritionKey(uid, dateStr));

  String _waterKey(String uid, String dateStr) =>
      '$_waterKeyPrefix${uid}_$dateStr';

  Future<void> saveWater(String uid, String dateStr, double litres) =>
      _saveMap(
          uid, 'water_$dateStr', _waterKey(uid, dateStr), {'litres': litres});

  Future<double> loadWater(String uid, String dateStr) async {
    final data =
        await _loadMap(uid, 'water_$dateStr', _waterKey(uid, dateStr));
    return (data?['litres'] as num?)?.toDouble() ?? 0.0;
  }

  // ---------- Progress, stats, chat, assessments ----------

  Future<void> saveProgressEntries(
          String uid, List<Map<String, dynamic>> entries) =>
      _saveList(uid, 'progress', '$_progressKeyPrefix$uid', entries);

  Future<List<Map<String, dynamic>>> loadProgressEntries(String uid) =>
      _loadList(uid, 'progress', '$_progressKeyPrefix$uid');

  Future<void> saveStats(String uid, Map<String, dynamic> stats) =>
      _saveMap(uid, 'stats', '$_statsKeyPrefix$uid', stats);

  Future<Map<String, dynamic>?> loadStats(String uid) =>
      _loadMap(uid, 'stats', '$_statsKeyPrefix$uid');

  Future<void> saveChatMessages(
          String uid, List<Map<String, dynamic>> messages) =>
      _saveList(uid, 'chat', '$_chatKeyPrefix$uid', messages);

  Future<List<Map<String, dynamic>>> loadChatMessages(String uid) =>
      _loadList(uid, 'chat', '$_chatKeyPrefix$uid');

  Future<void> saveAssessmentHistory(
          String uid, List<Map<String, dynamic>> entries) =>
      _saveList(uid, 'assessmentHistory',
          '$_assessmentHistoryKeyPrefix$uid', entries);

  Future<List<Map<String, dynamic>>> loadAssessmentHistory(String uid) =>
      _loadList(uid, 'assessmentHistory',
          '$_assessmentHistoryKeyPrefix$uid');

  // ---------- Delete everything for a user ----------

  Future<void> clearUserData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.contains(uid)).toList()) {
      await prefs.remove(key);
    }
    await _api.deleteAll(uid);
  }
}