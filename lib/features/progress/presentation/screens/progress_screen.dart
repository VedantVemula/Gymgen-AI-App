import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/app_widgets.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/core/widgets/galaxy_scaffold.dart'; // NEW IMPORT
import 'package:gymgen_ai/providers/progress_provider.dart';
import 'package:gymgen_ai/providers/profile_provider.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';
import 'package:gymgen_ai/models/progress_models.dart';
import 'package:gymgen_ai/models/workout_models.dart';

class ProgressScreen extends StatelessWidget {
  static const routeName = '/progress';

  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final profile = context.watch<ProfileProvider>();
    final workout = context.watch<WorkoutProvider>();

    return GalaxyScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddWeightSheet(context),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(child: _StatsOverview(profile: profile)),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _WeightCard(entries: progress.weeklyEntries),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: _WorkoutActivityCard(logs: workout.logs),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      const Text(
                        'Weight Log',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showAddWeightSheet(context),
                        child: const Text(
                          '+ Log',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (progress.entries.isEmpty)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: const _EmptyLog(),
                  )
                else
                  ...progress.entries
                      .take(10)
                      .map(
                        (entry) => FadeSlideIn(
                          delay: const Duration(milliseconds: 240),
                          child: _WeightLogItem(
                            entry: entry,
                            onDelete: () => progress.removeEntry(entry.id),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddWeightSheet(),
    );
  }
}

class _StatsOverview extends StatelessWidget {
  final ProfileProvider profile;

  const _StatsOverview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = profile.stats;
    final tiles = [
      (
        '${stats.currentWeightKg.toStringAsFixed(1)} kg',
        'Current weight',
        Icons.monitor_weight_outlined,
        AppColors.accent,
      ),
      (
        '${stats.streakDays}',
        'Day streak',
        Icons.local_fire_department_rounded,
        AppColors.energy,
      ),
      (
        '${stats.totalWorkouts}',
        'Workouts',
        Icons.fitness_center_rounded,
        AppColors.success,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tiles[i].$4,
                          tiles[i].$4.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tiles[i].$3, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tiles[i].$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tiles[i].$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i != tiles.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _WeightCard extends StatelessWidget {
  final List<ProgressEntry> entries;

  const _WeightCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final hasChart = entries.length >= 2;
    final latest = entries.isEmpty ? null : entries.last.weightKg;
    final change = hasChart
        ? entries.last.weightKg - entries.first.weightKg
        : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight progress',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Last 7 entries',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (latest != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${latest.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (change != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (change < 0
                                      ? AppColors.success
                                      : AppColors.textSecondary)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          change == 0
                              ? 'No change'
                              : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: change < 0
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasChart)
            _WeightChart(entries: entries)
          else
            const _EmptyChartPlaceholder(),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<ProgressEntry> entries;

  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final weights = entries.map((e) => e.weightKg).toList();
    final lo = weights.reduce(math.min);
    final hi = weights.reduce(math.max);
    final pad = math.max((hi - lo) * 0.25, 0.5);

    final minY = (lo - pad).floorToDouble();
    final rawRange = (hi + pad).ceilToDouble() - minY;
    final interval = (rawRange / 4)
        .ceilToDouble()
        .clamp(1.0, double.infinity)
        .toDouble();
    final maxY = minY + interval * (rawRange / interval).ceil();

    final spots = [
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].weightKg),
    ];

    return SizedBox(
      height: 180,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Opacity(
          opacity: t,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (entries.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: interval,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (value != idx.toDouble() ||
                          idx < 0 ||
                          idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('d/M').format(entries[idx].date),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  preventCurveOverShooting: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF78A4FF)],
                  ),
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.accent,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.25),
                        AppColors.accent.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            color: AppColors.textSecondary,
            size: 34,
          ),
          SizedBox(height: 8),
          Text(
            'Log at least 2 weight entries to see the chart.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WorkoutActivityCard extends StatelessWidget {
  final List<WorkoutLog> logs;

  const _WorkoutActivityCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));

    final counts = weekDates
        .map((d) => logs.where((l) => DateUtils.isSameDay(l.date, d)).length)
        .toList();

    final weekLogs = logs.where((l) {
      final d = DateUtils.dateOnly(l.date);
      return !d.isBefore(monday) && !d.isAfter(sunday);
    }).toList();

    final sessions = weekLogs.length;
    final minutes = weekLogs.fold<int>(0, (s, l) => s + l.durationMinutes);
    final kcal = weekLogs.fold<int>(0, (s, l) => s + l.caloriesBurned);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Workout activity',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Text(
                '${DateFormat('d MMM').format(monday)} – '
                '${DateFormat('d MMM').format(sunday)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Sessions',
                value: '$sessions',
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Minutes',
                value: '$minutes',
                color: AppColors.energy,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'kcal',
                value: '$kcal',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _WeekBarChart(dates: weekDates, counts: counts, today: today),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<int> counts;
  final DateTime today;

  const _WeekBarChart({
    required this.dates,
    required this.counts,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.fold<int>(0, math.max);
    final maxY = math.max(3, maxCount).toDouble();

    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 162,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i > 6) return const SizedBox.shrink();
                  final isToday = DateUtils.isSameDay(dates[i], today);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayLetters[i],
                          style: TextStyle(
                            color: isToday
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w900
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          counts[i] > 0 ? '${counts[i]}' : '·',
                          style: TextStyle(
                            color: counts[i] > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(7, (i) {
            final isToday = DateUtils.isSameDay(dates[i], today);
            final count = counts[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  width: 18,
                  gradient: isToday ? AppGradients.hero : null,
                  color: isToday
                      ? null
                      : AppColors.accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: const Color(0xFFEFF3FA),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            color: AppColors.textSecondary,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'No weight entries yet.\nTap + Log to track your weight.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightLogItem extends StatelessWidget {
  final ProgressEntry entry;
  final VoidCallback onDelete;

  const _WeightLogItem({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasNotes = entry.notes != null && entry.notes!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (hasNotes)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatDate(entry.date),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            tooltip: 'Delete entry',
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) return 'Today';
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('d MMM yyyy').format(date);
  }
}

class _AddWeightSheet extends StatefulWidget {
  const _AddWeightSheet();

  @override
  State<_AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends State<_AddWeightSheet> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    final progress = context.read<ProgressProvider>();
    final profile = context.read<ProfileProvider>();
    await progress.addEntry(weight, notes: _notesController.text.trim());
    await profile.updateWeight(weight);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Log Weight',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g. 72.5',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. Morning, after workout',
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(100),
                boxShadow: AppShadows.glow(AppColors.accent),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: _save,
                  child: const Center(
                    child: Text(
                      'Save Weight',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}