import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/category_chart.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/transaction_list.dart';
import '../models/recurring_rule.dart';
import '../widgets/recurring_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();

  FirestoreService? _fs;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;
  String _section = 'overview';
  Budget _budget = const Budget(month: '', limits: {});
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final householdId = await _auth.loadHouseholdId();
      if (householdId == null) {
        setState(() {
          _error = 'Não encontramos sua casa. Saia e entre novamente';
          _loading = false;
        });
        return;
      }
      _fs = FirestoreService(householdId);
      await _materialize();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os dados';
          _loading = false;
        });
      }
    }
  }

  Future<void> _newRecurring() async {
    final rule = await showRecurringDialog(context, _month);
    if (rule != null) await _fs!.addRecurring(rule);
  }

  Future<void> _materialize() async {
    final user = FirebaseAuth.instance.currentUser!;
    await _fs!.ensureRecurringForMonth(_month, user.uid, user.displayName ?? 'Alguém');
  }

  Future<void> _shiftMonth(int delta) async {
    final next = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    final isCurrent = now.year == next.year && now.month == next.month;
    final lastDay = DateTime(next.year, next.month + 1, 0).day;

    setState(() {
      _month = next;
      _selectedDay = isCurrent ? now.day : _selectedDay.clamp(1, lastDay);
    });
    await _materialize();
  }

  void _onSelectDay(int day) => setState(() => _selectedDay = day);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _saveOpeningBalance(double value) => _fs!.saveOpeningBalance(_month, value, _uid);

  Future<void> _saveClosingBalance(double value) => _fs!.saveClosingBalance(_month, value, _uid);

  Future<void> _newTransaction({required bool isIncome}) async {
    final date = DateTime(_month.year, _month.month, _selectedDay);
    final transaction = await showTransactionDialog(context, date, isIncome: isIncome);
    if (transaction != null) await _fs!.addTransaction(transaction);
  }

  Future<void> _onSection(String id) async {
    if (id == 'budget') {
      final limits = await showBudgetDialog(context, _budget.limits);
      if (limits != null) await _fs!.saveBudget(_month, limits, _uid);
      return;
    }
    setState(() => _section = id);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AppTheme.ui(14, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _auth.signOut,
                child: Text('Sair', style: AppTheme.ui(13, color: AppColors.accent)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(selected: _section, onSelect: _onSection),
            Expanded(
              child: StreamBuilder<Budget>(
                stream: _fs!.budgetOfMonth(_month),
                builder: (context, budgetSnap) {
                  _budget = budgetSnap.data ?? Budget(month: monthKey(_month), limits: const {});
                  return StreamBuilder<List<AppTransaction>>(
                    stream: _fs!.transactionsOfMonth(_month),
                    builder: (context, txSnap) {
                      final transactions = txSnap.data ?? const <AppTransaction>[];
                      final loading = txSnap.connectionState == ConnectionState.waiting;
                      return switch (_section) {
                        'summary' => _summaryView(transactions, loading),
                        'fixed' => _fixedView(),
                        _ => _overview(transactions, loading),
                      };
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return AppHeader(
      month: _month,
      selectedDay: _selectedDay,
      openingBalance: _budget.openingBalance,
      closingBalance: _budget.closingBalance,
      onShiftMonth: _shiftMonth,
      onSelectDay: _onSelectDay,
      onSaveOpeningBalance: _saveOpeningBalance,
      onSaveClosingBalance: _saveClosingBalance,
      onNewExpense: () => _newTransaction(isIncome: false),
      onNewIncome: () => _newTransaction(isIncome: true),
      onSignOut: _auth.signOut,
      title: switch (_section) {
        'summary' => 'Resumo do mês',
        'fixed' => 'Contas fixas',
        _ => 'Visão geral',
      },
      showDayStrip: _section == 'overview',
    );
  }


  Widget _fixedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 22),
          StreamBuilder<List<RecurringRule>>(
            stream: _fs!.recurringRules(),
            builder: (context, snap) {
              final rules = snap.data ?? const <RecurringRule>[];
              final total = rules
                  .where((r) => !r.isIncome && r.active)
                  .fold<double>(0, (s, r) => s + r.amount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: _miniStat('Total mensal em contas fixas', money(total))),
                      const SizedBox(width: 14),
                      Expanded(child: _miniStat('Contas cadastradas', '${rules.length}')),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: _newRecurring,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nova conta fixa'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.onAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _card(
                    title: 'Contas fixas da casa',
                    subtitle: 'Lançadas automaticamente a cada mês',
                    child: snap.connectionState == ConnectionState.waiting
                        ? _spinner()
                        : rules.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    'Nenhuma conta fixa cadastrada',
                                    style: AppTheme.ui(13, color: AppColors.textMuted),
                                  ),
                                ),
                              )
                            : Column(children: rules.map(_recurringRow).toList()),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recurringRow(RecurringRule r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F2429), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Categories.byId(r.categoryId).icon, size: 17, color: Color(r.categoryColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.description, style: AppTheme.ui(14)),
                const SizedBox(height: 3),
                Text(
                  '${r.categoryName} · todo dia ${r.dayOfMonth}',
                  style: AppTheme.ui(11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            money(r.amount),
            style: AppTheme.uiMoney(
              14,
              color: r.isIncome ? AppColors.income : AppColors.expense,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => _fs!.deleteRecurring(r.id),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(List<AppTransaction> transactions, bool loading) {
    final dayTransactions = transactions.where((t) => t.date.day == _selectedDay).toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    final income = dayTransactions.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final expense = dayTransactions.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final dayBalance = income - expense;
    final dayColor = dayBalance > 0
        ? AppColors.income
        : dayBalance < 0
            ? AppColors.expense
            : AppColors.accent;

    final spentByCategory = <String, double>{};
    for (final t in dayTransactions.where((t) => !t.isIncome)) {
      spentByCategory[t.categoryId] = (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final dayLabelText = fullDayLabel(DateTime(_month.year, _month.month, _selectedDay));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _metric('Entradas do dia', money(income), AppColors.income, false, Icons.arrow_downward)),
              const SizedBox(width: 14),
              Expanded(child: _metric('Saídas do dia', money(expense), AppColors.expense, false, Icons.arrow_upward)),
              const SizedBox(width: 14),
              Expanded(
                child: _metric(
                  'Saldo do dia',
                  money(dayBalance),
                  dayColor,
                  true,
                  Icons.account_balance_wallet_outlined,
                  borderColor: dayBalance == 0 ? null : dayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 900;
              final chart = _card(
                title: 'Despesas por categoria',
                subtitle: dayLabelText,
                child: CategoryChart(spent: spentByCategory),
              );
              final list = _card(
                title: 'Lançamentos do dia',
                subtitle: dayLabelText,
                child: loading
                    ? _spinner()
                    : TransactionList(
                        transactions: dayTransactions,
                        onDelete: (id) => _fs!.deleteTransaction(id),
                        emptyMessage: 'Nada lançado neste dia',
                        showDate: false,
                      ),
              );
              if (narrow) {
                return Column(children: [chart, const SizedBox(height: 14), list]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: 14),
                  Expanded(child: list),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryView(List<AppTransaction> transactions, bool loading) {
    final income = transactions.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final expense = transactions.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final balance = _budget.openingBalance + income - expense;

    final spentByCategory = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      spentByCategory[t.categoryId] = (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final daysElapsed = _daysElapsed();
    final dailyAverage = daysElapsed > 0 ? expense / daysElapsed : 0.0;

    final topCategory = spentByCategory.entries.isEmpty
        ? null
        : (spentByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _metric('Receitas', money(income), AppColors.income, false, Icons.arrow_downward)),
              const SizedBox(width: 14),
              Expanded(child: _metric('Despesas', money(expense), AppColors.expense, false, Icons.arrow_upward)),
              const SizedBox(width: 14),
              Expanded(child: _metric('Saldo do mês', money(balance), AppColors.accent, true, Icons.account_balance_wallet_outlined)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniStat('Média diária de gastos', money(dailyAverage))),
              const SizedBox(width: 14),
              Expanded(
                child: _miniStat(
                  'Maior categoria',
                  topCategory == null ? '--' : Categories.byId(topCategory.key).name,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _miniStat('Total de lançamentos', '${transactions.length}')),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 900;
              final chart = _card(
                title: 'Despesas por categoria',
                subtitle: monthLabel(_month),
                child: CategoryChart(spent: spentByCategory),
              );
              final list = _card(
                title: 'Todos os lançamentos',
                subtitle: monthLabel(_month),
                child: loading
                    ? _spinner()
                    : TransactionList(
                        transactions: transactions,
                        onDelete: (id) => _fs!.deleteTransaction(id),
                        emptyMessage: 'Nenhum lançamento neste mês',
                      ),
              );
              if (narrow) {
                return Column(children: [chart, const SizedBox(height: 14), list]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: 14),
                  Expanded(child: list),
                ],
              );
            },
          ),
        ],
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

  int _daysElapsed() {
    final now = DateTime.now();
    if (now.year == _month.year && now.month == _month.month) return now.day;
    return DateTime(_month.year, _month.month + 1, 0).day;
  }

  Widget _card({required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTheme.ui(17, color: AppColors.accent, weight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: AppTheme.ui(12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _metric(
    String label,
    String value,
    Color color,
    bool highlight,
    IconData icon, {
    Color? borderColor,
  }) {
    final border = borderColor ?? (highlight ? AppColors.borderAccent : AppColors.border);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: highlight ? AppColors.surfaceRaised : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: borderColor != null ? 1 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.ui(12, color: AppColors.accent)),
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