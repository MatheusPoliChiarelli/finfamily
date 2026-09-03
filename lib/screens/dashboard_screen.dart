import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/banks.dart';
import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../models/car.dart';
import '../models/fixed_bill.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/category_chart.dart';
import '../widgets/fixed_bill_dialog.dart';
import '../widgets/screen_glow.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/transaction_list.dart';
import 'cars_screen.dart';
import '../models/product.dart';
import 'vise_versa_screen.dart';

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
  String _bankId = Banks.geral.id;
  String _section = 'overview';
  Budget _budget = const Budget(month: '', limits: {});
  bool _loading = true;
  String? _error;
  List<Car> _activeCars = const [];
  List<Product> _products = const [];


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
      _fs!.cars().listen((cars) {
        if (mounted) setState(() => _activeCars = cars.where((c) => !c.isSold).toList());
      });

      _fs!.products().listen((products) {
        if (mounted) setState(() => _products = products);
      });

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

  void _onSelectBank(String id) => setState(() => _bankId = id);

  void _onSelectDay(int day) => setState(() => _selectedDay = day);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _saveOpeningBalance(double value) =>
      _fs!.saveOpeningBalance(_month, _bankId, value, _uid);

  Future<void> _saveClosingBalance(double value) =>
      _fs!.saveClosingBalance(_month, _bankId, value, _uid);

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final now = DateTime.now();
    final isCurrent = now.year == next.year && now.month == next.month;
    final lastDay = DateTime(next.year, next.month + 1, 0).day;

    setState(() {
      _month = next;
      _selectedDay = isCurrent ? now.day : _selectedDay.clamp(1, lastDay);
    });
  }

  Future<void> _newTransaction({required bool isIncome}) async {
    final date = DateTime(_month.year, _month.month, _selectedDay);
    final transaction = await showTransactionDialog(
      context,
      date,
      isIncome: isIncome,
      bankId: _bankId,
      activeCars: _activeCars,
      products: _products,
    );
    if (transaction == null) return;

    await _fs!.addTransaction(transaction);

    if (transaction.newCarModel != null) {
      await _fs!.addCar(Car(
        id: '',
        name: '${transaction.newCarBrand} ${transaction.newCarModel}'.trim(),
        plate: '',
        year: transaction.newCarYear ?? '',
        purchaseDate: transaction.date,
        purchasePrice: transaction.amount,
      ));
      return;
    }

    if (transaction.isCarSale && transaction.carId != null) {
      await _fs!.sellCar(transaction.carId!, transaction.amount, transaction.date);
      return;
    }

    if (transaction.fashionKind == 'compra') {
      final qty = transaction.quantity ?? 1;
      await _fs!.addProduct(Product(
        id: '',
        brand: transaction.fashionBrand ?? '',
        model: transaction.fashionModel ?? '',
        type: transaction.fashionType ?? 'outro',
        purchaseDate: transaction.date,
        unitCost: transaction.amount / qty,
        quantity: qty,
      ));
      return;
    }

    if (transaction.fashionKind == 'venda' && transaction.productId != null) {
      final product = _products.firstWhere((p) => p.id == transaction.productId);
      await _fs!.registerSale(
        product.id,
        product.sold,
        product.revenue,
        transaction.quantity ?? 1,
        transaction.amount,
      );
      return;
    }

    if (transaction.carId != null) {
      final car = _activeCars.firstWhere((c) => c.id == transaction.carId);
      await _fs!.updateCosts(car.id, [
        ...car.costs,
        CarCost(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          description: transaction.description,
          amount: transaction.amount,
          date: transaction.date,
          typeId: transaction.carCostType ?? 'outro',
        ),
      ]);
    }
  }

  Future<void> _newFixedBill() async {
    final bill = await showFixedBillDialog(context);
    if (bill != null) await _fs!.addFixedBill(bill);
  }

  Future<void> _onSection(String id) async {
    if (id == 'budget') {
      final limits = await showBudgetDialog(context, _budget.limits);
      if (limits != null) await _fs!.saveBudget(_month, limits, _uid);
      return;
    }
    setState(() => _section = id);
  }

  List<AppTransaction> _filterByBank(List<AppTransaction> all) {
    if (_bankId == Banks.geral.id) return all;
    return all.where((t) => t.bankId == _bankId).toList();
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
              child: ScreenGlow(
                color: Banks.byId(_bankId).color,
                active: _bankId != Banks.geral.id && _section != 'cars' && _section != 'fashion',
                child: StreamBuilder<Budget>(
                  stream: _fs!.budgetOfMonth(_month),
                  builder: (context, budgetSnap) {
                    _budget = budgetSnap.data ?? Budget(month: monthKey(_month), limits: const {});
                    return StreamBuilder<List<AppTransaction>>(
                      stream: _fs!.transactionsOfMonth(_month),
                      builder: (context, txSnap) {
                        final transactions = _filterByBank(txSnap.data ?? const <AppTransaction>[]);
                        final loading = txSnap.connectionState == ConnectionState.waiting;
                        return switch (_section) {
                          'summary' => _summaryView(transactions, loading),
                          'fixed' => _fixedView(),
                          'cars' => CarsScreen(fs: _fs!),
                          'fashion' => ViseVersaScreen(fs: _fs!),
                          _ => _overview(transactions, loading),
                        };
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _header({double dayBalance = 0, bool showDayBalance = false}) {
    return AppHeader(
      month: _month,
      selectedDay: _selectedDay,
      openingBalance: _budget.openingFor(_bankId),
      closingBalance: _budget.closingFor(_bankId),
      dayBalance: dayBalance,
      showDayBalance: showDayBalance,
      balancesEditable: _bankId != Banks.geral.id && _section == 'overview',
      showActions: _section == 'overview',
      selectedBankId: _bankId,
      onSelectBank: _onSelectBank,
      onShiftMonth: _shiftMonth,
      onSelectDay: _onSelectDay,
      onSaveOpeningBalance: _saveOpeningBalance,
      onSaveClosingBalance: _saveClosingBalance,
      onNewExpense: () => _newTransaction(isIncome: false),
      onNewIncome: () => _newTransaction(isIncome: true),
      onSignOut: _auth.signOut,
      canAddTransaction: _bankId != Banks.geral.id,
      title: switch (_section) {
        'summary' => 'Resumo do mês',
        'fixed' => 'Contas fixas',
        'fashion' => 'Vise Versa',
        _ => 'Visão geral',
      },
      showDayStrip: _section == 'overview',
    );
  }

  Widget _overview(List<AppTransaction> transactions, bool loading) {
    final dayTransactions = transactions.where((t) => t.date.day == _selectedDay).toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    final income = dayTransactions
        .where((t) => t.isIncome && !t.isTransfer)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = dayTransactions
        .where((t) => !t.isIncome && !t.isTransfer)
        .fold<double>(0, (s, t) => s + t.amount);

    final dayBalance = dayTransactions
        .fold<double>(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
    final dayColor = dayBalance > 0
        ? AppColors.income
        : dayBalance < 0
            ? AppColors.expense
            : AppColors.accent;

    final spentByCategory = <String, double>{};
    for (final t in dayTransactions.where((t) => !t.isIncome && !t.isTransfer)) {
      spentByCategory[t.categoryId] = (spentByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final dayLabelText = fullDayLabel(DateTime(_month.year, _month.month, _selectedDay));

    final untilYesterday = transactions
        .where((t) => t.date.day < _selectedDay)
        .fold<double>(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

    final runningBalance = _budget.openingFor(_bankId) + untilYesterday + dayBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(dayBalance: runningBalance, showDayBalance: true),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _metric('Entradas do dia', money(income), AppColors.income, false, Icons.arrow_downward)),
              const SizedBox(width: 14),
              Expanded(child: _metric('Saídas do dia', money(expense), AppColors.expense, false, Icons.arrow_upward)),
              const SizedBox(width: 14),
              Expanded(
                child: _metric(
                  'Balanço do dia',
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
                        showBank: _bankId == Banks.geral.id,
                      ),
              );
              if (narrow) {
                return Column(children: [chart, const SizedBox(height: 14), list]);
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: chart),
                    const SizedBox(width: 14),
                    Expanded(child: list),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryView(List<AppTransaction> transactions, bool loading) {
    final income = transactions
        .where((t) => t.isIncome && !t.isTransfer)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => !t.isIncome && !t.isTransfer)
        .fold<double>(0, (s, t) => s + t.amount);
    final balance = income - expense;
    final movement = transactions.fold<double>(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
    final declared = _budget.closingFor(_bankId) - _budget.openingFor(_bankId);
    final divergence = movement - declared;
    final matches = divergence.abs() < 0.01;

    final spentByCategory = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome && !t.isTransfer)) {
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
              Expanded(
                child: _metric(
                  'Saldo do mês',
                  money(balance),
                  balance >= 0 ? AppColors.income : AppColors.expense,
                  true,
                  Icons.account_balance_wallet_outlined,
                  borderColor: balance >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
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
              const SizedBox(width: 14),
              Expanded(
                child: _miniStat(
                  matches ? 'Confere com o extrato' : 'Falta lançar',
                  matches ? 'OK' : money(divergence.abs()),
                  valueColor: matches ? AppColors.income : AppColors.expense,
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
                        showBank: _bankId == Banks.geral.id,
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

  Widget _fixedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 22),
          StreamBuilder<List<FixedBill>>(
            stream: _fs!.fixedBills(),
            builder: (context, snap) {
              final bills = snap.data ?? const <FixedBill>[];
              final total = bills.fold<double>(0, (s, b) => s + b.amount);

              final byCategory = <String, double>{};
              for (final b in bills) {
                byCategory[b.categoryId] = (byCategory[b.categoryId] ?? 0) + b.amount;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: _miniStat('Total mensal', money(total))),
                      const SizedBox(width: 14),
                      Expanded(child: _miniStat('Contas cadastradas', '${bills.length}')),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: _newFixedBill,
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 900;
                      final list = _card(
                        title: 'Contas fixas da casa',
                        subtitle: 'Referência do custo mensal',
                        child: snap.connectionState == ConnectionState.waiting
                            ? _spinner()
                            : bills.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: Text(
                                        'Nenhuma conta fixa cadastrada',
                                        style: AppTheme.ui(13, color: AppColors.textMuted),
                                      ),
                                    ),
                                  )
                                : Column(children: bills.map(_fixedBillRow).toList()),
                      );
                      final chart = _card(
                        title: 'Composição por categoria',
                        subtitle: 'Peso de cada categoria no custo fixo',
                        child: CategoryChart(spent: byCategory),
                      );
                      if (narrow) {
                        return Column(children: [list, const SizedBox(height: 14), chart]);
                      }
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: list),
                            const SizedBox(width: 14),
                            Expanded(child: chart),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fixedBillRow(FixedBill b) {
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
            child: Icon(Categories.byId(b.categoryId).icon, size: 17, color: Color(b.categoryColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name, style: AppTheme.ui(14)),
                const SizedBox(height: 3),
                Text(b.categoryName, style: AppTheme.ui(11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(money(b.amount), style: AppTheme.uiMoney(14, weight: FontWeight.w500)),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => _fs!.deleteFixedBill(b.id),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTheme.ui(17, color: AppColors.accent, weight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: AppTheme.ui(12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 20),
          Flexible(child: SingleChildScrollView(child: child)),
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
  
  Widget _miniStat(String label, String value, {Color? valueColor}) {
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
          Text(value, style: AppTheme.uiMoney(13, color: valueColor, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}