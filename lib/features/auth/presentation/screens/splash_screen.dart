import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:gymgen_ai/features/assessment/presentation/screens/assessment_screen.dart';
import 'package:gymgen_ai/features/dashboard/dashboard_screen.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _sheenCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _logoCtrl.forward();
    _checkInitialState();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _sheenCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkInitialState() async {
    // 1. Let the animation play for a moment
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final onboardingDone =
        await LocalStorageService.instance.isOnboardingCompleted();
    if (!mounted) return;
    
    final auth = context.read<AuthProvider>();

    if (!onboardingDone) {
      Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
      return;
    }

    if (auth.isLoggedIn) {
      try {
        // FIX: Added a 5-second timeout so it doesn't freeze if the server is asleep
        final savedProfile = await LocalStorageService.instance
            .loadProfileForUser(auth.userId, auth.userEmail)
            .timeout(const Duration(seconds: 5)); 

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          savedProfile == null
              ? AssessmentScreen.routeName
              : DashboardScreen.routeName,
        );
      } catch (e) {
        // FIX: If it times out or fails, just send them to the Dashboard. 
        // The dashboard will load local cache and sync in the background.
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
      }
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.splashBackdrop),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _Glow(
                color: AppColors.accent,
                size: 320,
                pulse: _pulseCtrl,
              ),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _Glow(
                color: AppColors.energy,
                size: 280,
                pulse: _pulseCtrl,
                reverse: true,
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 30),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _AnimatedLogo(
                            controller: _logoCtrl,
                            sheen: _sheenCtrl,
                          ),
                          const SizedBox(height: 28),
                          _RevealText(
                            controller: _logoCtrl,
                            start: 0.25,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'GYMGEN ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'AI',
                                    style: TextStyle(
                                      color: AppColors.accentSoft,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _RevealText(
                            controller: _logoCtrl,
                            start: 0.45,
                            child: const Text(
                              'AI POWERED FITNESS COACH',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 44),
                          _RevealText(
                            controller: _logoCtrl,
                            start: 0.55,
                            child: const _TaglineRow(),
                          ),
                          const SizedBox(height: 56),
                          _RevealText(
                            controller: _logoCtrl,
                            start: 0.75,
                            child: const _LoadingDots(),
                          ),
                          const SizedBox(height: 14),
                          _RevealText(
                            controller: _logoCtrl,
                            start: 0.85,
                            child: Text(
                              'Preparing your experience...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  final Animation<double> pulse;
  final bool reverse;

  const _Glow({
    required this.color,
    required this.size,
    required this.pulse,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = reverse ? 1 - pulse.value : pulse.value;
        final scale = 0.92 + t * 0.16;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.55),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedLogo extends StatelessWidget {
  final AnimationController controller;
  final AnimationController sheen;

  const _AnimatedLogo({required this.controller, required this.sheen});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(
          controller.value.clamp(0.0, 0.75) / 0.75,
        );
        final ringT = Curves.easeOutCubic.transform(
          ((controller.value - 0.1) / 0.6).clamp(0.0, 1.0),
        );
        return SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: ringT * math.pi * 2,
                child: Opacity(
                  opacity: ringT,
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0),
                          AppColors.accent,
                          AppColors.accentSoft,
                          AppColors.accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 152,
                        height: 152,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.6 + t * 0.4,
                child: Opacity(
                  opacity: controller.value.clamp(0.0, 1.0),
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      gradient: AppGradients.hero,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: AppShadows.glow(AppColors.accent),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                        AnimatedBuilder(
                          animation: sheen,
                          builder: (context, _) {
                            return Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(34),
                                child: Transform.translate(
                                  offset: Offset(
                                    -140 + sheen.value * 280,
                                    0,
                                  ),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Container(
                                      width: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(alpha: 0.35),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevealText extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final Widget child;

  const _RevealText({
    required this.controller,
    required this.start,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = ((controller.value - start) / 0.15).clamp(0.0, 1.0);
        final curved = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - curved)),
            child: child,
          ),
        );
      },
    );
  }
}

class _TaglineRow extends StatelessWidget {
  const _TaglineRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Train Smarter', Icons.bolt_rounded),
      ('Eat Better', Icons.eco_rounded),
      ('Live Stronger', Icons.favorite_rounded),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$2, color: AppColors.accentSoft, size: 14),
                const SizedBox(width: 6),
                Text(
                  items[i].$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.15) % 1.0;
            final scale = 0.6 + (1 - (phase - 0.5).abs() * 2) * 0.4;
            final dot = Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.accentSoft
                    .withValues(alpha: 0.4 + scale * 0.6),
                shape: BoxShape.circle,
              ),
            );
            return Transform.scale(scale: scale, child: dot);
          }),
        );
      },
    );
  }
}