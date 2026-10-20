import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymgen_ai/models/workout_models.dart';
import 'package:gymgen_ai/models/assessment_model.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';
import 'package:gymgen_ai/services/workout_generator_service.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutPlan? _plan;
  List<WorkoutLog> _logs = [];
  bool _loading = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>?>? _planSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _logsSubscription;
  StreamSubscription<Map<String, dynamic>?>? _progressSubscription;

  String _uid = '';

  bool _sessionActive = false;
  WorkoutDay? _activeDay;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _elapsedSeconds = 0;
  DateTime? _activeSessionDate;
  List<bool> _completedExercises = [];

  final Map<String, List<String>> _dailyProgress = {};

  WorkoutPlan? get plan => _plan;
  List<WorkoutLog> get logs => _logs;
  bool get loading => _loading;
  String? get error => _error;
  bool get sessionActive => _sessionActive;
  WorkoutDay? get activeDay => _activeDay;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSet => _currentSet;
  int get elapsedSeconds => _elapsedSeconds;
  DateTime? get activeSessionDate => _activeSessionDate;
  List<bool> get completedExercises =>
      List.unmodifiable(_completedExercises);

  // ── New helpers ─────────────────────────────────────────────────────────────

  int get pendingCount => _completedExercises.where((c) => !c).length;

  bool get allExercisesDone =>
      _activeDay != null &&
      _completedExercises.isNotEmpty &&
      pendingCount == 0;

  /// Next not-completed exercise after the current one, wrapping around.
  int? _nextPendingIndex() {
    final day = _activeDay;
    if (day == null) return null;
    final n = day.exercises.length;
    for (var step = 1; step < n; step++) {
      final i = (_currentExerciseIndex + step) % n;
      if (i < _completedExercises.length && !_completedExercises[i]) {
        return i;
      }
    }
    return null;
  }

  // ── Keys ────────────────────────────────────────────────────────────────────

  String _dateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _dayKey(WorkoutDay day, [DateTime? date]) =>
      '${_dateKey(date)}::'
      '${day.dayLabel.trim().toLowerCase()}::'
      '${day.focus.trim().toLowerCase()}';

  String _exerciseKey(Exercise exercise) =>
      exercise.id.trim().isNotEmpty
          ? exercise.id
          : exercise.name.trim().toLowerCase();

  bool isExerciseDone(
    WorkoutDay day,
    Exercise exercise, {
    DateTime? date,
  }) =>
      (_dailyProgress[_dayKey(day, date)] ?? const <String>[])
          .contains(_exerciseKey(exercise));

  int completedCountForDay(
    WorkoutDay day, {
    DateTime? date,
  }) =>
      day.exercises
          .where((e) => isExerciseDone(day, e, date: date))
          .length;

  WorkoutDay? get todayWorkout {
    if (_plan == null || _plan!.days.isEmpty) return null;

    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final today = weekdayNames[DateTime.now().weekday - 1];

    for (final day in _plan!.days) {
      if (day.dayLabel.toLowerCase() == today.toLowerCase()) {
        return day;
      }
    }
    return null;
  }

  int get completedLogs => _logs.where((log) => log.isComplete).length;

  bool get workoutCompletedToday => _logs.any((log) {
        final date = log.date;
        final now = DateTime.now();
        return log.isComplete &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      });

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> load(String uid) async {
    await _planSubscription?.cancel();
    await _logsSubscription?.cancel();
    await _progressSubscription?.cancel();

    if (_uid != uid) {
      _plan = null;
      _logs = [];
      _dailyProgress.clear();
      _error = null;
      _sessionActive = false;
      _activeDay = null;
      _currentExerciseIndex = 0;
      _currentSet = 1;
      _elapsedSeconds = 0;
      _activeSessionDate = null;
      _completedExercises = [];
    }

    _uid = uid;

    if (uid.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final planData =
          await LocalStorageService.instance.loadWorkoutPlan(uid);
      if (planData != null) {
        _plan = WorkoutPlan.fromJson(planData);
      }

      final logData =
          await LocalStorageService.instance.loadWorkoutLogs(uid);
      _logs = logData
          .map((d) => WorkoutLog.fromJson(d))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final progressData =
          await LocalStorageService.instance.loadWorkoutProgress(uid);
      _dailyProgress
        ..clear()
        ..addAll(
          (progressData ?? <String, List<String>>{}).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );

      final savedSession =
          await LocalStorageService.instance.loadWorkoutSession(uid);
      _restoreSession(savedSession);

      _planSubscription = LocalStorageService.instance
          .watchMapData(uid, 'workoutPlan')
          .listen(
        (data) {
          if (data != null) {
            _plan = WorkoutPlan.fromJson(data);
          }
          notifyListeners();
        },
        onError: (Object error) {
          _error = 'Workout plan sync failed: $error';
          notifyListeners();
        },
      );

      _logsSubscription = LocalStorageService.instance
          .watchListData(uid, 'workoutLogs')
          .listen(
        (data) {
          _logs = data.map(WorkoutLog.fromJson).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          notifyListeners();
        },
        onError: (Object error) {
          _error = 'Workout history sync failed: $error';
          notifyListeners();
        },
      );

      _progressSubscription = LocalStorageService.instance
          .watchMapData(uid, 'workoutProgress')
          .listen(
        (data) {
          if (data == null) return;

          _dailyProgress
            ..clear()
            ..addAll(
              data.map(
                (key, value) =>
                    MapEntry(key, List<String>.from(value as List)),
              ),
            );

          if (_activeDay != null) {
            final ids = _dailyProgress[
                    _dayKey(_activeDay!, _activeSessionDate)] ??
                const <String>[];
            _completedExercises = _activeDay!.exercises
                .map((e) => ids.contains(_exerciseKey(e)))
                .toList();
          }
          notifyListeners();
        },
        onError: (Object error) {
          _error = 'Workout progress sync failed: $error';
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void _restoreSession(Map<String, dynamic>? saved) {
    if (saved == null || saved['active'] != true || _plan == null) {
      return;
    }

    final focus = (saved['focus'] as String? ?? '').toLowerCase();
    final dayLabel = (saved['dayLabel'] as String? ?? '').toLowerCase();

    WorkoutDay? found;
    for (final day in _plan!.days) {
      if (day.focus.toLowerCase() == focus &&
          day.dayLabel.toLowerCase() == dayLabel) {
        found = day;
        break;
      }
    }

    if (found == null || found.exercises.isEmpty) return;

    _activeDay = found;
    _sessionActive = true;

    _currentExerciseIndex =
        ((saved['currentExerciseIndex'] as num?)?.toInt() ?? 0)
            .clamp(0, found.exercises.length - 1)
            .toInt();

    _currentSet = ((saved['currentSet'] as num?)?.toInt() ?? 1)
        .clamp(1, found.exercises[_currentExerciseIndex].sets)
        .toInt();

    _elapsedSeconds = (saved['elapsedSeconds'] as num?)?.toInt() ?? 0;

    _activeSessionDate =
        DateTime.tryParse(saved['sessionDate'] as String? ?? '') ??
            DateTime.now();

    final stored = (saved['completedExercises'] as List? ?? const [])
        .map((v) => v == true)
        .toList();

    _completedExercises = List<bool>.generate(
      found.exercises.length,
      (i) => i < stored.length && stored[i],
    );

    final key = _dayKey(found, _activeSessionDate);
    final ids = _dailyProgress[key] ?? <String>[];

    for (var i = 0; i < found.exercises.length; i++) {
      if (ids.contains(_exerciseKey(found.exercises[i]))) {
        _completedExercises[i] = true;
      }
    }
  }

  Future<void> generatePlan(String uid, Assessment assessment) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _uid = uid;
      _plan = WorkoutGeneratorService.instance.generatePlan(assessment);
      await LocalStorageService.instance.saveWorkoutPlan(
        uid,
        _plan!.toJson(),
      );
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  // ── Session ─────────────────────────────────────────────────────────────────

  void startSession(WorkoutDay day) {
    if (_sessionActive &&
        _activeDay?.focus == day.focus &&
        _activeDay?.dayLabel == day.dayLabel) {
      return;
    }

    _activeDay = day;
    _currentSet = 1;
    _elapsedSeconds = 0;
    _activeSessionDate = DateTime.now();
    _sessionActive = true;

    final doneIds =
        _dailyProgress[_dayKey(day, _activeSessionDate)] ??
            const <String>[];

    _completedExercises = day.exercises
        .map((e) => doneIds.contains(_exerciseKey(e)))
        .toList();

    // Start at the first unfinished exercise, not always exercise 1.
    final firstPending = _completedExercises.indexWhere((c) => !c);
    _currentExerciseIndex = firstPending == -1 ? 0 : firstPending;

    unawaited(_persistSession());
    notifyListeners();
  }

  void updateElapsedSeconds(int seconds) {
    if (!_sessionActive) return;
    _elapsedSeconds = seconds;
    if (seconds % 5 == 0) {
      unawaited(_persistSession());
    }
  }

  Future<void> completeSet() async {
    final day = _activeDay;
    if (day == null || day.exercises.isEmpty) return;

    final exercise = day.exercises[_currentExerciseIndex];

    if (_currentSet >= exercise.sets) {
      _completedExercises[_currentExerciseIndex] = true;

      final key = _dayKey(day, _activeSessionDate);
      final ids = _dailyProgress.putIfAbsent(key, () => <String>[]);
      if (!ids.contains(_exerciseKey(exercise))) {
        ids.add(_exerciseKey(exercise));
      }
      await _saveDailyProgress();

      final next = _nextPendingIndex();
      if (next != null) {
        _currentExerciseIndex = next;
        _currentSet = 1;
      }
    } else {
      _currentSet++;
    }

    await _persistSession();
    notifyListeners();
  }

  /// Moves to the next unfinished exercise (wrapping around).
  /// Returns false if there is nothing else left to move to.
  Future<bool> skipExercise() async {
    final next = _nextPendingIndex();
    if (next == null) return false;

    _currentExerciseIndex = next;
    _currentSet = 1;
    await _persistSession();
    notifyListeners();
    return true;
  }

  Future<void> _saveDailyProgress() async {
    if (_uid.isEmpty) return;

    try {
      await LocalStorageService.instance.saveWorkoutProgress(
        _uid,
        _dailyProgress.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
    } catch (e) {
      _error = 'Progress saved locally; cloud sync failed: $e';
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    if (_uid.isEmpty || _activeDay == null) return;

    try {
      await LocalStorageService.instance.saveWorkoutSession(
        _uid,
        {
          'active': _sessionActive,
          'focus': _activeDay!.focus,
          'dayLabel': _activeDay!.dayLabel,
          'currentExerciseIndex': _currentExerciseIndex,
          'currentSet': _currentSet,
          'elapsedSeconds': _elapsedSeconds,
          'sessionDate':
              (_activeSessionDate ?? DateTime.now()).toIso8601String(),
          'completedExercises': _completedExercises,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _error = 'Session saved locally; cloud sync failed: $e';
      notifyListeners();
    }
  }

  Future<WorkoutLog?> finishSession(
    String uid, {
    required int elapsedSeconds,
    required double bodyWeightKg,
  }) async {
    final day = _activeDay;
    if (day == null) return null;

    final completedCount = _completedExercises.where((c) => c).length;

    final elapsedMinutes =
        elapsedSeconds <= 0 ? 0 : (elapsedSeconds / 60).ceil();

    final estimatedCalories = bodyWeightKg > 0
        ? (5.0 * 3.5 * bodyWeightKg / 200 * elapsedMinutes).round()
        : 0;

    final log = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutName: day.focus,
      durationMinutes: elapsedMinutes,
      caloriesBurned: estimatedCalories,
      exercisesCompleted: completedCount,
      exercisesPlanned: day.exercises.length,
      date: DateTime.now(),
    );

    _logs.insert(0, log);

    _sessionActive = false;
    _activeDay = null;
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _elapsedSeconds = 0;
    _activeSessionDate = null;
    _completedExercises = [];

    notifyListeners();

    try {
      await LocalStorageService.instance.saveWorkoutLogs(
        uid,
        _logs.map((l) => l.toJson()).toList(),
      );
      _error = null;
    } catch (e) {
      _error = 'Workout saved locally; cloud sync failed: $e';
    } finally {
      try {
        await LocalStorageService.instance.clearWorkoutSession(uid);
      } catch (_) {
        // A later load can recover the local state.
      }
    }

    notifyListeners();
    return log;
  }

  void cancelSession() {
    _sessionActive = false;
    _activeDay = null;
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _elapsedSeconds = 0;
    _activeSessionDate = null;
    _completedExercises = [];

    if (_uid.isNotEmpty) {
      unawaited(LocalStorageService.instance.clearWorkoutSession(_uid));
    }

    notifyListeners();
  }

  double get sessionProgress {
    final day = _activeDay;
    if (day == null || day.exercises.isEmpty) return 0.0;

    var totalSets = 0;
    var completedSets = 0;

    for (var i = 0; i < day.exercises.length; i++) {
      final sets = day.exercises[i].sets;
      if (sets <= 0) continue;

      totalSets += sets;

      if (i < _completedExercises.length && _completedExercises[i]) {
        completedSets += sets;
      } else if (i == _currentExerciseIndex) {
        completedSets += (_currentSet - 1).clamp(0, sets).toInt();
      }
    }

    if (totalSets == 0) return 0.0;
    return (completedSets / totalSets).clamp(0.0, 1.0).toDouble();
  }

  @override
  void dispose() {
    _planSubscription?.cancel();
    _logsSubscription?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }
}