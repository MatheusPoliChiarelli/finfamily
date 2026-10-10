import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

class DailyChart extends StatelessWidget {
  const DailyChart({
    super.key,
    required this.values,
    required this.color,
    this.showZeroLine = false,
    this.height = 150,
  });

  final List<double> values;
  final Color color;
  final bool showZeroLine;
  final double height;

  double _pow10(int exp) {
    var result = 1.0;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }

  double _niceMax(double raw) {
    if (raw <= 0) return 1;
    final magnitude = _pow10(raw.floor().toString().length - 1);
    final steps = [1.0, 2.0, 2.5, 5.0, 10.0];
    for (final s in steps) {
      final candidate = magnitude * s;
      if (candidate >= raw) return candidate;
    }
    return magnitude * 10;
  }

  String _axisLabel(double v) {
    if (v == 0) return '0';
    if (v.abs() >= 1000) {
      final k = v / 1000;
      return '${k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Sem dados neste mês', style: AppTheme.ui(13, color: AppColors.textMuted)),
        ),
      );
    }

    final rawMax = values.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    final safeMax = _niceMax(rawMax);
    final hasNegative = showZeroLine && values.any((v) => v < 0);

    const ticks = 4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(ticks + 1, (i) {
              final value = safeMax * (ticks - i) / ticks;
              return Text(
                _axisLabel(value),
                style: AppTheme.uiMoney(9, color: AppColors.textMuted),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 3.0;
              final barWidth = ((constraints.maxWidth - gap * (values.length - 1)) / values.length)
                  .clamp(4.0, 60.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            ticks + 1,
                            (_) => Container(height: 0.5, color: AppColors.border),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(values.length, (i) {
                            final v = values[i];
                            final ratio = (v.abs() / safeMax).clamp(0.0, 1.0);
                            final negative = v < 0;
                            final barColor = hasNegative && negative ? AppColors.expense : color;
                            final barHeight = (ratio * height).clamp(v == 0 ? 0.0 : 2.0, height);

                            return Padding(
                              padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : gap),
                              child: Tooltip(
                                message: '${i + 1}: ${money(v)}',
                                preferBelow: false,
                                verticalOffset: -(height / 2) - 12,
                                child: SizedBox(
                                  width: barWidth,
                                  height: height,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeOutCubic,
                                        width: barWidth,
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: v == 0 ? AppColors.surfaceRaised : barColor,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(values.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : gap),
                        child: SizedBox(
                          width: barWidth,
                          child: Text(
                            '${i + 1}',
                            textAlign: TextAlign.center,
                            style: AppTheme.uiMoney(9, color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}