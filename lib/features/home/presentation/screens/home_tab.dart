import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/app_widgets.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/core/widgets/galaxy_scaffold.dart'; // NEW IMPORT
import 'package:gymgen_ai/providers/auth_provider.dart';
import 'package:gymgen_ai/providers/profile_provider.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';
import 'package:gymgen_ai/providers/nutrition_provider.dart';
import 'package:gymgen_ai/features/workout/presentation/screens/workout_screen.dart';
import 'package:gymgen_ai/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:gymgen_ai/features/workout/presentation/screens/workout_execution_screen.dart';

class HomeTab extends StatelessWidget {
  static const routeName = '/home';
  final ValueChanged<int>? onSelectTab;

  const HomeTab({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final workout = context.watch<WorkoutProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final auth = context.watch<AuthProvider>();

    final name = profile.displayName.isNotEmpty
        ? profile.displayName.split(' ').first
        : auth.userName.split(' ').first;
    final notifications = _buildNotifications(
      workout: workout,
      nutrition: nutrition,
      profile: profile,
    );

    return GalaxyScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: Colors.white,
              onRefresh: () async {
                final uid = auth.userId;
                await Future.wait([
                  profile.loadProfile(uid),
                  workout.load(uid),
                  nutrition.load(uid),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      name: name,
                      userId: auth.userId,
                      notifications: notifications,
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: _TodayProgressCard(
                        nutrition: nutrition,
                        workout: workout,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _GalaxySectionTitle(title: 'Quick Actions'),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: _QuickActions(
                        workout: workout,
                        nutrition: nutrition,
                        onSelectTab: onSelectTab,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: _GalaxySectionTitle(title: "Today's Workout"),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: _TodayWorkoutCard(workout: workout),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 280),
                      child: _GalaxySectionTitle(
                        title: 'Nutrition Summary',
                        action: 'View Details',
                        onAction: () => Navigator.of(
                          context,
                        ).pushNamed(NutritionScreen.routeName),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 320),
                      child: _NutritionSummaryCard(nutrition: nutrition),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 360),
                      child: _GalaxySectionTitle(title: 'My Stats'),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: _StatsCard(profile: profile),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notifications (logic unchanged) ─────────────────────────────────────────

List<_AppNotification> _buildNotifications({
  required WorkoutProvider workout,
  required NutritionProvider nutrition,
  required ProfileProvider profile,
}) {
  final items = <_AppNotification>[];

  for (final log in workout.logs.take(8)) {
    final completed = log.exercisesCompleted;
    final planned = log.exercisesPlanned;
    items.add(
      _AppNotification(
        id: 'workout-${log.id}',
        title: log.isComplete ? 'Workout completed' : 'Workout session saved',
        message: planned > 0
            ? '${log.workoutName}: $completed of $planned exercises completed.'
            : '${log.workoutName} · ${log.durationMinutes} min.',
        date: log.date,
        icon: log.isComplete
            ? Icons.check_circle_rounded
            : Icons.fitness_center_rounded,
        color: AppColors.success,
        route: '/workout',
      ),
    );
  }

  final meals = [...nutrition.today.entries]
    ..sort((a, b) => b.time.compareTo(a.time));
  for (final entry in meals.take(8)) {
    items.add(
      _AppNotification(
        id: 'food-${entry.id}',
        title: 'Food logged',
        message: '${entry.name} · ${entry.calories} kcal · ${entry.mealType}',
        date: entry.time,
        icon: Icons.restaurant_rounded,
        color: AppColors.accent,
        route: '/nutrition',
      ),
    );
  }

  final today = nutrition.today;
  if (today.targetWaterLitres > 0 &&
      today.waterLitres >= today.targetWaterLitres) {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    items.add(
      _AppNotification(
        id: 'hydration-$dayKey',
        title: 'Hydration goal reached',
        message:
            'You logged ${today.waterLitres.toStringAsFixed(1)} L of water today.',
        date: now,
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF4A9BFF),
        route: '/nutrition',
      ),
    );
  }

  final syncErrors = [
    profile.error,
    workout.error,
    nutrition.error,
  ].whereType<String>().where((error) => error.trim().isNotEmpty).toSet();
  for (final error in syncErrors) {
    items.add(
      _AppNotification(
        id: 'sync-${error.split(':').first}',
        title: 'Sync needs attention',
        message: error,
        date: DateTime.now(),
        icon: Icons.cloud_off_rounded,
        color: AppColors.error,
      ),
    );
  }

  items.sort((a, b) => b.date.compareTo(a.date));
  return items;
}

class _AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String? route;

  const _AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.icon,
    required this.color,
    this.route,
  });
}

// ── Galaxy-aware section title (white text over video) ──────────────────────

class _GalaxySectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _GalaxySectionTitle({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const Spacer(),
          BouncyTap(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Text(
                action!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatefulWidget {
  final String name;
  final String userId;
  final List<_AppNotification> notifications;

  const _Header({
    required this.name,
    required this.userId,
    required this.notifications,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  Set<String> _seenIds = {};
  bool _seenLoaded = false;

  String get _storageKey => 'notification_seen_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _loadSeenIds();
  }

  @override
  void didUpdateWidget(covariant _Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _seenIds = {};
      _seenLoaded = false;
      _loadSeenIds();
    }
  }

  Future<void> _loadSeenIds() async {
    if (widget.userId.isEmpty) {
      if (mounted) setState(() => _seenLoaded = true);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _seenIds = (prefs.getStringList(_storageKey) ?? []).toSet();
      _seenLoaded = true;
    });
  }

  Future<void> _openNotifications() async {
    final ids = widget.notifications.map((item) => item.id).toSet();
    setState(() => _seenIds = ids);
    if (widget.userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _seenIds.toList());
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NotificationsSheet(
        notifications: widget.notifications,
        onOpen: (route) {
          Navigator.of(sheetContext).pop();
          if (route != null) {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _seenLoaded
        ? widget.notifications
              .where((item) => !_seenIds.contains(item.id))
              .length
        : 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, ${widget.name} 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Ready to crush today's goals?",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        BouncyTap(
          onTap: _openNotifications,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  final List<_AppNotification> notifications;
  final ValueChanged<String?> onOpen;

  const _NotificationsSheet({
    required this.notifications,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            if (notifications.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 44,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No updates yet',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Workout activity, food logs, hydration goals, and sync alerts will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onOpen(item.route),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.icon, color: item.color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat(
                                        'EEE, d MMM · h:mm a',
                                      ).format(item.date),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.route != null)
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                            ],
                          ),
                        ),
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

// ── Today Progress Card ──────────────────────────────────────────────────────

class _TodayProgressCard extends StatelessWidget {
  final NutritionProvider nutrition;
  final WorkoutProvider workout;

  const _TodayProgressCard({required this.nutrition, required this.workout});

  @override
  Widget build(BuildContext context) {
    final today = nutrition.today;
    final plannedToday = workout.todayWorkout;

    final now = DateTime.now();
    final todayLogs = workout.logs
        .where((l) => DateUtils.isSameDay(l.date, now))
        .toList();
    final burned = todayLogs.fold<num>(0, (sum, l) => sum + l.caloriesBurned);

    double? workoutFraction;
    if (plannedToday != null && plannedToday.exercises.isNotEmpty) {
      final done = plannedToday.exercises
          .where((e) => workout.isExerciseDone(plannedToday, e))
          .length;
      workoutFraction = done / plannedToday.exercises.length;
    }

    final double? nutritionFraction = today.targetCalories > 0
        ? today.calorieProgress.clamp(0.0, 1.0).toDouble()
        : null;

    final parts = [workoutFraction, nutritionFraction].whereType<double>();
    final goalPct = parts.isEmpty
        ? 0.0
        : (parts.reduce((a, b) => a + b) / parts.length * 100).clamp(
            0.0,
            100.0,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.glow(AppColors.accent),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
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
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's Progress",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        AnimatedCounter(
                          value: burned,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'kcal',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: AnimatedRing(
                      progress: goalPct / 100,
                      size: 92,
                      stroke: 9,
                      color: Colors.white,
                      background: Colors.white.withValues(alpha: 0.2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedCounter(
                            value: goalPct,
                            suffix: '%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'GOAL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _HeroStat(
                          icon: Icons.fitness_center_rounded,
                          label: 'Workout',
                          value: workoutFraction == null
                              ? '—'
                              : '${(workoutFraction * 100).round()}%',
                        ),
                        const SizedBox(height: 10),
                        _HeroStat(
                          icon: Icons.restaurant_rounded,
                          label: 'Nutrition',
                          value: nutritionFraction == null
                              ? '—'
                              : '${(nutritionFraction * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final WorkoutProvider workout;
  final NutritionProvider nutrition;
  final ValueChanged<int>? onSelectTab;

  const _QuickActions({
    required this.workout,
    required this.nutrition,
    this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionCard(
          icon: Icons.fitness_center_rounded,
          title: 'Workout',
          subtitle: 'Plan',
          colors: const [Color(0xFF246BFF), Color(0xFF4C86FF)],
          onTap: () => Navigator.of(context).pushNamed(WorkoutScreen.routeName),
        ),
        const SizedBox(width: 12),
        _ActionCard(
          icon: Icons.eco_rounded,
          title: 'Nutrition',
          subtitle: 'Track',
          colors: const [Color(0xFF35C99A), Color(0xFF43DCAB)],
          onTap: () =>
              Navigator.of(context).pushNamed(NutritionScreen.routeName),
        ),
        const SizedBox(width: 12),
        _ActionCard(
          icon: Icons.smart_toy_rounded,
          title: 'AI Coach',
          subtitle: 'Ask',
          colors: const [Color(0xFFFF9A3D), Color(0xFFFF7A45)],
          onTap: () => onSelectTab?.call(1),
        ),
        const SizedBox(width: 12),
        _ActionCard(
          icon: Icons.bar_chart_rounded,
          title: 'Progress',
          subtitle: 'Stats',
          colors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          onTap: () => onSelectTab?.call(2),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.6)),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Today's Workout Card ─────────────────────────────────────────────────────

class _TodayWorkoutCard extends StatelessWidget {
  final WorkoutProvider workout;

  const _TodayWorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final today = workout.todayWorkout;

    final total = today?.exercises.length ?? 0;
    final done = today == null
        ? 0
        : today.exercises.where((e) => workout.isExerciseDone(today, e)).length;
    final progress = total == 0 ? 0.0 : done / total;
    final allDone = total > 0 && done >= total;

    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppGradients.hero,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.glow(AppColors.accent),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      today?.focus ?? 'No plan yet',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (today != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.repeat_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${today.exercises.length} exercises',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${today.durationMinutes} min',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (today != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  allDone
                      ? 'Completed 🎉'
                      : done > 0
                      ? '$done of $total done'
                      : 'Not started',
                  style: TextStyle(
                    color: allDone
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8EDF5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? AppColors.success : AppColors.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: today == null
                  ? null
                  : () {
                      workout.startSession(today);
                      Navigator.of(
                        context,
                      ).pushNamed(WorkoutExecutionScreen.routeName);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    allDone
                        ? 'Workout Again'
                        : done > 0
                        ? 'Resume Workout'
                        : 'Start Workout',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nutrition Summary ────────────────────────────────────────────────────────

class _NutritionSummaryCard extends StatelessWidget {
  final NutritionProvider nutrition;

  const _NutritionSummaryCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final today = nutrition.today;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              AnimatedRing(
                progress: today.calorieProgress,
                size: 118,
                stroke: 12,
                color: AppColors.accent,
                background: const Color(0xFFE7ECF5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedCounter(
                      value: today.totalCalories,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/ ${today.targetCalories} kcal',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    MacroProgressRow(
                      label: 'Protein',
                      value:
                          '${today.totalProtein.toStringAsFixed(0)} / ${today.targetProtein.toStringAsFixed(0)}g',
                      progress: today.proteinProgress,
                      color: AppColors.success,
                    ),
                    MacroProgressRow(
                      label: 'Carbs',
                      value:
                          '${today.totalCarbs.toStringAsFixed(0)} / ${today.targetCarbs.toStringAsFixed(0)}g',
                      progress: today.carbsProgress,
                      color: AppColors.accent,
                    ),
                    MacroProgressRow(
                      label: 'Fats',
                      value:
                          '${today.totalFat.toStringAsFixed(0)} / ${today.targetFat.toStringAsFixed(0)}g',
                      progress: today.fatProgress,
                      color: const Color(0xFFFF9A3D),
                    ),
                    MacroProgressRow(
                      label: 'Water',
                      value:
                          '${today.waterLitres.toStringAsFixed(1)} / ${today.targetWaterLitres.toStringAsFixed(1)}L',
                      progress: today.waterProgress,
                      color: const Color(0xFF4A9BFF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats Card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final ProfileProvider profile;

  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final stats = profile.stats;
    final weightChange = stats.weeklyWeightChange;
    final changeStr = weightChange == 0
        ? '0 kg'
        : '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg';

    final tiles = [
      (
        Icons.monitor_weight_outlined,
        '${stats.currentWeightKg.toStringAsFixed(1)} kg',
        'Weight',
        AppColors.accent,
        null as Color?,
      ),
      (
        Icons.trending_up_rounded,
        changeStr,
        'This Week',
        const Color(0xFFFF9A3D),
        weightChange < 0 ? AppColors.success : null,
      ),
      (
        Icons.fitness_center_rounded,
        '${stats.totalWorkouts}',
        'Workouts',
        AppColors.success,
        null,
      ),
      (
        Icons.local_fire_department_rounded,
        '${stats.streakDays}',
        'Streak',
        AppColors.energy,
        null,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tiles[i].$4.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tiles[i].$1, color: tiles[i].$4, size: 18),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tiles[i].$2,
                      style: TextStyle(
                        color: tiles[i].$5 ?? AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tiles[i].$3,
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
          if (i != tiles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
