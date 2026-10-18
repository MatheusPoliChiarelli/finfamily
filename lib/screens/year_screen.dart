import 'package:flutter/material.dart';

import '../data/banks.dart';
import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/category_chart.dart';
import '../widgets/monthly_chart.dart';

const _nonExpenseCategories = {'vise_versa', 'robmotors', 'duplicata', 'transporte_nena'};
const _viseVersaCategories = {'vise_versa', 'duplicata', 'transporte_nena'};
const _robMotorsCategories = {'robmotors'};

class YearScreen extends StatefulWidget {
  const YearScreen({
    super.key,
    required this.fs,
    required this.bankId,
    required this.year,
    required this.headerBuilder,
    required this.onBalances,
  });

  final FirestoreService fs;
  final String bankId;
  final int year;
  final Widget Function() headerBuilder;
  final void Function(double opening, double closing) onBalances;

  @override
  State<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends State<YearScreen> {
  String _categoryFilter = 'all';

  List<AppTransaction> _filter(List<AppTransaction> all) {
    if (widget.bankId == Banks.geral.id) return all;
    return all.where((t) => t.bankId == widget.bankId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppTransaction>>(
      stream: widget.fs.transactionsOfYear(widget.year),
      builder: (context, txSnap) {
        final transactions = _filter(txSnap.data ?? const <AppTransaction>[]);
        final loading = txSnap.connectionState == ConnectionState.waiting;

        return StreamBuilder<List<Budget>>(
          stream: widget.fs.budgetsOfYear(widget.year),
          builder: (context, budgetSnap) {
            final budgets = budgetSnap.data ?? const <Budget>[];
            return _content(transactions, budgets, loading);
          },
        );
      },
    );
  }

  Widget _content(List<AppTransaction> transactions, List<Budget> budgets, bool loading) {
    final income = transactions
        .where((t) => t.isIncome && !t.isTransfer)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => !t.isIncome && !t.isTransfer)
        .fold<double>(0, (s, t) => s + t.amount);
    final balance = income - expense;

    final spentByCategory = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome && !t.isTransfer)) {
      if (!_passesFilter(t.categoryId)) continue;
      spentByCategory[t.categoryId] = (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final earnedByCategory = <String, double>{};
    for (final t in transactions.where((t) => t.isIncome && !t.isTransfer)) {
      earnedByCategory[t.categoryId] = (earnedByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final topCategory = spentByCategory.entries.isEmpty
        ? null
        : (spentByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    final now = DateTime.now();
    final isCurrentYear = now.year == widget.year;
    final monthsElapsed = isCurrentYear ? now.month : 12;

    final monthlyIncome = List<double>.filled(12, 0);
    final monthlyExpense = List<double>.filled(12, 0);
    final monthlyNet = List<double>.filled(12, 0);

    for (final t in transactions) {
      final i = t.date.month - 1;
      if (!t.isTransfer) {
        if (t.isIncome) {
          monthlyIncome[i] += t.amount;
        } else {
          monthlyExpense[i] += t.amount;
        }
      }
      monthlyNet[i] += t.isIncome ? t.amount : -t.amount;
    }

    final patrimony = List<double>.filled(12, 0);
    var yearOpening = 0.0;
    var yearClosing = 0.0;
    var lastMonthWithClosing = 0;

    for (final b in budgets) {
      final parts = b.month.split('-');
      if (parts.length != 2) continue;
      final m = int.tryParse(parts[1]);
      if (m == null || m < 1 || m > 12) continue;

      final closing = b.closingFor(widget.bankId);
      patrimony[m - 1] = closing;

      if (m == 1) yearOpening = b.openingFor(widget.bankId);
      if (closing != 0 && m > lastMonthWithClosing) {
        lastMonthWithClosing = m;
        yearClosing = closing;
      }
    }

    widget.onBalances(yearOpening, yearClosing);

    final monthlyAverage = monthsElapsed > 0 ? expense / monthsElapsed : 0.0;

    final bestMonth = monthlyNet.asMap().entries.where((e) => e.value != 0).fold<MapEntry<int, double>?>(
      null,
      (best, e) => best == null || e.value > best.value ? e : best,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.headerBuilder(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _metric('Entradas', money(income), AppColors.income, Icons.arrow_upward)),
              const SizedBox(width: 14),
              Expanded(child: _metric('Saídas', money(expense), AppColors.expense, Icons.arrow_downward)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniStat('Gasto médio mensal', money(monthlyAverage))),
              const SizedBox(width: 14),
              Expanded(
                child: _miniStat(
                  'Maior categoria',
                  topCategory == null ? '--' : Categories.byId(topCategory.key).name,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _miniStat('Lançamentos no ano', '${transactions.length}')),
              const SizedBox(width: 14),
              Expanded(
                child: _miniStat(
                  'Melhor mês',
                  bestMonth == null ? '--' : fullMonth(bestMonth.key + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _card(
                  title: 'Saídas por categoria',
                  subtitle: 'Ano de ${widget.year}',
                  action: _expenseFilterButton(),
                  child: loading ? _spinner() : CategoryChart(spent: spentByCategory),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _card(
                  title: 'Entradas por categoria',
                  subtitle: 'Ano de ${widget.year}',
                  child: loading ? _spinner() : CategoryChart(spent: earnedByCategory, isIncome: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Patrimônio ao longo do ano',
            subtitle: 'Saldo final de cada mês',
            child: MonthlyChart(values: patrimony, color: AppColors.accent, showNegative: true, height: 220),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _card(
                  title: 'Entradas por mês',
                  subtitle: 'Ano de ${widget.year}',
                  child: MonthlyChart(values: monthlyIncome, color: AppColors.income),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _card(
                  title: 'Saídas por mês',
                  subtitle: 'Ano de ${widget.year}',
                  child: MonthlyChart(values: monthlyExpense, color: AppColors.expense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _passesFilter(String categoryId) {
    switch (_categoryFilter) {
      case 'expenses':
        return !_nonExpenseCategories.contains(categoryId);
      case 'vise_versa':
        return _viseVersaCategories.contains(categoryId);
      case 'robmotors':
        return _robMotorsCategories.contains(categoryId);
      default:
        return true;
    }
  }

  Widget _expenseFilterButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _filterChip('Todas', 'all'),
        const SizedBox(width: 6),
        _filterChip('Apenas despesas', 'expenses'),
        const SizedBox(width: 6),
        _filterChip('Vise Versa', 'vise_versa'),
        const SizedBox(width: 6),
        _filterChip('RobMotors', 'robmotors'),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _categoryFilter == value;
    return InkWell(
      onTap: () => setState(() => _categoryFilter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.ui(
            11,
            color: selected ? AppColors.accent : AppColors.textMuted,
            weight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _spinner() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ),
      );

  Widget _card({required String title, String? subtitle, Widget? action, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.ui(17, color: AppColors.accent, weight: FontWeight.w500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTheme.ui(12, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color, IconData icon, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: borderColor != null ? AppColors.surfaceRaised : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.border, width: borderColor != null ? 1 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.ui(16, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTheme.displayMoney(26, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.ui(12, color: AppColors.accent))),
          Text(value, style: AppTheme.uiMoney(13, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}