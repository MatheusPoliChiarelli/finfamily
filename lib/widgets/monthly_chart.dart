import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

class MonthlyChart extends StatelessWidget {
  const MonthlyChart({
    super.key,
    required this.values,
    required this.color,
    this.showNegative = false,
    this.height = 200,
  });

  final List<double> values;
  final Color color;
  final bool showNegative;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final barWidth = (constraints.maxWidth - gap * (values.length - 1)) / values.length;

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
                  final barColor = showNegative && v < 0 ? AppColors.expense : color;

                  return Padding(
                    padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : gap),
                    child: SizedBox(
                      width: barWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (v != 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  money(v),
                                  maxLines: 1,
                                  style: AppTheme.uiMoney(9, color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                            width: barWidth,
                            height: (ratio * (height - 30)).clamp(v == 0 ? 0.0 : 3.0, height - 30),
                            decoration: BoxDecoration(
                              color: v == 0 ? AppColors.surfaceRaised : barColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(values.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : gap),
                  child: SizedBox(
                    width: barWidth,
                    child: Text(
                      shortMonth(i + 1),
                      textAlign: TextAlign.center,
                      style: AppTheme.ui(11, color: AppColors.textMuted),
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