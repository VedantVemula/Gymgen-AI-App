import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';
import 'package:gymgen_ai/providers/profile_provider.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';
import 'package:gymgen_ai/models/workout_models.dart';
import 'package:video_player/video_player.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  static const routeName = '/workout-execution';

  const WorkoutExecutionScreen({super.key});

  @override
  State<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  int _restSeconds = 0;
  Timer? _restTimer;
  bool _resting = false;
  bool _paused = false;
  int _totalSeconds = 0;
  Timer? _workoutTimer;
  bool _finishing = false;
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = context.read<WorkoutProvider>().elapsedSeconds;
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _workoutTimer?.cancel();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!_paused && mounted) {
          setState(() => _totalSeconds++);
          context
              .read<WorkoutProvider>()
              .updateElapsedSeconds(_totalSeconds);
        }
      },
    );
  }

  void _startRest(int seconds) {
    setState(() {
      _resting = true;
      _restSeconds = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!_paused && mounted) {
          if (_restSeconds <= 1) {
            setState(() {
              _restSeconds = 0;
              _resting = false;
            });
            _restTimer?.cancel();
          } else {
            setState(() => _restSeconds--);
          }
        }
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _finishWorkout() async {
    if (_finishing) return;
    _finishing = true;

    _restTimer?.cancel();
    _workoutTimer?.cancel();

    final workout = context.read<WorkoutProvider>();
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    final weightKg =
        profile.profile?.weightKg ?? profile.stats.currentWeightKg;

    try {
      final log = await workout.finishSession(
        auth.userId,
        elapsedSeconds: _totalSeconds,
        bodyWeightKg: weightKg,
      );

      if (!mounted) return;
      setState(() => _celebrate = true);
      _showCompletionDialog(log);
    } catch (error) {
      _finishing = false;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save workout: $error')),
      );
    }
  }

  void _confirmEnd({String? message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End workout?'),
        content: Text(message ?? 'Your session summary will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _finishWorkout();
            },
            child: const Text(
              'End session',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(WorkoutLog? log) {
    final calories = log?.caloriesBurned;
    final partial =
        log != null && log.exercisesCompleted < log.exercisesPlanned;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppGradients.success,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.success),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              partial ? 'Workout Saved' : 'Workout Complete! 🎉',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            if (log != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${log.exercisesCompleted} / ${log.exercisesPlanned} exercises',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              calories != null && calories > 0
                  ? 'Estimated $calories kcal burned in '
                      '${_formatTime(_totalSeconds)}'
                  : 'Workout time: ${_formatTime(_totalSeconds)}. '
                      'Add your weight in your profile for a calorie estimate.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accent.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final day = workout.activeDay;

    // FIX: If session is cleared (null), pop the screen automatically
    if (day == null || !workout.sessionActive || day.exercises.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      });
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final exercises = day.exercises;
    final currentIdx = workout.currentExerciseIndex
        .clamp(0, exercises.length - 1)
        .toInt();
    final currentExercise = exercises[currentIdx];
    final currentSet = workout.currentSet;
    final progress = workout.sessionProgress.clamp(0.0, 1.0).toDouble();

    final restStr = currentExercise.rest
        .replaceAll(' sec', '')
        .replaceAll(' min', '');
    final parsedRest = int.tryParse(restStr) ?? 60;
    final restSecs = currentExercise.rest.contains('min')
        ? parsedRest * 60
        : parsedRest;

    final exerciseDone = workout.isExerciseDone(
      day,
      currentExercise,
      date: workout.activeSessionDate,
    );

    final isFinalStep =
        currentSet >= currentExercise.sets && workout.pendingCount <= 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: Stack(
        children: [
          if (_celebrate) ConfettiBurst(play: _celebrate),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _TopBar(
                      focus: day.focus,
                      time: _formatTime(_totalSeconds),
                      onClose: () => _confirmEnd(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SessionProgressBar(
                              progress: progress,
                              done: workout.completedCountForDay(
                                day,
                                date: workout.activeSessionDate,
                              ),
                              total: exercises.length,
                              exerciseDone: exerciseDone,
                            ),
                            const SizedBox(height: 18),
                            _ExerciseCard(
                              currentIdx: currentIdx,
                              totalExercises: exercises.length,
                              exercise: currentExercise,
                              currentSet: currentSet,
                            ),
                            if (_resting) ...[
                              const SizedBox(height: 16),
                              _RestCard(
                                seconds: _restSeconds,
                                formatted: _formatTime(_restSeconds),
                                onSkip: () {
                                  setState(() => _resting = false);
                                  _restTimer?.cancel();
                                },
                              ),
                            ],
                            if (currentIdx + 1 < exercises.length) ...[
                              const SizedBox(height: 16),
                              _UpNextCard(
                                name: exercises[currentIdx + 1].name,
                              ),
                            ],
                            const SizedBox(height: 20),
                            _ActionBar(
                              isFinalStep: isFinalStep,
                              resting: _resting,
                              currentSet: currentSet,
                              exerciseSets: currentExercise.sets,
                              onSkip: () async {
                                _restTimer?.cancel();
                                if (mounted) {
                                  setState(() => _resting = false);
                                }
                                final moved =
                                    await workout.skipExercise();
                                if (!moved && mounted) {
                                  _confirmEnd(
                                    message:
                                        'No other exercises left. Finish the workout?',
                                  );
                                }
                              },
                              onNext: () async {
                                final finishingExercise =
                                    currentSet >= currentExercise.sets;

                                if (finishingExercise) {
                                  _restTimer?.cancel();
                                  setState(() => _resting = false);
                                }

                                // FIX: if it's the last exercise AND last set, finish workout
                                if (isFinalStep) {
                                  await _finishWorkout();
                                  return;
                                }

                                await workout.completeSet();
                                if (!mounted) return;

                                if (finishingExercise) {
                                  if (workout.allExercisesDone) {
                                    await _finishWorkout();
                                  }
                                } else {
                                  _startRest(restSecs);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _finishWorkout,
                                child: const Text(
                                  'Finish workout',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String focus;
  final String time;
  final VoidCallback onClose;

  const _TopBar({
    required this.focus,
    required this.time,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          BouncyTap(
            onTap: onClose,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  focus,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'WORKOUT IN PROGRESS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppColors.accent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionProgressBar extends StatelessWidget {
  final double progress;
  final int done;
  final int total;
  final bool exerciseDone;

  const _SessionProgressBar({
    required this.progress,
    required this.done,
    required this.total,
    required this.exerciseDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'SESSION PROGRESS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 6),
            Text(
              '$done of $total exercises done',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (exerciseDone
                        ? AppColors.success
                        : AppColors.textSecondary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                exerciseDone ? 'DONE' : 'PENDING',
                style: TextStyle(
                  color: exerciseDone
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int currentIdx;
  final int totalExercises;
  final Exercise exercise;
  final int currentSet;

  const _ExerciseCard({
    required this.currentIdx,
    required this.totalExercises,
    required this.exercise,
    required this.currentSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EDF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A66).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF3FF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'EXERCISE ${currentIdx + 1} OF $totalExercises',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: Color(0xFFE8A23A),
                ),
                const SizedBox(width: 5),
                const Text(
                  'FORM GUIDE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _ExerciseVideoPanel(
            key: ValueKey(exercise.id),
            exerciseName: exercise.name,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.track_changes_rounded,
                      size: 15,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exercise.targetMuscle.isEmpty
                            ? 'Full body'
                            : exercise.targetMuscle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((exercise.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    exercise.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ExerciseMetric(
                        label: 'SET',
                        value: '$currentSet/${exercise.sets}',
                        icon: Icons.repeat_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExerciseMetric(
                        label: 'TARGET',
                        value: exercise.reps,
                        icon: Icons.bolt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExerciseMetric(
                        label: 'REST',
                        value: exercise.rest,
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ExerciseMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.accent),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestCard extends StatelessWidget {
  final int seconds;
  final String formatted;
  final VoidCallback onSkip;

  const _RestCard({
    required this.seconds,
    required this.formatted,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAFBF5), Color(0xFFF5FFFB)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBDEEDD)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: Color(0xFF159A72),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECOVERY BREAK',
                  style: TextStyle(
                    color: Color(0xFF168263),
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatted,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Breathe steadily and reset your form.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSkip,
            child: const Text('SKIP'),
          ),
        ],
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  final String name;
  const _UpNextCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.skip_next_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Text(
            'UP NEXT',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isFinalStep;
  final bool resting;
  final int currentSet;
  final int exerciseSets;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _ActionBar({
    required this.isFinalStep,
    required this.resting,
    required this.currentSet,
    required this.exerciseSets,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.fast_forward_rounded, size: 18),
            label: const Text('Skip'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFFDCE4F1)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: resting ? null : AppGradients.hero,
              color: resting ? AppColors.border : null,
              borderRadius: BorderRadius.circular(100),
              boxShadow: resting ? [] : AppShadows.glow(AppColors.accent),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: resting ? null : onNext,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (resting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Icon(
                          isFinalStep
                              ? Icons.flag_rounded
                              : currentSet >= exerciseSets
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        resting
                            ? 'Resting…'
                            : isFinalStep
                                ? 'Finish workout'
                                : currentSet >= exerciseSets
                                    ? 'Next exercise'
                                    : 'Complete set',
                        style: TextStyle(
                          color: resting
                              ? AppColors.textSecondary
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Plays an MP4 from assets/exercises/<exercise_name>.mp4.
class _ExerciseVideoPanel extends StatefulWidget {
  final String exerciseName;

  const _ExerciseVideoPanel({
    super.key,
    required this.exerciseName,
  });

  @override
  State<_ExerciseVideoPanel> createState() => _ExerciseVideoPanelState();
}

class _ExerciseVideoPanelState extends State<_ExerciseVideoPanel> {
  VideoPlayerController? _controller;
  bool _failed = false;

  String _assetPath(String name) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return 'assets/exercises/$normalized.mp4';
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller =
        VideoPlayerController.asset(_assetPath(widget.exerciseName));

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (mounted) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant _ExerciseVideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.exerciseName != widget.exerciseName) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      height: 232,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F7FF), Color(0xFFE4ECFF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _failed
                ? _missingVideo(_assetPath(widget.exerciseName))
                : controller != null && controller.value.isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'LOOPING FORM GUIDE',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: .5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.exerciseName.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _missingVideo(String path) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 36,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            const Text(
              'Exercise video not found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              path,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}