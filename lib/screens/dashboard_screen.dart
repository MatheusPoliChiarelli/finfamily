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

  Future<void> _saveOpeningBalance(double value) async {
    await _fs!.saveOpeningBalance(_month, value, FirebaseAuth.instance.currentUser!.uid);
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
    });
    await _materialize();
  }

  void _onSelectDay(int day) => setState(() => _selectedDay = day);

  Future<void> _newTransaction({required bool isIncome}) async {
    final date = DateTime(_month.year, _month.month, _selectedDay);
    final transaction = await showTransactionDialog(context, date, isIncome: isIncome);
    if (transaction != null) await _fs!.addTransaction(transaction);
  }
  Future<void> _onSection(String id) async {
    if (id == 'budget') {
      final limits = await showBudgetDialog(context, _budget.limits);
      if (limits != null) {
        await _fs!.saveBudget(_month, limits, FirebaseAuth.instance.currentUser!.uid);
      }
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
                      return _content(transactions, txSnap.connectionState);
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

  Widget _content(List<AppTransaction> transactions, ConnectionState state) {
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
          AppHeader(
            month: _month,
            selectedDay: _selectedDay,
            openingBalance: _budget.openingBalance,
            onShiftMonth: _shiftMonth,
            onSelectDay: _onSelectDay,
            onSaveOpeningBalance: _saveOpeningBalance,
            onNewExpense: () => _newTransaction(isIncome: false),
            onNewIncome: () => _newTransaction(isIncome: true),
            onSignOut: _auth.signOut,
          ),
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
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 900;
              final chart = _card(
                title: 'Despesas por categoria',
                child: CategoryChart(spent: spentByCategory),
              );
              final list = _card(
                title: 'Lançamentos do mês',
                child: _transactionsList(transactions, state),
              );
              if (narrow) {
                return Column(children: [chart, const SizedBox(height: 14), list]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: chart),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: list),
                ],
              );
            },
          ),
        ],
      ),
    );
  }


  int _daysElapsed() {
    final now = DateTime.now();
    if (now.year == _month.year && now.month == _month.month) return now.day;
    int _selectedDay = DateTime.now().day;
    return DateTime(_month.year, _month.month + 1, 0).day;
  }

  Widget _card({required String title, required Widget child}) {
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
          Text(title, style: AppTheme.ui(14, weight: FontWeight.w500)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color, bool highlight, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: highlight ? AppColors.surfaceRaised : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.borderAccent : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.ui(12, color: AppColors.textMuted)),
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
          Expanded(child: Text(label, style: AppTheme.ui(12, color: AppColors.textMuted))),
          Text(value, style: AppTheme.uiMoney(13, weight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _transactionsList(List<AppTransaction> transactions, ConnectionState state) {
    if (state == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Nenhum lançamento neste mês',
            style: AppTheme.ui(13, color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(children: transactions.map(_transactionRow).toList());
  }

  Widget _transactionRow(AppTransaction t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F2429), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Categories.byId(t.categoryId).icon, size: 16, color: Color(t.categoryColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(t.description, style: AppTheme.ui(13), overflow: TextOverflow.ellipsis),
                    ),
                    if (t.isRecurring) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.repeat, size: 13, color: AppColors.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${t.categoryName} · ${t.createdByName} · ${dayLabel(t.date)}',
                  style: AppTheme.ui(11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${t.isIncome ? '+' : '-'} ${plain(t.amount)}',
            style: AppTheme.uiMoney(13, color: t.isIncome ? AppColors.income : AppColors.expense),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _fs!.deleteTransaction(t.id),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}