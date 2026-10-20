import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';
import 'package:gymgen_ai/providers/profile_provider.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';
import 'package:gymgen_ai/providers/nutrition_provider.dart';
import 'package:gymgen_ai/providers/coach_provider.dart';
import 'package:gymgen_ai/providers/progress_provider.dart';
import 'package:gymgen_ai/providers/assessment_provider.dart';
import 'package:gymgen_ai/features/home/presentation/screens/home_tab.dart';
import 'package:gymgen_ai/features/coach/presentation/screens/coach_screen.dart';
import 'package:gymgen_ai/features/progress/presentation/screens/progress_screen.dart';
import 'package:gymgen_ai/features/profile/presentation/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.userId;

    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.loadProfile(uid, email: auth.userEmail);
    if (!mounted) return;
    
    await Future.wait([
      context.read<WorkoutProvider>().load(uid),
      context.read<NutritionProvider>().load(uid, profile: profileProvider.profile),
      context.read<CoachProvider>().load(uid),
      context.read<ProgressProvider>().load(uid),
      context.read<AssessmentProvider>().loadAssessments(uid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeTab(onSelectTab: (index) => setState(() => _currentIndex = index)),
            const CoachScreen(),
            const ProgressScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.smart_toy_rounded, Icons.smart_toy_outlined, 'Coach'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Progress'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavItem(
                  selected: currentIndex == i,
                  activeIcon: items[i].$1,
                  inactiveIcon: items[i].$2,
                  label: items[i].$3,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? activeIcon : inactiveIcon,
                color: selected ? AppColors.accent : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.textMuted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}