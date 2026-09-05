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

    final maxValue = values.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    final safeMax = maxValue == 0 ? 1.0 : maxValue;
    final hasNegative = showZeroLine && values.any((v) => v < 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        final barWidth = ((constraints.maxWidth - gap * (values.length - 1)) / values.length)
            .clamp(4.0, 60.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (i) {
                  final v = values[i];
                  final ratio = (v.abs() / safeMax).clamp(0.0, 1.0);
                  final negative = v < 0;
                  final barColor = hasNegative && negative ? AppColors.expense : color;

                  return Padding(
                    padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : gap),
                    child: Tooltip(
                      message: '${i + 1}: ${money(v)}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            width: barWidth,
                            height: (ratio * 138).clamp(v == 0 ? 0.0 : 2.0, 138.0),
                            decoration: BoxDecoration(
                              color: v == 0 ? AppColors.surfaceRaised : barColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(values.length, (i) {
                final day = i + 1;
                final show = day == 1 || day % 5 == 0 || day == values.length;
                return Padding(
                  padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : gap),
                  child: SizedBox(
                    width: barWidth,
                    child: Text(
                      show ? '$day' : '',
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
    );
  }
}