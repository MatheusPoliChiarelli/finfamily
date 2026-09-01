import 'package:flutter/material.dart';

class ScreenGlow extends StatelessWidget {
  const ScreenGlow({
    super.key,
    required this.color,
    required this.active,
    required this.child,
  });

  final Color color;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 320),
            opacity: active ? 1 : 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.05,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    color.withValues(alpha: 0.10),
                    color.withValues(alpha: 0.22),
                  ],
                  stops: const [0.0, 0.62, 0.87, 1.0],
                ),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}