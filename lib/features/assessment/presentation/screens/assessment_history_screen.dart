import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_text_styles.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/providers/assessment_provider.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';

class AssessmentHistoryScreen extends StatefulWidget {
  static const routeName = '/assessment-history';

  const AssessmentHistoryScreen({super.key});

  @override
  State<AssessmentHistoryScreen> createState() =>
      _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends State<AssessmentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<AssessmentProvider>().loadAssessments(auth.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Assessment history', style: AppTextStyles.heading2),
      ),
      body: SafeArea(
        child: provider.loadingHistory
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : provider.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        provider.error!,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : provider.assessments.isEmpty
                    ? _EmptyState()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: FadeSlideIn(
                              child: _AssessmentSummary(provider: provider),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 8, 20, 24),
                              itemCount: provider.assessments.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final assessment =
                                    provider.assessments[index];
                                return FadeSlideIn(
                                  delay: Duration(
                                      milliseconds: 60 * (index.clamp(0, 6))),
                                  child: _HistoryCard(
                                    index: index + 1,
                                    date: assessment.createdAt,
                                    age: assessment.age,
                                    height: assessment.heightCm,
                                    weight: assessment.weightKg,
                                    goal: assessment.goal,
                                    workoutDays: assessment.workoutDays,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 44,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No saved assessments yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete an assessment to see your progress history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentSummary extends StatelessWidget {
  final AssessmentProvider provider;

  const _AssessmentSummary({required this.provider});

  int get averageWeight {
    if (provider.assessments.isEmpty) return 0;
    final total = provider.assessments
        .fold<double>(0, (sum, item) => sum + item.weightKg);
    return (total / provider.assessments.length).round();
  }

  int get averageWorkoutDays {
    if (provider.assessments.isEmpty) return 0;
    final total = provider.assessments
        .fold<int>(0, (sum, item) => sum + item.workoutDays);
    return (total / provider.assessments.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final maxWeight = provider.assessments
        .map((a) => a.weightKg)
        .fold<double>(0, (prev, weight) => prev > weight ? prev : weight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SummaryTile(
                    icon: Icons.assignment_rounded,
                    label: 'Assessments',
                    value: '${provider.assessments.length}',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _SummaryTile(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Avg weight',
                    value: '$averageWeight kg',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _SummaryTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Avg days',
                    value: '$averageWorkoutDays',
                    color: AppColors.energy,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return Opacity(
                      opacity: t,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final labels = provider.assessments
                                      .asMap()
                                      .entries
                                      .map((entry) =>
                                          'S${entry.key + 1}')
                                      .toList();
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= labels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 8),
                                    child: Text(
                                      labels[index],
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (provider.assessments.length - 1)
                              .toDouble()
                              .clamp(0, 6)
                              .toDouble(),
                          minY: 0,
                          maxY: maxWeight + 10,
                          lineBarsData: [
                            LineChartBarData(
                              spots: provider.assessments
                                  .asMap()
                                  .entries
                                  .map((entry) => FlSpot(
                                      entry.key.toDouble(),
                                      entry.value.weightKg))
                                  .toList(),
                              isCurved: true,
                              curveSmoothness: 0.3,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  Color(0xFF78A4FF)
                                ],
                              ),
                              barWidth: 4,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, bar, index) =>
                                        FlDotCirclePainter(
                                  radius: 5,
                                  color: AppColors.accent,
                                  strokeWidth: 2.5,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withOpacity(0.25),
                                    AppColors.accent.withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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

class _HistoryCard extends StatelessWidget {
  final int index;
  final DateTime date;
  final int age;
  final double height;
  final double weight;
  final String goal;
  final int workoutDays;

  const _HistoryCard({
    required this.index,
    required this.date,
    required this.age,
    required this.height,
    required this.weight,
    required this.goal,
    required this.workoutDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.hero,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '#$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assessment saved',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date.toLocal().toString().split('.').first,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'SAVED',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: 'Age', value: '$age'),
              _Chip(
                  label: 'Height',
                  value: '${height.toStringAsFixed(0)} cm'),
              _Chip(label: 'Weight', value: '${weight.toStringAsFixed(1)} kg'),
              _Chip(label: 'Goal', value: goal),
              _Chip(label: 'Days', value: '$workoutDays'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;

  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}