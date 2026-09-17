import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'balance_field.dart';
import 'bank_selector.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.openingBalance,
    required this.closingBalance,
    required this.onShiftMonth,
    required this.onSelectDay,
    required this.onSaveOpeningBalance,
    required this.onSaveClosingBalance,
    required this.onNewExpense,
    required this.onNewIncome,
    required this.selectedBankId,
    required this.onSelectBank,
    required this.dayBalance,
    this.title = 'Visão geral',
    this.showDayStrip = true,
    this.canAddTransaction = true,
    this.balancesEditable = true,
    this.showActions = true,
    this.showDayBalance = false,
    this.showBalances = true,
    this.titleOverride,
    this.bankBorder,
  });

  final DateTime month;
  final int selectedDay;
  final double openingBalance;
  final double closingBalance;
  final ValueChanged<int> onShiftMonth;
  final ValueChanged<int> onSelectDay;
  final ValueChanged<double> onSaveOpeningBalance;
  final ValueChanged<double> onSaveClosingBalance;
  final VoidCallback onNewExpense;
  final VoidCallback onNewIncome;
  final String title;
  final bool showDayStrip;
  final String selectedBankId;
  final ValueChanged<String> onSelectBank;
  final bool canAddTransaction;
  final bool balancesEditable;
  final bool showActions;
  final double dayBalance;
  final bool showDayBalance;
  final bool showBalances;
  final String? titleOverride;
  final Color? bankBorder;

    @override
  Widget build(BuildContext context) {
    final hasBoth = openingBalance != 0 && closingBalance != 0;
    final monthBalance = hasBoth ? closingBalance - openingBalance : null;
    final balanceColor = monthBalance == null
        ? null
        : (monthBalance >= 0 ? AppColors.income : AppColors.expense);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _monthSelector(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: BankSelector(selectedId: selectedBankId, onSelect: onSelectBank),
              ),
            ),
            const SizedBox(width: 16),
            Opacity(
              opacity: showActions && canAddTransaction ? 1 : 0,
              child: IgnorePointer(
                ignoring: !(showActions && canAddTransaction),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionButton('Entrada', Icons.arrow_upward, AppColors.income, onNewIncome),
                    const SizedBox(width: 8),
                    _actionButton('Saída', Icons.arrow_downward, AppColors.expense, onNewExpense),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showBalances) ...[
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                BalanceField(
                  key: ValueKey('open-${monthKey(month)}-$selectedBankId-$openingBalance'),
                  label: 'Saldo inicial do mês',
                  icon: Icons.savings_outlined,
                  value: openingBalance,
                  onSave: balancesEditable ? onSaveOpeningBalance : null,
                  borderColor: bankBorder,
                ),
                const SizedBox(width: 12),
                if (showDayBalance) ...[
                  BalanceField(
                    label: 'Saldo do dia',
                    icon: Icons.today_outlined,
                    value: dayBalance,
                    valueColor: dayBalance >= 0 ? AppColors.income : AppColors.expense,
                    borderColor: bankBorder,
                  ),
                  const SizedBox(width: 12),
                ],
                BalanceField(
                  key: ValueKey('close-${monthKey(month)}-$selectedBankId-$closingBalance'),
                  label: 'Saldo final do mês',
                  icon: Icons.account_balance_outlined,
                  value: closingBalance,
                  onSave: balancesEditable ? onSaveClosingBalance : null,
                  borderColor: bankBorder,
                ),
                const SizedBox(width: 12),
                BalanceField(
                  label: 'Balanço do mês',
                  icon: Icons.swap_vert,
                  value: monthBalance,
                  valueColor: balanceColor,
                  borderColor: balanceColor,
                ),
              ],
            ),
          ),
        ],
        if (showDayStrip) ...[
          const SizedBox(height: 18),
          _dayStrip(context),
        ],
      ],
    );
  }

  Widget _monthSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(Icons.chevron_left, () => onShiftMonth(-1), AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(titleOverride ?? monthLabel(month), style: AppTheme.display(30)),
        const SizedBox(width: 6),
        _arrow(Icons.chevron_right, () => onShiftMonth(1), AppColors.textSecondary),
      ],
    );
  }

  Widget _dayStrip(BuildContext context) {
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 5.0;
        final width = (constraints.maxWidth - gap * (totalDays - 1)) / totalDays;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(totalDays, (index) {
            final day = index + 1;
            final date = DateTime(month.year, month.month, day);
            final selected = day == selectedDay;
            final isToday = isCurrentMonth && day == now.day;
            final today = DateTime(now.year, now.month, now.day);
            final isPast = !date.isAfter(today);

            return Padding(
              padding: EdgeInsets.only(right: day == totalDays ? 0 : gap),
              child: InkWell(
                onTap: () => onSelectDay(day),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: width,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentSoft
                        : (isPast ? AppColors.surface : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? (bankBorder ?? AppColors.borderAccent)
                          : (isToday
                              ? (bankBorder ?? AppColors.accent)
                              : (isPast ? (bankBorder ?? AppColors.border) : Colors.transparent)),
                      width: selected || isToday ? 1 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayShort[date.weekday - 1],
                        style: AppTheme.ui(
                          10,
                          color: selected ? AppColors.accent : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$day',
                        style: AppTheme.uiMoney(
                          15,
                          color: selected
                              ? AppColors.accent
                              : (isPast ? AppColors.textSecondary : AppColors.textMuted),
                          weight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 150,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(icon, size: 17, color: AppColors.bg),
            ),
            const SizedBox(width: 10),
            Text(label, style: AppTheme.ui(14, color: color, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }


  Widget _arrow(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}