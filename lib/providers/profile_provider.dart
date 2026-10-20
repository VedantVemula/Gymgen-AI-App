import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymgen_ai/models/user_profile_model.dart';
import 'package:gymgen_ai/models/progress_models.dart';
import 'package:gymgen_ai/models/workout_models.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';

/// Shared source of truth for profile details and summary statistics.
class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  UserStats _stats = const UserStats();
  bool _loading = false;
  String? _error;
  String _uid = '';

  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  StreamSubscription<Map<String, dynamic>?>? _statsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _workoutSubscription;

  UserProfile? get profile => _profile;
  UserStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  String get displayName => _profile?.name.trim().isNotEmpty == true
      ? _profile!.name.trim()
      : 'Athlete';

  String get userId => _profile?.uid ?? _uid;

  Future<void> loadProfile(String uid, {String email = ''}) async {
    if (_uid != uid) {
      await _cancelSubscriptions();
      _profile = null;
      _stats = const UserStats();
    }

    _uid = uid;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final profileData =
          await LocalStorageService.instance.loadProfileForUser(uid, email);

      if (profileData != null) {
        _profile = UserProfile.fromJson(profileData);
      }

      final statsData =
          await LocalStorageService.instance.loadStats(uid);

      final savedStats = statsData == null
          ? const UserStats()
          : UserStats.fromJson(statsData);

      _stats = UserStats(
        totalWorkouts: savedStats.totalWorkouts,
        streakDays: savedStats.streakDays,
        currentWeightKg: _profile != null && _profile!.weightKg > 0
            ? _profile!.weightKg
            : savedStats.currentWeightKg,
        weeklyWeightChange: savedStats.weeklyWeightChange,
        totalCaloriesBurned: savedStats.totalCaloriesBurned,
      );

      await _cancelSubscriptions();

      // Listen for profile changes so dependent features can update.
      _profileSubscription = LocalStorageService.instance
          .watchProfile(uid)
          .listen((data) {
        if (data != null) {
          _profile = UserProfile.fromJson(data);

          final weight = _profile!.weightKg;

          if (weight > 0 && weight != _stats.currentWeightKg) {
            _stats = UserStats(
              totalWorkouts: _stats.totalWorkouts,
              streakDays: _stats.streakDays,
              currentWeightKg: weight,
              weeklyWeightChange: _stats.weeklyWeightChange,
              totalCaloriesBurned: _stats.totalCaloriesBurned,
            );
          }
        }

        notifyListeners();
      }, onError: (Object e) {
        _error = 'Profile sync failed: $e';
        notifyListeners();
      });

      _statsSubscription = LocalStorageService.instance
          .watchMapData(uid, 'stats')
          .listen((data) {
        final saved = data == null
            ? const UserStats()
            : UserStats.fromJson(data);

        _stats = UserStats(
          totalWorkouts: saved.totalWorkouts,
          streakDays: saved.streakDays,
          currentWeightKg: _profile != null && _profile!.weightKg > 0
              ? _profile!.weightKg
              : saved.currentWeightKg,
          weeklyWeightChange: saved.weeklyWeightChange,
          totalCaloriesBurned: saved.totalCaloriesBurned,
        );

        notifyListeners();
      }, onError: (Object e) {
        _error = 'Stats sync failed: $e';
        notifyListeners();
      });

      _workoutSubscription = LocalStorageService.instance
          .watchListData(uid, 'workoutLogs')
          .listen((items) {
        _applyWorkoutStats(
          items.map(WorkoutLog.fromJson).toList(),
        );
        notifyListeners();
      }, onError: (Object e) {
        _error = 'Workout stats sync failed: $e';
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    _uid = uid;

    _profile = UserProfile(
      uid: uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    notifyListeners();
    await _saveAndReport(_saveProfile);
  }

  /// Updates the profile immediately and persists the latest values.
  /// A changed weight also updates the shared weight statistics.
  Future<void> updateProfile(UserProfile updated) async {
    final previousWeight = _profile?.weightKg ?? _stats.currentWeightKg;

    final weightChanged = updated.weightKg > 0 &&
        (updated.weightKg - previousWeight).abs() > 0.001;

    _profile = updated;
    _uid = updated.uid;
    _error = null;

    if (weightChanged) {
      _stats = UserStats(
        totalWorkouts: _stats.totalWorkouts,
        streakDays: _stats.streakDays,
        currentWeightKg: updated.weightKg,
        weeklyWeightChange: updated.weightKg - previousWeight,
        totalCaloriesBurned: _stats.totalCaloriesBurned,
      );
    }

    notifyListeners();

    await _saveAndReport(() async {
      await _saveProfile();

      if (weightChanged) {
        await _saveStats();
      }
    });
  }

  Future<void> updateFromAssessment({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goal,
    required String experience,
    required String equipment,
    required int workoutDays,
    required String dietPreference,
  }) async {
    if (_profile == null) return;

    final oldWeight = _stats.currentWeightKg;

    _profile = _profile!.copyWith(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
      goal: goal,
      experience: experience,
      equipment: equipment,
      workoutDays: workoutDays,
      dietPreference: dietPreference,
    );

    _stats = UserStats(
      totalWorkouts: _stats.totalWorkouts,
      streakDays: _stats.streakDays,
      currentWeightKg: weightKg,
      weeklyWeightChange: weightKg - oldWeight,
      totalCaloriesBurned: _stats.totalCaloriesBurned,
    );

    notifyListeners();

    await _saveAndReport(() async {
      await _saveProfile();
      await _saveStats();
    });
  }

  Future<void> refreshWorkoutStats(List<WorkoutLog> logs) async {
    _applyWorkoutStats(logs);
    notifyListeners();
    await _saveAndReport(_saveStats);
  }

  void _applyWorkoutStats(List<WorkoutLog> logs) {
    final completed = logs.where((log) => log.isComplete).toList();

    final dates = completed
        .map((log) => DateTime(
              log.date.year,
              log.date.month,
              log.date.day,
            ))
        .toSet();

    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    if (!dates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;

    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    _stats = UserStats(
      totalWorkouts: completed.length,
      streakDays: streak,
      currentWeightKg: _profile != null && _profile!.weightKg > 0
          ? _profile!.weightKg
          : _stats.currentWeightKg,
      weeklyWeightChange: _stats.weeklyWeightChange,
      totalCaloriesBurned: logs.fold(
        0,
        (total, log) => total + log.caloriesBurned,
      ),
    );
  }

  Future<void> updateWeight(double weight) async {
    final previousWeight = _stats.currentWeightKg;

    _stats = UserStats(
      totalWorkouts: _stats.totalWorkouts,
      streakDays: _stats.streakDays,
      currentWeightKg: weight,
      weeklyWeightChange: weight - previousWeight,
      totalCaloriesBurned: _stats.totalCaloriesBurned,
    );

    if (_profile != null) {
      _profile = _profile!.copyWith(weightKg: weight);
    }

    notifyListeners();

    await _saveAndReport(() async {
      await _saveProfile();
      await _saveStats();
    });
  }

  Future<void> _saveAndReport(
    Future<void> Function() save,
  ) async {
    try {
      await save();
      _error = null;
    } catch (e) {
      _error = 'Saved on this device; cloud sync failed: $e';
    }

    notifyListeners();
  }

  Future<void> _saveProfile() async {
    if (_profile != null) {
      await LocalStorageService.instance.saveProfile(
        userId,
        _profile!.toJson(),
      );
    }
  }

  Future<void> _saveStats() async {
    await LocalStorageService.instance.saveStats(
      userId,
      _stats.toJson(),
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _profileSubscription?.cancel();
    await _statsSubscription?.cancel();
    await _workoutSubscription?.cancel();

    _profileSubscription = null;
    _statsSubscription = null;
    _workoutSubscription = null;
  }

  void signOut() {
    _cancelSubscriptions();
    _uid = '';
    _profile = null;
    _stats = const UserStats();
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _statsSubscription?.cancel();
    _workoutSubscription?.cancel();
    super.dispose();
  }
}