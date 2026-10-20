import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/app_widgets.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';
import 'package:gymgen_ai/models/workout_models.dart';
import 'package:gymgen_ai/features/workout/presentation/screens/workout_execution_screen.dart';

class WorkoutScreen extends StatefulWidget {
  static const routeName = '/workout';

  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Workout Plan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: workout.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : workout.plan == null
              ? const _NoPlanView()
              : _buildBody(context, workout),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutProvider workout) {
    final plan = workout.plan!;
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final isToday = DateUtils.isSameDay(_selectedDate, today);

    final selectedDay = _workoutForDate(plan.days, _selectedDate);
    final dayLogComplete = workout.logs.any(
      (l) => l.isComplete && DateUtils.isSameDay(l.date, _selectedDate),
    );

    bool isDone(Exercise e) {
      if (selectedDay == null) return false;
      if (dayLogComplete) return true;
      return isToday && workout.isExerciseDone(selectedDay, e);
    }

    final total = selectedDay?.exercises.length ?? 0;
    final done =
        selectedDay == null ? 0 : selectedDay.exercises.where(isDone).length;

    final dayLogs = workout.logs
        .where((l) => DateUtils.isSameDay(l.date, _selectedDate))
        .toList();
    final sessionEnded = dayLogs.isNotEmpty;
    final skipped = sessionEnded ? (total - done) : 0;

    final recent = [...workout.logs]
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        FadeSlideIn(
          child: Row(
            children: List.generate(7, (i) {
              final date = monday.add(Duration(days: i));
              final hasWorkout = _workoutForDate(plan.days, date) != null;
              final completed = workout.logs.any(
                (l) => l.isComplete && DateUtils.isSameDay(l.date, date),
              );
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                  child: _DayTile(
                    date: date,
                    isToday: DateUtils.isSameDay(date, today),
                    isSelected: DateUtils.isSameDay(date, _selectedDate),
                    hasWorkout: hasWorkout,
                    isCompleted: completed,
                    onTap: () => setState(() => _selectedDate = date),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),

        if (selectedDay == null)
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: _RestCard(date: _selectedDate, isToday: isToday),
          )
        else ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: _ProgressHeader(
              day: selectedDay,
              done: done,
              total: total,
              skipped: skipped,
              sessionEnded: sessionEnded,
              canStart: isToday && done < total,
              isToday: isToday,
              onStart: () {
                workout.startSession(selectedDay);
                Navigator.of(context)
                    .pushNamed(WorkoutExecutionScreen.routeName);
              },
            ),
          ),
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: const SectionTitle(title: 'Exercises'),
          ),
          const SizedBox(height: 12),
          ...selectedDay.exercises.asMap().entries.map((e) {
            final d = isDone(e.value);
            return FadeSlideIn(
              delay: Duration(milliseconds: 200 + 40 * e.key),
              child: _ExerciseCard(
                exercise: e.value,
                index: e.key + 1,
                isDone: d,
                isSkipped: sessionEnded && !d,
              ),
            );
          }),
        ],

        if (recent.isNotEmpty) ...[
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: const SectionTitle(title: 'Recent activity'),
          ),
          const SizedBox(height: 12),
          ...recent.take(5).map((log) => FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: _HistoryTile(log: log),
              )),
        ],
      ],
    );
  }
}

WorkoutDay? _workoutForDate(List<WorkoutDay> days, DateTime date) {
  for (final day in days) {
    if (_weekdayNumber(day.dayLabel) == date.weekday) return day;
  }
  return null;
}

int? _weekdayNumber(String label) {
  const weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final n = label.trim().toLowerCase();
  for (var i = 0; i < weekdays.length; i++) {
    if (n == weekdays[i] || n == weekdays[i].substring(0, 3)) return i + 1;
  }
  return null;
}

// ── No Plan ─────────────────────────────────────────────────────────────────

class _NoPlanView extends StatelessWidget {
  const _NoPlanView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.glow(AppColors.accent),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Workout Plan Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete your fitness assessment to get a personalized workout plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Take Assessment',
                leadingIcon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onTap: () => Navigator.of(context).pushNamed('/assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day tile ────────────────────────────────────────────────────────────────

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.hasWorkout,
    required this.isCompleted,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday, isSelected, hasWorkout, isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = isCompleted
        ? Icons.check_circle_rounded
        : hasWorkout
            ? Icons.circle
            : Icons.remove;

    final iconColor = isCompleted
        ? (isSelected ? Colors.white : AppColors.success)
        : hasWorkout
            ? (isSelected ? Colors.white70 : AppColors.accent)
            : (isSelected ? Colors.white54 : AppColors.border);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.hero : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isToday
                    ? AppColors.accent
                    : AppColors.border.withOpacity(0.6),
            width: isToday && !isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppShadows.glow(AppColors.accent) : null,
        ),
        child: Column(
          children: [
            Text(
              DateFormat('E').format(date),
              style: TextStyle(
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Icon(icon, color: iconColor, size: isCompleted ? 12 : 8),
          ],
        ),
      ),
    );
  }
}

// ── Progress header ─────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.day,
    required this.done,
    required this.total,
    required this.skipped,
    required this.sessionEnded,
    required this.canStart,
    required this.isToday,
    required this.onStart,
  });

  final WorkoutDay day;
  final int done, total, skipped;
  final bool sessionEnded, canStart, isToday;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final allDone = total > 0 && done >= total;
    final progress = total == 0 ? 0.0 : done / total;
    final label = allDone
        ? 'Workout completed'
        : sessionEnded
            ? 'Restart workout'
            : done > 0
                ? 'Resume workout'
                : 'Start workout';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.glow(AppColors.accent),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day.focus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total exercises  •  ${day.durationMinutes} min',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      skipped > 0
                          ? '$done done  •  $skipped skipped'
                          : '$done of $total done',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: canStart ? onStart : null,
                    icon: Icon(
                      allDone
                          ? Icons.check_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(label),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accent,
                      disabledBackgroundColor: Colors.white.withOpacity(0.85),
                      disabledForegroundColor: AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rest card ───────────────────────────────────────────────────────────────

class _RestCard extends StatelessWidget {
  const _RestCard({required this.date, required this.isToday});

  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withOpacity(0.55)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rest and recovery',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isToday
                ? 'No workout is scheduled today.'
                : 'No workout on ${DateFormat('EEEE').format(date)}.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Exercise card ───────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.isDone,
    this.isSkipped = false,
  });

  final Exercise exercise;
  final int index;
  final bool isDone;
  final bool isSkipped;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success.withOpacity(0.05)
            : isSkipped
                ? const Color(0xFFF7F8FA)
                : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? AppColors.success.withOpacity(0.5)
              : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isDone
                  ? AppGradients.success
                  : AppGradients.hero,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    )
                  : Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: isDone || isSkipped
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.sets} sets × ${exercise.reps}  •  Rest ${exercise.rest}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    exercise.targetMuscle,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSkipped)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SKIPPED',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── History tile ────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.log});

  final WorkoutLog log;

  String get _dateLabel {
    final now = DateTime.now();
    if (DateUtils.isSameDay(log.date, now)) return 'Today';
    if (DateUtils.isSameDay(
        log.date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('d MMM').format(log.date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (log.isComplete ? AppColors.success : AppColors.accent)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              log.isComplete
                  ? Icons.check_circle_rounded
                  : Icons.timelapse_rounded,
              color: log.isComplete ? AppColors.success : AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.workoutName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${log.durationMinutes} min  •  ${log.caloriesBurned} kcal  •  ${log.exercisesCompleted} exercises',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _dateLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}