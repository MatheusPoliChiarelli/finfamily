import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/banks.dart';
import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../models/car.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/category_chart.dart';
import '../widgets/screen_glow.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/transaction_list.dart';
import 'cars_screen.dart';
import '../models/product.dart';
import 'vise_versa_screen.dart';
import 'package:flutter/services.dart';
import '../widgets/daily_chart.dart';
import 'dart:async';
import 'year_screen.dart';


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
  bool _showAllTransactions = false;
  String _dayBuffer = '';
  Timer? _dayTimer;


  @override
  void initState() {
    super.initState();
    _init();
    HardwareKeyboard.instance.addHandler(_globalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_globalKey);
    _dayTimer?.cancel();
    super.dispose();
  }
  



  void _typeDay(String digit) {
    if (_section != 'overview' || _typing) return;

    _dayTimer?.cancel();
    final lastDay = DateTime(_month.year, _month.month + 1, 0).day;

    if (_dayBuffer.isNotEmpty) {
      final candidate = int.parse('$_dayBuffer$digit');
      _dayBuffer = '';
      if (candidate >= 1 && candidate <= lastDay) {
        setState(() => _selectedDay = candidate);
      } else {
        final single = int.parse(digit);
        if (single >= 1 && single <= lastDay) setState(() => _selectedDay = single);
      }
      return;
    }

    final single = int.parse(digit);
    final canBePrefix = single >= 1 && single <= 3;

    if (canBePrefix) {
      _dayBuffer = digit;
      _dayTimer = Timer(const Duration(milliseconds: 500), () {
        _dayBuffer = '';
        if (mounted) setState(() => _selectedDay = single);
      });
      return;
    }

    if (single >= 1 && single <= lastDay) setState(() => _selectedDay = single);
  }


  bool _globalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_typing) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_section == 'overview' && _bankId != Banks.geral.id) {
        _newTransaction(isIncome: false);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_section == 'overview' && _bankId != Banks.geral.id) {
        _newTransaction(isIncome: true);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.keyG) {
      _onSelectBank(Banks.geral.id);
      return true;
    }
    if (key == LogicalKeyboardKey.keyS) {
      _onSelectBank(Banks.sicoob.id);
      return true;
    }
    if (key == LogicalKeyboardKey.keyI) {
      _onSelectBank(Banks.itau.id);
      return true;
    }
    if (key == LogicalKeyboardKey.keyN) {
      _onSelectBank(Banks.nubank.id);
      return true;
    }
    if (key == LogicalKeyboardKey.keyV) {
      _onSelectBank(Banks.vr.id);
      return true;
    }

    final digits = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };

    final digit = digits[key];
    if (digit != null) {
      _typeDay(digit);
      return true;
    }

    return false;
  }
  bool get _typing {
    final focus = FocusManager.instance.primaryFocus;
    return focus?.context?.widget is EditableText ||
        focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
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

      if (transaction.restockProductId != null) {
        final product = _products.firstWhere((p) => p.id == transaction.restockProductId);
        await _fs!.restockProduct(product, qty, transaction.amount);
        return;
      }

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


  Future<void> _onSection(String id) async {
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
                          'year' => YearScreen(fs: _fs!, bankId: _bankId, header: _header()),
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
        'year' => 'Resumo do ano',
        'fixed' => 'Contas fixas',
        'fashion' => 'Vise Versa',
        _ => 'Visão geral',
      },
      showDayStrip: _section == 'overview',
      showBalances: _section != 'year',
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

    final dayBalance = income - expense;

    final dayMovement = dayTransactions
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

    final runningBalance = _budget.openingFor(_bankId) + untilYesterday + dayMovement;

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
    final movement = transactions.fold<double>(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
    final declared = _budget.closingFor(_bankId) - _budget.openingFor(_bankId);
    final divergence = (income - expense) - declared;
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

    final monthDays = DateTime(_month.year, _month.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = now.year == _month.year && now.month == _month.month;
    final totalDays = isCurrentMonth ? now.day : monthDays;

    final dailyIncome = List<double>.filled(totalDays, 0);
    final dailyExpense = List<double>.filled(totalDays, 0);
    final dailyNet = List<double>.filled(totalDays, 0);

    for (final t in transactions) {
      final i = t.date.day - 1;
      if (i < 0 || i >= totalDays) continue;
      if (!t.isTransfer) {
        if (t.isIncome) {
          dailyIncome[i] += t.amount;
        } else {
          dailyExpense[i] += t.amount;
        }
      }
      dailyNet[i] += t.isIncome ? t.amount : -t.amount;
    }

    final patrimony = <double>[];
    var running = _budget.openingFor(_bankId);
    for (var i = 0; i < totalDays; i++) {
      running += dailyNet[i];
      patrimony.add(running);
    }

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
          _card(
            title: 'Despesas por categoria',
            subtitle: monthLabel(_month),
            child: CategoryChart(spent: spentByCategory),
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Patrimônio ao longo do mês',
            subtitle: 'Saldo acumulado dia a dia',
            child: DailyChart(
              values: patrimony,
              color: AppColors.accent,
              showZeroLine: true,
              height: 220,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _card(
                  title: 'Entradas por dia',
                  subtitle: monthLabel(_month),
                  child: DailyChart(values: dailyIncome, color: AppColors.income),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _card(
                  title: 'Saídas por dia',
                  subtitle: monthLabel(_month),
                  child: DailyChart(values: dailyExpense, color: AppColors.expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Todos os lançamentos',
            subtitle: '${transactions.length} no mês, movimento de ${money(movement)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _showAllTransactions = !_showAllTransactions),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showAllTransactions ? Icons.expand_less : Icons.expand_more,
                          size: 17,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showAllTransactions ? 'Ocultar lançamentos' : 'Ver lançamentos',
                          style: AppTheme.ui(13, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showAllTransactions) ...[
                  const SizedBox(height: 16),
                  loading
                      ? _spinner()
                      : TransactionList(
                          transactions: transactions,
                          onDelete: (id) => _fs!.deleteTransaction(id),
                          emptyMessage: 'Nenhum lançamento neste mês',
                          showBank: _bankId == Banks.geral.id,
                        ),
                ],
              ],
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