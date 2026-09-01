import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
            child: Row(
              children: [
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('FinFamily', style: AppTheme.display(22)),
              ],
            ),
          ),
          _item('overview', Icons.grid_view_outlined, 'Visão geral'),
          _item('summary', Icons.insights_outlined, 'Resumo do mês'),
          _item('budget', Icons.pie_chart_outline, 'Orçamento'),
          _item('recurring', Icons.repeat, 'Recorrentes'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'versão 0.1',
              style: AppTheme.ui(11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String id, IconData icon, String label) {
    final active = selected == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: InkWell(
        onTap: () => onSelect(id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: active ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTheme.ui(
                  13,
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  weight: active ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}