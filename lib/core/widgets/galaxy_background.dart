import 'dart:math' as math;
import 'package:flutter/material.dart';

class GalaxyBackground extends StatefulWidget {
  const GalaxyBackground({super.key});

  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _GalaxyPainter(time: _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  final double time;
  _GalaxyPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height);

    // 1. Deep Space Background
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF02000A),
          Color(0xFF0B0B2A),
          Color(0xFF05061A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // 2. Nebula Clouds
    _drawNebula(canvas, center, maxRadius, time);

    // 3. Stars
    final rng = math.Random(42);
    for (int i = 0; i < 180; i++) {
      _drawStar(canvas, rng, size, time);
    }

    // 4. Shooting Star
    _drawShootingStar(canvas, size, time);
  }

  void _drawNebula(Canvas canvas, Offset center, double maxRadius, double t) {
    final scale = 1.0 + math.sin(t * math.pi * 2) * 0.1;
    final rotation = t * math.pi * 2;

    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80)
      ..blendMode = BlendMode.screen;

    final c1 = Offset(
      center.dx + math.cos(rotation) * 100,
      center.dy + math.sin(rotation) * 100,
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF246BFF).withOpacity(0.15),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: c1, radius: maxRadius * 0.6 * scale));
    canvas.drawCircle(c1, maxRadius * 0.6 * scale, paint);

    final c2 = Offset(
      center.dx + math.cos(rotation + math.pi) * 150,
      center.dy + math.sin(rotation + math.pi) * 150,
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF8B5CF6).withOpacity(0.12),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: c2, radius: maxRadius * 0.5 * scale));
    canvas.drawCircle(c2, maxRadius * 0.5 * scale, paint);
  }

  void _drawStar(Canvas canvas, math.Random rng, Size size, double t) {
    final double x = rng.nextDouble() * size.width;
    final double y = rng.nextDouble() * size.height;
    
    final int layer = rng.nextInt(3);
    final double speed = layer == 0 ? 2.0 : (layer == 1 ? 5.0 : 10.0);
    final double sizeMultiplier = layer == 0 ? 0.5 : (layer == 1 ? 1.0 : 1.6);
    
    final double dx = (x + t * size.width * speed * 0.05) % size.width;
    final double dy = (y + t * size.height * speed * 0.05) % size.height;

    final double twinklePhase = rng.nextDouble() * math.pi * 2;
    final double twinkle = 0.5 + math.sin(t * math.pi * 4 + twinklePhase) * 0.5;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 + twinkle * 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dx, dy), 0.8 * sizeMultiplier, paint);

    if (layer == 2) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(twinkle * 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: 4.0));
      canvas.drawCircle(Offset(dx, dy), 4.0, glowPaint);
    }
  }

  void _drawShootingStar(Canvas canvas, Size size, double t) {
    final double cycle = (t * 6.5) % 1.0;
    if (cycle > 0.15) return;

    final double progress = cycle / 0.15;
    
    final startX = size.width * 0.8;
    final startY = size.height * 0.1;
    final endX = size.width * 0.2;
    final endY = size.height * 0.4;

    final currentX = startX + (endX - startX) * progress;
    final currentY = startY + (endY - startY) * progress;

    final paint = Paint()
      ..color = Colors.white.withOpacity(1.0 - progress)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final tailLength = 80.0 * (1.0 - progress);
    final angle = math.atan2(endY - startY, endX - startX);
    
    final tailX = currentX - math.cos(angle) * tailLength;
    final tailY = currentY - math.sin(angle) * tailLength;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(1.0 - progress),
        Colors.transparent,
      ],
    );

    paint.shader = gradient.createShader(
      Rect.fromPoints(Offset(currentX, currentY), Offset(tailX, tailY)),
    );

    canvas.drawLine(Offset(currentX, currentY), Offset(tailX, tailY), paint);
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}