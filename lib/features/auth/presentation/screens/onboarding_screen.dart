import 'package:flutter/material.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int page = 0;

  final data = const [
    (
      'Smarter Workouts.',
      'AI builds a plan around your body, goals and equipment — not a one-size template.',
      Icons.fitness_center_rounded,
      Color(0xFF246BFF),
      Color(0xFF78A4FF),
    ),
    (
      'Precision Nutrition.',
      'Calories and macros tuned to your training load, with quick food logging.',
      Icons.eco_rounded,
      Color(0xFF35C99A),
      Color(0xFF43DCAB),
    ),
    (
      'Real Progress.',
      'Track workouts, weight and streaks with charts that make momentum visible.',
      Icons.insights_rounded,
      Color(0xFFFF9A3D),
      Color(0xFFFF7A45),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (page == data.length - 1) {
      await LocalStorageService.instance.setOnboardingCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skip() async {
    await LocalStorageService.instance.setOnboardingCompleted();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'GYMGEN ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        TextSpan(
                          text: 'AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: data.length,
                onPageChanged: (v) => setState(() => page = v),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double delta = 0;
                      if (_controller.position.haveDimensions) {
                        delta = index - _controller.page!;
                      } else {
                        delta = index - page.toDouble();
                      }
                      final scale = (1 - delta.abs() * 0.08).clamp(0.85, 1.0);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: _OnboardingCard(
                      title: data[index].$1,
                      subtitle: data[index].$2,
                      icon: data[index].$3,
                      colorA: data[index].$4,
                      colorB: data[index].$5,
                      index: index,
                      page: page,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  _Dots(count: data.length, index: page),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        gradient: page == data.length - 1
                            ? AppGradients.hero
                            : const LinearGradient(
                                colors: [AppColors.ink, AppColors.inkSoft],
                              ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: AppShadows.glow(
                          page == data.length - 1
                              ? AppColors.accent
                              : AppColors.ink,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: _next,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                              child: Row(
                                key: ValueKey(page),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    page == data.length - 1
                                        ? 'Get Started'
                                        : 'Next',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    page == data.length - 1
                                        ? Icons.rocket_launch_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final int index;
  final int page;

  const _OnboardingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.index,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: AppShadows.elevated,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorA.withOpacity(0.14),
                      colorB.withOpacity(0.06),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Floating decor circles
                    Positioned(
                      top: 20,
                      right: 30,
                      child: _Decor(
                        color: colorA.withOpacity(0.15),
                        size: 40,
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 40,
                      child: _Decor(
                        color: colorB.withOpacity(0.18),
                        size: 24,
                      ),
                    ),
                    Positioned(
                      top: 80,
                      left: 60,
                      child: _Decor(
                        color: colorA.withOpacity(0.1),
                        size: 16,
                      ),
                    ),
                    // Big icon tile
                    TweenAnimationBuilder<double>(
                      key: ValueKey('$index-$page'),
                      tween: Tween(begin: 0.85, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, s, child) =>
                          Transform.scale(scale: s, child: child),
                      child: Container(
                        width: 156,
                        height: 156,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colorA, colorB],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorA.withOpacity(0.35),
                              blurRadius: 34,
                              spreadRadius: 4,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 68),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Decor extends StatelessWidget {
  final Color color;
  final double size;
  const _Decor({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 30 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.border,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}