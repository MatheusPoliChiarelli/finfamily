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

  List<Category> get _options => [
        ...(widget.isIncome ? Categories.incomes : Categories.expenses),
        if (widget.bankId != Banks.geral.id)
          ...Categories.transfersFor(widget.bankId, widget.isIncome),
      ];

  bool get _isTransfer =>
      Categories.isTransfer(_category.id) ||
      _category.id == 'motoboy' ||
      _category.id == 'correios' ||
      _category.id == 'cartao_rosangela';

  bool get _fashionNoStock => _isFashionIncome && widget.bankId == Banks.itau.id;

  Color get _accent => widget.isIncome ? AppColors.income : AppColors.expense;

  bool get _isRobMotors => _category.id == 'robmotors';
  bool get _isViseVersa => _category.id == 'vise_versa';

  bool get _isCarExpense => !widget.isIncome && _isRobMotors;
  bool get _isCarIncome => widget.isIncome && _isRobMotors;
  bool get _isNewCar => _isCarExpense && _carId == _newId;
  bool get _isCarSale => _isCarIncome && _incomeKind == 'venda';

  bool get _isFashionExpense => !widget.isIncome && _isViseVersa;
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
    if (_isCarExpense) return !_isNewCar && _costType == 'outro';
    if (_isCarIncome || _isFashionExpense || _isFashionIncome) return false;
    return _category.id == 'outros' || _category.id == 'outras_receitas';
  }

  int get _qty => int.tryParse(_quantity.text) ?? 0;

  List<CarCostType> get _costTypes =>
      CarCostTypes.all.where((t) => t.id != 'compra').toList();

  List<String> get _stepFlow {
    if (_isFashionExpense) {
      return ['category', 'brand', 'model', if (!_isRestock) 'pieceType', 'quantity', 'amount'];
    }
    if (_isFashionIncome) {
      if (_fashionNoStock) return ['category', 'amount'];
      return _saleUndefined
          ? ['category', 'saleBrand', 'amount']
          : ['category', 'saleBrand', 'saleModel', 'quantity', 'amount'];
    }
    if (_isCarExpense) {
      return ['category', 'car', if (!_isNewCar && _carId != null) 'costType', 'amount'];
    }
    return ['category', 'amount'];
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

  void _move(int delta) {
    final length = _currentListLength;
    if (length == 0) return;
    setState(() {
      _listIndex = (_listIndex + delta).clamp(0, length - 1);
      _applyListIndex();
    });
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

    if (next == 'amount') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus());
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
      _step == 'saleBrand' || _step == 'saleModel';

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _nextStep();
      return;
    }
    if (_step == 'amount' || _step == 'quantity') return;

    final vertical = _gridStep ? 3 : 1;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _dialogFocus.requestFocus());
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
    super.dispose();
  }

  String _resolveDescription() {
    if (_isNewCar) return 'Compra do carro';
    if (_isCarExpense) {
      if (_costType == 'outro') return _description.text.trim();
      return CarCostTypes.byId(_costType).name;
    }
    if (_isCarIncome) {
      if (_incomeKind == 'comissao') return 'Comissão';
      final car = widget.activeCars.firstWhere((c) => c.id == _carId);
      return 'Venda do ${car.name}';
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
    if (_isCarIncome && _incomeKind == null) {
      setState(() => _error = 'Escolha o tipo da entrada');
      return;
    }
    if (_isCarSale && _carId == null) {
      setState(() => _error = 'Escolha o carro vendido');
      return;
    }
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
    if (_isCarExpense && _carId == null) {
      setState(() => _error = 'Escolha o carro');
      return;
    }
    if (_isNewCar && (_brand.text.trim().isEmpty || _model.text.trim().isEmpty)) {
      setState(() => _error = 'Informe marca e modelo');
      return;
    }

    final value = parseCurrency(_amount.text);
    if (value <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }

    if (_needsFreeText && _description.text.trim().isEmpty) {
      setState(() => _error = 'Informe a descrição');
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
        carId: (_isCarExpense && !_isNewCar) || _isCarSale ? _carId : null,
        carCostType: _isCarExpense && !_isNewCar ? _costType : null,
        isCarSale: _isCarSale,
        newCarBrand: _isNewCar ? _brand.text.trim() : null,
        newCarModel: _isNewCar ? _model.text.trim() : null,
        newCarYear: _isNewCar ? _year.text.trim() : null,
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
    if (!_isCarIncome) return true;
    if (_incomeKind == 'comissao') return true;
    if (_isCarSale && _carId != null) return true;
    return false;
  }

  String get _amountLabel {
    if (_isCarSale) return 'Valor da venda';
    if (_isFashionExpense) return 'Valor total pago';
    if (_isFashionIncome) return 'Valor total recebido';
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
      case 'quantity':
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
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _headerRow(),
                const SizedBox(height: 24),
                _label('Categoria', active: _step == 'category'),
                const SizedBox(height: 10),
                _grid(_options.map((c) => _categoryChip(c)).toList()),
                if (_isCarIncome) ...[
                  const SizedBox(height: 22),
                  _label('Tipo da entrada'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _radioTile('Comissão', Icons.handshake_outlined,
                            _incomeKind == 'comissao', () {
                          setState(() {
                            _incomeKind = 'comissao';
                            _carId = null;
                          });
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _radioTile('Venda de carro', Icons.sell_outlined,
                            _incomeKind == 'venda', () {
                          setState(() => _incomeKind = 'venda');
                        }),
                      ),
                    ],
                  ),
                ],
                if (_isCarSale) ...[
                  const SizedBox(height: 22),
                  _label('Carro vendido'),
                  const SizedBox(height: 10),
                  if (widget.activeCars.isEmpty)
                    _emptyBox('Nenhum carro ativo no estoque')
                  else
                    ...widget.activeCars.map(_carOption),
                ],
                if (_isCarExpense) ...[
                  const SizedBox(height: 22),
                  _label('Carro', active: _step == 'car'),
                  const SizedBox(height: 10),
                  _newOption('Novo carro', _carId == _newId, () => setState(() => _carId = _newId)),
                  ...widget.activeCars.map(_carOption),
                ],
                if (_isNewCar) ...[
                  const SizedBox(height: 18),
                  _label('Dados do carro'),
                  const SizedBox(height: 10),
                  _brandModelYear(),
                ],
                if (_isCarExpense && !_isNewCar && _carId != null) ...[
                  const SizedBox(height: 22),
                  _label('Tipo do custo', active: _step == 'costType'),
                  const SizedBox(height: 10),
                  _grid(_costTypes.map((t) => _costChip(t)).toList()),
                ],
                if (_isFashionExpense) ...[
                  const SizedBox(height: 22),
                  _label('Marca', active: _step == 'brand'),
                  const SizedBox(height: 10),
                  _grid([
                    _choiceChip('Outra marca', _brandChoice == _newId, Icons.add_circle_outline, () {
                      setState(() {
                        _brandChoice = _newId;
                        _modelChoice = null;
                        _step = 'brand';
                        _listIndex = 0;
                      });
                    }),
                    ..._existingBrands.map(
                      (b) => _choiceChip(b, _brandChoice == b, Icons.label_outline, () {
                        setState(() {
                          _brandChoice = b;
                          _modelChoice = null;
                          _step = 'brand';
                          _listIndex = _existingBrands.indexOf(b) + 1;
                        });
                      }),
                    ),
                  ]),
                  if (_isNewBrand) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _brand,
                      style: AppTheme.ui(14),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Nome da marca'),
                    ),
                  ],
                  if (_brandChoice != null) ...[
                    const SizedBox(height: 20),
                    _label('Modelo', active: _step == 'model'),
                    const SizedBox(height: 10),
                    _grid([
                      _choiceChip('Outro modelo', _modelChoice == _newId, Icons.add_circle_outline, () {
                        setState(() {
                          _modelChoice = _newId;
                          _step = 'model';
                          _listIndex = 0;
                        });
                      }),
                      ..._modelsOfBrand.map(
                        (m) => _choiceChip(m, _modelChoice == m, Icons.style_outlined, () {
                          setState(() {
                            _modelChoice = m;
                            _step = 'model';
                            _listIndex = _modelsOfBrand.indexOf(m) + 1;
                          });
                        }),
                      ),
                    ]),
                    if (_isNewModel) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _model,
                        style: AppTheme.ui(14),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: 'Nome do modelo'),
                      ),
                    ],
                  ],
                  if (_isRestock) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Peça já existe, será somada ao card atual',
                              style: AppTheme.ui(12, color: AppColors.accent),
                            ),
                          ),
                          Text(
                            '${_matchedProduct!.quantity} compradas',
                            style: AppTheme.uiMoney(11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!_isRestock && _brandChoice != null && _modelChoice != null) ...[
                    const SizedBox(height: 20),
                    _label('Tipo da peça', active: _step == 'pieceType'),
                    const SizedBox(height: 10),
                    _grid(PieceTypes.all.map((t) => _pieceChip(t)).toList()),
                  ],
                  const SizedBox(height: 18),
                  _quantityField(),
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
                if (_fashionNoStock) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 15, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Recebimento de cartão, sem baixa no estoque',
                            style: AppTheme.ui(12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
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
                if (_needsFreeText) ...[
                  const SizedBox(height: 22),
                  _label('Descrição'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    style: AppTheme.ui(14),
                    onSubmitted: (_) => _save(),
                    decoration: const InputDecoration(hintText: 'Do que se trata'),
                  ),
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
            widget.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
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

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
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
          _step = 'car';
          _listIndex = widget.activeCars.indexWhere((o) => o.id == car.id) + 1;
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
        _incomeKind = null;
      }),
      children: [
        _radio(selected),
        const SizedBox(width: 7),
        Icon(c.icon, size: 14, color: Color(c.color)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            c.name,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(12, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}