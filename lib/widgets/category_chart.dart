import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key, required this.spent});

  final Map<String, double> spent;

  @override
  Widget build(BuildContext context) {
    final entries = spent.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Sem despesas registradas neste mês',
            style: AppTheme.ui(13, color: AppColors.textMuted),
          ),
        ),
      );
    }

    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final max = entries.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: entries.map((e) {
        final category = Categories.byId(e.key);
        final ratio = e.value / max;
        final share = total == 0 ? 0.0 : e.value / total * 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(category.icon, size: 15, color: Color(category.color)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(category.name, style: AppTheme.ui(13, color: AppColors.textSecondary)),
                  ),
                  Text(money(e.value), style: AppTheme.uiMoney(13)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${share.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: AppTheme.uiMoney(12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio.clamp(0.02, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: Color(category.color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}