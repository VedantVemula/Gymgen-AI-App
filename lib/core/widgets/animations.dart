import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fade + slide in with an optional delay. Wrap any widget.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, 0.12),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: widget.curve,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) {
        return Opacity(
          opacity: _a.value,
          child: Transform.translate(
            offset: Offset(
              widget.offset.dx * (1 - _a.value) * 100,
              widget.offset.dy * (1 - _a.value) * 100,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A list whose children stagger in.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration step;
  final Duration duration;
  final Offset offset;

  const StaggeredList({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 500),
    this.offset = const Offset(0, 0.15),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          FadeSlideIn(
            delay: step * i,
            duration: duration,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}

/// Animated number that counts up to [value].
class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String suffix;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.suffix = '',
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final text = decimals == 0
            ? v.round().toString()
            : v.toStringAsFixed(decimals);
        return Text('$text$suffix', style: style);
      },
    );
  }
}

/// Button that gently pulses to draw attention.
class PulseButton extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PulseButton({super.key, required this.child, this.enabled = true});

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        final scale = 1 + 0.02 * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// Tap bounces the child.
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: widget.scale,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapCancel: () => _c.forward(),
      onTapUp: (_) => _c.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _c, child: widget.child),
    );
  }
}

/// Diagonal shimmer overlay — good for loading placeholders.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(-1 + _c.value * 2, 0),
              end: Alignment(1 + _c.value * 2, 0),
              colors: const [
                Color(0xFFE8EDF5),
                Color(0xFFF7FAFF),
                Color(0xFFE8EDF5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Animated ring (used for calorie / goal rings).
class AnimatedRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double stroke;
  final Color color;
  final Color background;
  final Widget? child;
  final Duration duration;

  const AnimatedRing({
    super.key,
    required this.progress,
    required this.size,
    required this.color,
    required this.background,
    this.stroke = 12,
    this.child,
    this.duration = const Duration(milliseconds: 1100),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: stroke,
                  backgroundColor: background,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              if (child != null) child!,
            ],
          );
        },
      ),
    );
  }
}

/// Simple confetti-ish burst for the workout-complete moment.
class ConfettiBurst extends StatefulWidget {
  final bool play;
  final int count;
  final Duration duration;

  const ConfettiBurst({
    super.key,
    required this.play,
    this.count = 26,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_Particle> _particles =
      List.generate(widget.count, (_) => _Particle.random());

  @override
  void initState() {
    super.initState();
    if (widget.play) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (!_c.isAnimating && _c.value == 0) return const SizedBox.shrink();
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _c.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double spin;
  final Color color;
  final double size;

  _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.color,
    required this.size,
  });

  static final _rng = math.Random();

  factory _Particle.random() {
    const palette = [
      Color(0xFF246BFF),
      Color(0xFF43DCAB),
      Color(0xFFFF9A3D),
      Color(0xFFFF7A45),
      Color(0xFF78A4FF),
    ];
    return _Particle(
      angle: _rng.nextDouble() * math.pi * 2,
      speed: 120 + _rng.nextDouble() * 220,
      spin: (_rng.nextDouble() - 0.5) * 12,
      color: palette[_rng.nextInt(palette.length)],
      size: 4 + _rng.nextDouble() * 6,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 3);
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final dist = p.speed * t;
      final pos = center +
          Offset(
            math.cos(p.angle) * dist,
            math.sin(p.angle) * dist + 120 * t * t,
          );
      final opacity = (1 - t).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}