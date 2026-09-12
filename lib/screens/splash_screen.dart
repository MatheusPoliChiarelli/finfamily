import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final Animation<double> _ringSweep;
  late final Animation<double> _symbolScale;
  late final Animation<double> _symbolFade;
  late final Animation<double> _glowPulse;
  late final Animation<double> _wordFade;
  late final Animation<double> _wordSpacing;
  late final Animation<double> _lineWidth;
  late final Animation<double> _tagFade;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));

    _ringSweep = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.02, 0.30, curve: Curves.easeInOutCubic)),
    );
    _symbolScale = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.14, 0.36, curve: Curves.easeOutBack)),
    );
    _symbolFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.14, 0.30, curve: Curves.easeOut)),
    );
    _glowPulse = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.30, 0.52, curve: Curves.easeInOut)),
    );
    _wordFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.36, 0.58, curve: Curves.easeOut)),
    );
    _wordSpacing = Tween(begin: 16.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.36, 0.66, curve: Curves.easeOutCubic)),
    );
    _lineWidth = Tween(begin: 0.0, end: 240.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.52, 0.72, curve: Curves.easeOutCubic)),
    );
    _tagFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.62, 0.82, curve: Curves.easeOut)),
    );
    _exitFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.93, 1.0, curve: Curves.easeIn)),
    );

    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final pulse = math.sin(_glowPulse.value * math.pi);

            return Opacity(
              opacity: _exitFade.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(96, 96),
                          painter: _RingPainter(
                            progress: _ringSweep.value,
                            color: AppColors.accent,
                          ),
                        ),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.28 * pulse),
                                blurRadius: 40 + 20 * pulse,
                                spreadRadius: 4 * pulse,
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: _symbolScale.value,
                          child: Opacity(
                            opacity: _symbolFade.value,
                            child: Text(
                              '\$',
                              style: AppTheme.display(52, color: AppColors.accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: _wordFade.value,
                    child: Text(
                      'FinFamily',
                      style: AppTheme.display(52).copyWith(letterSpacing: _wordSpacing.value),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: _lineWidth.value,
                    height: 1,
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: _tagFade.value,
                    child: Text(
                      'Todas as contas em um só lugar',
                      style: AppTheme.ui(14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.12);

    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}