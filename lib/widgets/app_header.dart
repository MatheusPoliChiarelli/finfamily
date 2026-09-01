import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'opening_balance_field.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.openingBalance,
    required this.onShiftMonth,
    required this.onSelectDay,
    required this.onSaveOpeningBalance,
    required this.onNewExpense,
    required this.onNewIncome,
    required this.onSignOut,
  });

  final DateTime month;
  final int selectedDay;
  final double openingBalance;
  final ValueChanged<int> onShiftMonth;
  final ValueChanged<int> onSelectDay;
  final ValueChanged<double> onSaveOpeningBalance;
  final VoidCallback onNewExpense;
  final VoidCallback onNewIncome;
  final VoidCallback onSignOut;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Você';
    final email = user?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Visão geral', style: AppTheme.display(26)),
            const SizedBox(width: 22),
            _monthSelector(),
            const SizedBox(width: 12),
            OpeningBalanceField(
              key: ValueKey('${monthKey(month)}-$openingBalance'),
              value: openingBalance,
              onSave: onSaveOpeningBalance,
            ),
            const Spacer(),
            _actionButton('Saída', Icons.arrow_upward, AppColors.expense, onNewExpense),
            const SizedBox(width: 10),
            _actionButton('Entrada', Icons.arrow_downward, AppColors.income, onNewIncome),
            const SizedBox(width: 16),
            _avatarMenu(name, email),
          ],
        ),
        const SizedBox(height: 20),
        _dayStrip(),
      ],
    );
  }

  Widget _monthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _arrow(Icons.chevron_left, () => onShiftMonth(-1)),
          SizedBox(
            width: 138,
            child: Text(
              monthLabel(month),
              textAlign: TextAlign.center,
              style: AppTheme.ui(13, weight: FontWeight.w500),
            ),
          ),
          _arrow(Icons.chevron_right, () => onShiftMonth(1)),
        ],
      ),
    );
  }

  Widget _dayStrip() {
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final size = ((constraints.maxWidth - gap * (totalDays - 1)) / totalDays).clamp(30.0, 44.0);

        return Row(
          children: List.generate(totalDays, (index) {
            final day = index + 1;
            final selected = day == selectedDay;
            final isToday = isCurrentMonth && day == now.day;

            return Padding(
              padding: EdgeInsets.only(right: day == totalDays ? 0 : gap),
              child: InkWell(
                onTap: () => onSelectDay(day),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.accent
                          : isToday
                              ? AppColors.accent.withValues(alpha: 0.6)
                              : AppColors.border,
                      width: selected || isToday ? 1 : 0.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.45),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: AppTheme.uiMoney(
                      12,
                      color: selected
                          ? AppColors.onAccent
                          : isToday
                              ? AppColors.accent
                              : AppColors.textMuted,
                      weight: selected || isToday ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 9),
            Text(label, style: AppTheme.ui(13, color: color, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _avatarMenu(String name, String email) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      onSelected: (value) {
        if (value == 'signout') onSignOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTheme.ui(13, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(email, style: AppTheme.ui(11, color: AppColors.textMuted)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'signout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text('Sair', style: AppTheme.ui(13)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentSoft,
          border: Border.all(color: AppColors.borderAccent, width: 0.5),
        ),
        child: Text(
          _initials(name),
          style: AppTheme.ui(13, color: AppColors.accent, weight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 17, color: AppColors.textSecondary),
      ),
    );
  }
}