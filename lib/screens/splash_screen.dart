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

  late final Animation<double> _coinDrop;
  late final Animation<double> _coinFade;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;
  late final Animation<double> _wordFade;
  late final Animation<double> _wordSpacing;
  late final Animation<double> _lineWidth;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2900));

    _coinDrop = Tween(begin: -160.0, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.05, 0.45, curve: Curves.bounceOut)),
    );
    _coinFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.05, 0.20, curve: Curves.easeOut)),
    );
    _ringScale = Tween(begin: 0.6, end: 3.4).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.42, 0.72, curve: Curves.easeOutCubic)),
    );
    _ringFade = Tween(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.42, 0.72, curve: Curves.easeOut)),
    );
    _wordFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.46, 0.80, curve: Curves.easeOut)),
    );
    _wordSpacing = Tween(begin: 14.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.46, 0.86, curve: Curves.easeOutCubic)),
    );
    _lineWidth = Tween(begin: 0.0, end: 190.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.62, 0.92, curve: Curves.easeOutCubic)),
    );
    _exitFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.90, 1.0, curve: Curves.easeIn)),
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
            return Opacity(
              opacity: _exitFade.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_c.value > 0.42)
                          Transform.scale(
                            scale: _ringScale.value,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: _ringFade.value),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        Transform.translate(
                          offset: Offset(0, _coinDrop.value),
                          child: Opacity(
                            opacity: _coinFade.value,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                    blurRadius: 26,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: _wordFade.value,
                    child: Text(
                      'FinFamily',
                      style: AppTheme.display(46).copyWith(letterSpacing: _wordSpacing.value),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: _lineWidth.value,
                    height: 1,
                    color: AppColors.accent.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _lineWidth.value / 190,
                    child: Text(
                      'as contas da casa, no mesmo lugar',
                      style: AppTheme.ui(12, color: AppColors.textMuted),
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