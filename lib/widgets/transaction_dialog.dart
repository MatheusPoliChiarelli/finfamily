import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/banks.dart';
import '../data/car_costs.dart';
import '../data/categories.dart';
import '../data/fashion.dart';
import '../models/app_transaction.dart';
import '../models/car.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

const _newId = '__new__';
const _undefinedId = '__undefined__';

Future<AppTransaction?> showTransactionDialog(
  BuildContext context,
  DateTime date, {
  required bool isIncome,
  required String bankId,
  required List<Car> activeCars,
  required List<Product> products,
}) {
  return showDialog<AppTransaction>(
    context: context,
    builder: (_) => _TransactionDialog(
      date: date,
      isIncome: isIncome,
      bankId: bankId,
      activeCars: activeCars,
      products: products,
    ),
  );
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({
    required this.date,
    required this.isIncome,
    required this.bankId,
    required this.activeCars,
    required this.products,
  });

  final DateTime date;
  final bool isIncome;
  final String bankId;
  final List<Car> activeCars;
  final List<Product> products;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _quantity = TextEditingController(text: '1');

  final _amountFocus = FocusNode();
  final _dialogFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();
  final _gridKey = GlobalKey();

  String _step = 'category';
  int _listIndex = 0;

  late Category _category;
  late String _bankId;
  String? _carId;
  String? _productId;
  String? _brandChoice;
  String? _modelChoice;
  String _costType = 'cautelar';
  String _pieceType = 'vestido';
  String? _incomeKind;
  String? _error;

  List<Category> get _allOptions {
    if (widget.isIncome && widget.bankId == Banks.vr.id) {
      return Categories.incomes.where((c) => c.id == 'vale_alimentacao').toList();
    }

    final base = widget.isIncome ? Categories.incomes : Categories.expenses;
    final others = base.where((c) => c.id != 'outros' && c.id != 'outras_receitas').toList();
    final outros = base.where((c) => c.id == 'outros' || c.id == 'outras_receitas').toList();

    return [
      ...others,
      if (widget.bankId != Banks.geral.id)
        ...Categories.transfersFor(widget.bankId, widget.isIncome),
      ...outros,
    ];
  }

  List<Category> get _options {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _allOptions;
    return _allOptions.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  bool get _isTransfer =>
      Categories.isTransfer(_category.id) ||
      _category.id == 'motoboy' ||
      _category.id == 'correios' ||
      _category.id == 'cartao_rosangela' ||
      _category.id == 'reembolso';

  bool get _fashionNoStock => _isFashionIncome;

  Color get _accent => widget.isIncome ? AppColors.income : AppColors.expense;

  bool get _isRobMotors => _category.id == 'robmotors';
  bool get _isCarCost => !widget.isIncome && _category.id == 'custo_carro';
  bool get _isViseVersa => _category.id == 'vise_versa';

  bool get _isCarExpense => false;
  bool get _isNewCarPurchase => !widget.isIncome && _isRobMotors;
  bool get _isCarIncome => widget.isIncome && _isRobMotors;
  bool get _isNewCar => _isCarExpense && _carId == _newId;
  bool get _isCarSale => false;

  bool get _isFashionExpense => false;
  bool get _isFashionIncome => widget.isIncome && _isViseVersa;
  bool get _isUndefinedPiece => _isFashionIncome && _saleUndefined;

  List<String> get _saleBrands {
    final set = <String>{};
    for (final p in _availableProducts) {
      if (p.brand.trim().isNotEmpty) set.add(p.brand.trim());
    }
    return set.toList()..sort();
  }

  List<Product> get _saleModelsOfBrand {
    if (_brandChoice == null || _brandChoice == _undefinedId) return [];
    return _availableProducts.where((p) => p.brand.trim() == _brandChoice).toList()
      ..sort((a, b) => a.model.compareTo(b.model));
  }

  bool get _saleUndefined => _isFashionIncome && _brandChoice == _undefinedId;

  List<String> get _existingBrands {
    final set = <String>{};
    for (final p in widget.products) {
      if (p.brand.trim().isNotEmpty) set.add(p.brand.trim());
    }
    return set.toList()..sort();
  }

  List<String> get _modelsOfBrand {
    if (_brandChoice == null || _brandChoice == _newId) return [];
    final set = <String>{};
    for (final p in widget.products) {
      if (p.brand.trim() == _brandChoice && p.model.trim().isNotEmpty) {
        set.add(p.model.trim());
      }
    }
    return set.toList()..sort();
  }

  bool get _isNewBrand => _brandChoice == _newId;
  bool get _isNewModel => _modelChoice == _newId;

  String get _finalBrand => _isNewBrand ? _brand.text.trim() : (_brandChoice ?? '');
  String get _finalModel => _isNewModel ? _model.text.trim() : (_modelChoice ?? '');

  Product? get _matchedProduct {
    if (_finalBrand.isEmpty || _finalModel.isEmpty) return null;
    return widget.products
        .where((p) => p.brand.trim() == _finalBrand && p.model.trim() == _finalModel)
        .firstOrNull;
  }

  bool get _isRestock => _isFashionExpense && _matchedProduct != null;

  List<Product> get _availableProducts => widget.products.where((p) => !p.soldOut).toList();

  Product? get _selectedProduct => (_productId == null || _productId == _undefinedId)
      ? null
      : widget.products.where((p) => p.id == _productId).firstOrNull;

  bool get _needsFreeText {
    if (_isTransfer) return false;
    if (_isCarCost) return false;
    if (_isNewCarPurchase) return false;
    if (_isCarIncome || _isFashionExpense || _isFashionIncome) return false;
    return _category.id == 'outros' || _category.id == 'outras_receitas';
  }

  int get _qty => int.tryParse(_quantity.text) ?? 0;

  List<CarCostType> get _costTypes =>
      CarCostTypes.all.where((t) => t.id != 'compra').toList();

  List<String> get _stepFlow {
    if (_isFashionIncome) {
      if (_fashionNoStock) return ['category', 'amount'];
      return _saleUndefined
          ? ['category', 'saleBrand', 'amount']
          : ['category', 'saleBrand', 'saleModel', 'quantity', 'amount'];
    }
    if (_isCarCost) {
      return ['category', 'costType', 'amount', 'carPick'];
    }
    if (_isNewCarPurchase) {
      return ['category', 'amount'];
    }
    return ['category', if (_needsFreeText) 'description', 'amount'];
  }

  int get _currentListLength {
    switch (_step) {
      case 'category':
        return _options.length;
      case 'brand':
        return _existingBrands.length + 1;
      case 'model':
        return _modelsOfBrand.length + 1;
      case 'pieceType':
        return PieceTypes.all.length;
      case 'product':
        return _availableProducts.length + 1;
      case 'car':
        return widget.activeCars.length + 1;
      case 'costType':
        return _costTypes.length;
      case 'carPick':
        return widget.activeCars.length;
      case 'saleBrand':
        return _saleBrands.length + 1;
      case 'saleModel':
        return _saleModelsOfBrand.length;
      default:
        return 0;
    }
  }

  void _applyListIndex() {
    switch (_step) {
      case 'category':
        _category = _options[_listIndex];
        _carId = null;
        _productId = null;
        _brandChoice = null;
        _modelChoice = null;
        _incomeKind = null;
        break;
      case 'brand':
        _brandChoice = _listIndex == 0 ? _newId : _existingBrands[_listIndex - 1];
        _modelChoice = null;
        break;
      case 'model':
        _modelChoice = _listIndex == 0 ? _newId : _modelsOfBrand[_listIndex - 1];
        break;
      case 'pieceType':
        _pieceType = PieceTypes.all[_listIndex].id;
        break;
      case 'product':
        _productId = _listIndex == 0 ? _undefinedId : _availableProducts[_listIndex - 1].id;
        break;
      case 'car':
        _carId = _listIndex == 0 ? _newId : widget.activeCars[_listIndex - 1].id;
        break;
      case 'costType':
        _costType = _costTypes[_listIndex].id;
        break;
      case 'carPick':
        if (widget.activeCars.isNotEmpty) {
          _carId = widget.activeCars[_listIndex].id;
        }
        break;
      case 'saleBrand':
        _brandChoice = _listIndex == 0 ? _undefinedId : _saleBrands[_listIndex - 1];
        _productId = null;
        break;
      case 'saleModel':
        if (_saleModelsOfBrand.isNotEmpty) {
          _productId = _saleModelsOfBrand[_listIndex].id;
        }
        break;
    }
  }


  void _scrollToSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;

      const columns = 3;
      final rows = (_currentListLength / columns).ceil();
      if (rows == 0) return;

      final rowHeight = box.size.height / rows;
      final currentRow = _listIndex ~/ columns;
      final gridTop = box.localToGlobal(Offset.zero).dy;
      final target = _scroll.offset + gridTop + (currentRow * rowHeight) - 220;

      _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _move(int delta) {
    final length = _currentListLength;
    if (length == 0) return;
    setState(() {
      _listIndex = (_listIndex + delta).clamp(0, length - 1);
      _applyListIndex();
    });
    _scrollToSelection();
  }

  void _nextStep() {
    if (_currentListLength > 0) _applyListIndex();

    final flow = _stepFlow;
    final current = flow.indexOf(_step);

    if (current == -1 || current >= flow.length - 1) {
      _save();
      return;
    }

    final next = flow[current + 1];

    setState(() {
      _step = next;
      _listIndex = 0;
      if (next != 'amount') _applyListIndex();
    });

    if (_step != 'category') _search.clear();

    if (next == 'costType' || next == 'carPick') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    } else if (next == 'amount') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus());
    } else if (next == 'description') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _descriptionFocus.requestFocus());
    } else if (next == 'quantity') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _quantityFocus.requestFocus();
        _quantity.selection = TextSelection(baseOffset: 0, extentOffset: _quantity.text.length);
      });
    }
  }


  bool get _gridStep =>
      _step == 'category' || _step == 'pieceType' || _step == 'costType' ||
      _step == 'brand' || _step == 'model' ||
      _step == 'saleBrand' || _step == 'saleModel' || _step == 'carPick';

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_searchFocus.hasFocus) return;
      _nextStep();
      return;
    }
    if (_step == 'amount' || _step == 'quantity' || _step == 'description') return;

    final vertical = _gridStep ? 3 : 1;

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      _dialogFocus.requestFocus();
    }
    if (key == LogicalKeyboardKey.arrowRight) _move(1);
    if (key == LogicalKeyboardKey.arrowLeft) _move(-1);
    if (key == LogicalKeyboardKey.arrowDown) _move(vertical);
    if (key == LogicalKeyboardKey.arrowUp) _move(-vertical);
  }

  @override
  void initState() {
    super.initState();
    _category = _options.first;
    _bankId = widget.bankId;
    _listIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _quantity.dispose();
    _amountFocus.dispose();
    _dialogFocus.dispose();
    _quantityFocus.dispose();
    _descriptionFocus.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _resolveDescription() {
    if (_isNewCarPurchase) {
      return 'Compra de ${_brand.text.trim()} ${_model.text.trim()}'.trim();
    }
    if (_isCarCost) {
      if (_costType == 'outro') return _description.text.trim();
      return CarCostTypes.byId(_costType).name;
    }
    if (_isFashionExpense) {
      return 'Compra de $_qty $_finalBrand $_finalModel'.trim();
    }
    if (_isFashionIncome) {
      if (_fashionNoStock || _isUndefinedPiece) return 'Venda Vise Versa';
      return 'Venda de $_qty ${_selectedProduct!.name}';
    }
    final typed = _description.text.trim();
    return typed.isEmpty ? _category.name : typed;
  }

  void _save() {
    if (_isFashionIncome && !_fashionNoStock && _productId == null) {
      setState(() => _error = 'Escolha a peça vendida');
      return;
    }
    if ((_isFashionExpense || (_isFashionIncome && !_fashionNoStock && !_isUndefinedPiece)) && _qty <= 0) {
      setState(() => _error = 'Informe a quantidade');
      return;
    }
    if (_isFashionIncome &&
        !_fashionNoStock &&
        !_isUndefinedPiece &&
        _qty > (_selectedProduct?.stock ?? 0)) {
      setState(() => _error = 'Só há ${_selectedProduct!.stock} em estoque');
      return;
    }
    if (_isFashionExpense && (_finalBrand.isEmpty || _finalModel.isEmpty)) {
      setState(() => _error = 'Informe marca e modelo');
      return;
    }
    if (_isCarCost && _carId == null) {
      setState(() => _error = 'Escolha o carro');
      return;
    }
    if (_isNewCarPurchase && (_brand.text.trim().isEmpty || _model.text.trim().isEmpty)) {
      setState(() => _error = 'Informe marca e modelo');
      return;
    }

    final value = parseCurrency(_amount.text);
    if (value <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;

    Navigator.of(context).pop(
      AppTransaction(
        id: '',
        amount: value,
        isIncome: widget.isIncome,
        date: widget.date,
        description: _resolveDescription(),
        categoryId: _category.id,
        categoryName: _category.name,
        categoryColor: _category.color,
        bankId: _bankId,
        carId: _isCarCost ? _carId : null,
        carCostType: _isCarCost ? _costType : null,
        isCarSale: _isCarSale,
        newCarBrand: _isNewCarPurchase ? _brand.text.trim() : null,
        newCarModel: _isNewCarPurchase ? _model.text.trim() : null,
        newCarYear: _isNewCarPurchase ? _year.text.trim() : null,
        fashionKind: _isFashionExpense ? 'compra' : (_isFashionIncome ? 'venda' : null),
        productId: _isFashionIncome && !_fashionNoStock && !_isUndefinedPiece ? _productId : null,
        quantity: _isFashionExpense || (_isFashionIncome && !_fashionNoStock && !_isUndefinedPiece) ? _qty : null,
        fashionBrand: _isFashionExpense && !_isRestock ? _finalBrand : null,
        fashionModel: _isFashionExpense && !_isRestock ? _finalModel : null,
        fashionType: _isFashionExpense && !_isRestock ? _pieceType : null,
        restockProductId: _isRestock ? _matchedProduct!.id : null,
        isTransferFlag: _isTransfer,
        createdBy: user.uid,
        createdByName: user.displayName ?? 'Alguém',
      ),
    );
  }

  bool get _showAmount {
    if (_isFashionIncome) {
      return _fashionNoStock || _saleUndefined || _selectedProduct != null;
    }
    return true;
  }

  String get _amountLabel {
    if (_isFashionExpense) return 'Valor total pago';
    return 'Valor';
  }

  String get _stepHint {
    switch (_step) {
      case 'category':
        return 'setas navegam, enter avança';
      case 'brand':
        return 'escolha a marca, enter avança';
      case 'model':
        return 'escolha o modelo, enter avança';
      case 'pieceType':
        return 'escolha o tipo, enter avança';
      case 'product':
        return 'escolha a peça vendida, enter avança';
      case 'car':
        return 'escolha o carro, enter avança';
      case 'costType':
        return 'escolha o tipo do custo, enter avança';
      case 'carPick':
        return 'escolha o carro, enter salva';
      case 'quantity':
        return 'digite e enter avança';
      case 'description':
        return 'digite e enter avança';
      case 'saleBrand':
        return 'escolha a marca, enter avança';
      case 'saleModel':
        return 'escolha o modelo, enter avança';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
        child: KeyboardListener(
          focusNode: _dialogFocus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _headerRow(),
                const SizedBox(height: 24),
                TextField(
                  controller: _search,
                  focusNode: _searchFocus,
                  style: AppTheme.ui(14),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {
                    _listIndex = 0;
                    if (_options.isNotEmpty) _category = _options.first;
                  }),
                  onSubmitted: (_) {
                    if (_options.isEmpty) return;
                    _searchFocus.unfocus();
                    _nextStep();
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar categoria',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Icon(Icons.search, size: 17, color: AppColors.textMuted),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 12),
                _grid(_options.map((c) => _categoryChip(c)).toList(), key: _gridKey),
                if (_isNewCarPurchase) ...[
                  const SizedBox(height: 22),
                  _label('Dados do carro'),
                  const SizedBox(height: 10),
                  _brandModelYear(),
                ],
                if (_isCarCost) ...[
                  const SizedBox(height: 22),
                  _label('Tipo do custo', active: _step == 'costType'),
                  const SizedBox(height: 10),
                  _grid(_costTypes.map((t) => _costChip(t)).toList()),
                  if (_costType == 'outro') ...[
                    const SizedBox(height: 18),
                    _label('Descrição'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _description,
                      style: AppTheme.ui(14),
                      decoration: const InputDecoration(hintText: 'Do que se trata'),
                    ),
                  ],
                ],
                if (_isFashionIncome && !_fashionNoStock) ...[
                  const SizedBox(height: 22),
                  _label('Marca', active: _step == 'saleBrand'),
                  const SizedBox(height: 10),
                  _grid([
                    _choiceChip('Peça indefinida', _brandChoice == _undefinedId, Icons.help_outline, () {
                      setState(() {
                        _brandChoice = _undefinedId;
                        _productId = null;
                        _step = 'saleBrand';
                        _listIndex = 0;
                      });
                    }),
                    ..._saleBrands.map(
                      (b) => _choiceChip(b, _brandChoice == b, Icons.label_outline, () {
                        setState(() {
                          _brandChoice = b;
                          _productId = null;
                          _step = 'saleBrand';
                          _listIndex = _saleBrands.indexOf(b) + 1;
                        });
                      }),
                    ),
                  ]),
                  if (_brandChoice != null && !_saleUndefined) ...[
                    const SizedBox(height: 20),
                    _label('Modelo', active: _step == 'saleModel'),
                    const SizedBox(height: 10),
                    if (_saleModelsOfBrand.isEmpty)
                      _emptyBox('Nenhuma peça dessa marca em estoque')
                    else
                      ..._saleModelsOfBrand.map(_productOption),
                  ],
                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 18),
                    _quantityField(),
                  ],
                ],
                if (_needsFreeText) ...[
                  const SizedBox(height: 22),
                  _label('Descrição', active: _step == 'description'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    focusNode: _descriptionFocus,
                    style: AppTheme.ui(14),
                    onSubmitted: (_) => _nextStep(),
                    decoration: const InputDecoration(hintText: 'Do que se trata'),
                  ),
                ],
                if (_showAmount) ...[
                  const SizedBox(height: 22),
                  _label(_amountLabel, active: _step == 'amount'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amount,
                    focusNode: _amountFocus,
                    style: AppTheme.uiMoney(15),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    decoration: _moneyInput(),
                  ),
                  if (_isFashionExpense && _qty > 0 && parseCurrency(_amount.text) > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Custo por peça', style: AppTheme.ui(12, color: AppColors.textMuted)),
                        const SizedBox(width: 10),
                        Text(
                          money(parseCurrency(_amount.text) / _qty),
                          style: AppTheme.uiMoney(13, color: AppColors.accent, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                  if (_isFashionIncome &&
                      _selectedProduct != null &&
                      _qty > 0 &&
                      parseCurrency(_amount.text) > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Lucro da venda', style: AppTheme.ui(12, color: AppColors.textMuted)),
                        const SizedBox(width: 10),
                        Text(
                          money(parseCurrency(_amount.text) - (_selectedProduct!.unitCost * _qty)),
                          style: AppTheme.uiMoney(13, color: AppColors.income, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
                if (_isCarCost) ...[
                  const SizedBox(height: 22),
                  _label('Carro', active: _step == 'carPick'),
                  const SizedBox(height: 10),
                  if (widget.activeCars.isEmpty)
                    _emptyBox('Nenhum carro ativo no estoque')
                  else
                    ...widget.activeCars.map(_carOption),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: AppTheme.ui(13, color: AppColors.expense)),
                ],
                const SizedBox(height: 26),
                FilledButton(onPressed: _save, child: const Text('Salvar')),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: AppTheme.ui(13, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool active = false}) {
    return Row(
      children: [
        Text(text, style: AppTheme.ui(12, color: active ? AppColors.accent : AppColors.textMuted)),
        if (active && _stepHint.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(_stepHint, style: AppTheme.ui(10, color: AppColors.accent)),
        ],
      ],
    );
  }

  Widget _quantityField() {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Quantidade', active: _step == 'quantity'),
          const SizedBox(height: 8),
          TextField(
            controller: _quantity,
            focusNode: _quantityFocus,
            style: AppTheme.uiMoney(15),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _nextStep(),
            decoration: const InputDecoration(hintText: '1'),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Icon(
            widget.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            size: 17,
            color: _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.isIncome ? 'Nova entrada' : 'Nova saída', style: AppTheme.display(24)),
              const SizedBox(height: 2),
              Text(
                '${fullDayLabel(widget.date)} · ${Banks.byId(widget.bankId).name}',
                style: AppTheme.ui(12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _brandModelYear() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _brand,
              style: AppTheme.ui(14),
              decoration: const InputDecoration(hintText: 'Marca'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _model,
              style: AppTheme.ui(14),
              decoration: const InputDecoration(hintText: 'Modelo'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _year,
              style: AppTheme.uiMoney(14),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: const InputDecoration(hintText: 'Ano'),
            ),
          ),
        ],
      );

  InputDecoration _moneyInput() => InputDecoration(
        hintText: '0,00',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text('R\$', style: AppTheme.uiMoney(15, color: AppColors.textSecondary)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      );

  Widget _grid(List<Widget> children, {Key? key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        const columns = 3;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((c) => SizedBox(width: width, child: c)).toList(),
        );
      },
    );
  }

  Widget _emptyBox(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: AppTheme.ui(12, color: AppColors.textMuted)),
      );

  Widget _radio(bool selected) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.textMuted,
            width: 1.2,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                ),
              )
            : null,
      );

  Widget _tile({
    required bool selected,
    required VoidCallback onTap,
    required List<Widget> children,
    double height = 42,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(children: children),
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, IconData icon, VoidCallback onTap) {
    return _tile(
      selected: selected,
      onTap: onTap,
      children: [
        _radio(selected),
        const SizedBox(width: 7),
        Icon(icon, size: 14, color: selected ? AppColors.accent : AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(12, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _radioTile(String label, IconData icon, bool selected, VoidCallback onTap) {
    return _tile(
      selected: selected,
      onTap: onTap,
      height: 46,
      children: [
        _radio(selected),
        const SizedBox(width: 9),
        Icon(icon, size: 15, color: selected ? AppColors.accent : AppColors.textMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(13, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _newOption(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _tile(
        selected: selected,
        onTap: onTap,
        height: 46,
        children: [
          Icon(Icons.add_circle_outline, size: 17,
              color: selected ? AppColors.accent : AppColors.textMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTheme.ui(
              13,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _undefinedPieceOption() {
    final selected = _productId == _undefinedId;
    return _tile(
      selected: selected,
      onTap: () => setState(() {
        _productId = _undefinedId;
        _step = 'product';
        _listIndex = 0;
      }),
      height: 46,
      children: [
        _radio(selected),
        const SizedBox(width: 10),
        Icon(Icons.help_outline, size: 15,
            color: selected ? AppColors.accent : AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Peça indefinida',
            style: AppTheme.ui(13, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
        Text('sem baixa no estoque', style: AppTheme.ui(10, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _carOption(Car car) {
    final selected = _carId == car.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _tile(
        selected: selected,
        onTap: () => setState(() {
          _carId = car.id;
          _step = 'carPick';
          _listIndex = widget.activeCars.indexWhere((o) => o.id == car.id);
        }),
        height: 46,
        children: [
          _radio(selected),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              car.year.isEmpty ? car.name : '${car.name} ${car.year}',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.ui(13, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
          Text(money(car.totalInvested), style: AppTheme.uiMoney(11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _productOption(Product p) {
    final selected = _productId == p.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _tile(
        selected: selected,
        onTap: () => setState(() {
          _productId = p.id;
          _step = 'product';
          _listIndex = _availableProducts.indexWhere((o) => o.id == p.id) + 1;
        }),
        height: 50,
        children: [
          _radio(selected),
          const SizedBox(width: 10),
          Icon(PieceTypes.byId(p.type).icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(13, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
                ),
                Text(
                  '${p.stock} em estoque · custo ${money(p.unitCost)}',
                  style: AppTheme.ui(10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _costChip(CarCostType t) {
    final selected = _costType == t.id;
    return _tile(
      selected: selected,
      onTap: () => setState(() {
        _costType = t.id;
        _step = 'costType';
        _listIndex = _costTypes.indexWhere((o) => o.id == t.id);
      }),
      children: [
        _radio(selected),
        const SizedBox(width: 7),
        Icon(t.icon, size: 14, color: selected ? AppColors.accent : AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            t.name,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(12, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _pieceChip(PieceType t) {
    final selected = _pieceType == t.id;
    return _tile(
      selected: selected,
      onTap: () => setState(() {
        _pieceType = t.id;
        _step = 'pieceType';
        _listIndex = PieceTypes.all.indexWhere((o) => o.id == t.id);
      }),
      children: [
        _radio(selected),
        const SizedBox(width: 7),
        Icon(t.icon, size: 14, color: selected ? AppColors.accent : AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            t.name,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(12, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(Category c) {
    final selected = _category.id == c.id;
    return _tile(
      selected: selected,
      onTap: () => setState(() {
        _category = c;
        _listIndex = _options.indexWhere((o) => o.id == c.id);
        _step = 'category';
        _carId = null;
        _productId = null;
        _brandChoice = null;
        _modelChoice = null;
      }),
      children: [
        _radio(selected),
        const SizedBox(width: 7),
        Icon(c.icon, size: 14, color: Color(c.color)),
        const SizedBox(width: 6),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              c.name,
              maxLines: 1,
              style: AppTheme.ui(12, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}