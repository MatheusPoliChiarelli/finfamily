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

  int _categoryIndex = 0;
  bool _categoryMode = true;

  late Category _category;
  late String _bankId;
  String? _carId;
  String? _productId;
  String _costType = 'cautelar';
  String _pieceType = 'vestido';
  String? _incomeKind;
  String? _error;

  List<Category> get _options => [
        ...(widget.isIncome ? Categories.incomes : Categories.expenses),
        if (widget.bankId != Banks.geral.id)
          ...Categories.transfersFor(widget.bankId, widget.isIncome),
      ];

  bool get _isTransfer => Categories.isTransfer(_category.id);

  Color get _accent => widget.isIncome ? AppColors.income : AppColors.expense;

  bool get _isRobMotors => _category.id == 'robmotors';
  bool get _isViseVersa => _category.id == 'vise_versa';

  bool get _isCarExpense => !widget.isIncome && _isRobMotors;
  bool get _isCarIncome => widget.isIncome && _isRobMotors;
  bool get _isNewCar => _isCarExpense && _carId == _newId;
  bool get _isCarSale => _isCarIncome && _incomeKind == 'venda';

  bool get _isFashionExpense => !widget.isIncome && _isViseVersa;
  bool get _isFashionIncome => widget.isIncome && _isViseVersa;

  List<Product> get _availableProducts => widget.products.where((p) => !p.soldOut).toList();

  Product? get _selectedProduct =>
      _productId == null ? null : widget.products.where((p) => p.id == _productId).firstOrNull;

  bool get _needsFreeText {
    if (_isTransfer) return false;
    if (_isCarExpense) return !_isNewCar && _costType == 'outro';
    if (_isCarIncome || _isFashionExpense || _isFashionIncome) return false;
    return _category.id == 'outros' || _category.id == 'outras_receitas';
  }

  int get _qty => int.tryParse(_quantity.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _category = _options.first;
    _bankId = widget.bankId;
    _categoryIndex = 0;
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
    super.dispose();
  }

  void _moveCategory(int delta) {
    if (!_categoryMode) return;
    final next = (_categoryIndex + delta).clamp(0, _options.length - 1);
    setState(() {
      _categoryIndex = next;
      _category = _options[next];
      _carId = null;
      _productId = null;
      _incomeKind = null;
    });
  }

  void _confirmCategory() {
    setState(() => _categoryMode = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus());
  }

  void _onEnter() {
    if (_categoryMode) {
      _confirmCategory();
      return;
    }
    _save();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _onEnter();
      return;
    }
    if (!_categoryMode) return;

    if (key == LogicalKeyboardKey.arrowRight) _moveCategory(1);
    if (key == LogicalKeyboardKey.arrowLeft) _moveCategory(-1);
    if (key == LogicalKeyboardKey.arrowDown) _moveCategory(3);
    if (key == LogicalKeyboardKey.arrowUp) _moveCategory(-3);
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
      return 'Compra de $_qty ${_brand.text.trim()} ${_model.text.trim()}'.trim();
    }
    if (_isFashionIncome) {
      final p = _selectedProduct!;
      return 'Venda de $_qty ${p.name}';
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
    if (_isFashionIncome && _productId == null) {
      setState(() => _error = 'Escolha a peça vendida');
      return;
    }
    if ((_isFashionExpense || _isFashionIncome) && _qty <= 0) {
      setState(() => _error = 'Informe a quantidade');
      return;
    }
    if (_isFashionIncome && _qty > (_selectedProduct?.stock ?? 0)) {
      setState(() => _error = 'Só há ${_selectedProduct!.stock} em estoque');
      return;
    }
    if (_isFashionExpense && (_brand.text.trim().isEmpty || _model.text.trim().isEmpty)) {
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
        productId: _isFashionIncome ? _productId : null,
        quantity: _isFashionExpense || _isFashionIncome ? _qty : null,
        fashionBrand: _isFashionExpense ? _brand.text.trim() : null,
        fashionModel: _isFashionExpense ? _model.text.trim() : null,
        fashionType: _isFashionExpense ? _pieceType : null,
        isTransfer: _isTransfer,
        createdBy: user.uid,
        createdByName: user.displayName ?? 'Alguém',
      ),
    );
  }

  bool get _showAmount {
    if (_isFashionIncome) return _selectedProduct != null;
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
                Row(
                  children: [
                    Text('Categoria', style: AppTheme.ui(12, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    if (_categoryMode)
                      Text(
                        'setas para navegar, enter para confirmar',
                        style: AppTheme.ui(10, color: AppColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _grid(_options.map((c) => _categoryChip(c)).toList()),
                if (_isCarIncome) ...[
                  const SizedBox(height: 22),
                  Text('Tipo da entrada', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _radioTile('Comissão', Icons.handshake_outlined, _incomeKind == 'comissao', () {
                          setState(() {
                            _incomeKind = 'comissao';
                            _carId = null;
                          });
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _radioTile('Venda de carro', Icons.sell_outlined, _incomeKind == 'venda', () {
                          setState(() => _incomeKind = 'venda');
                        }),
                      ),
                    ],
                  ),
                ],
                if (_isCarSale) ...[
                  const SizedBox(height: 22),
                  Text('Carro vendido', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  if (widget.activeCars.isEmpty)
                    _emptyBox('Nenhum carro ativo no estoque')
                  else
                    ...widget.activeCars.map(_carOption),
                ],
                if (_isCarExpense) ...[
                  const SizedBox(height: 22),
                  Text('Carro', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  _newOption('Novo carro', _carId == _newId, () => setState(() => _carId = _newId)),
                  ...widget.activeCars.map(_carOption),
                ],
                if (_isNewCar) ...[
                  const SizedBox(height: 18),
                  Text('Dados do carro', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  _brandModelYear(),
                ],
                if (_isCarExpense && !_isNewCar && _carId != null) ...[
                  const SizedBox(height: 22),
                  Text('Tipo do custo', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  _grid(CarCostTypes.all
                      .where((t) => t.id != 'compra')
                      .map((t) => _costChip(t))
                      .toList()),
                ],
                if (_isFashionExpense) ...[
                  const SizedBox(height: 22),
                  Text('Dados da peça', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Tipo da peça', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  _grid(PieceTypes.all.map((t) => _pieceChip(t)).toList()),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Quantidade', style: AppTheme.ui(12, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _quantity,
                          style: AppTheme.uiMoney(15),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(hintText: '1'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_isFashionIncome) ...[
                  const SizedBox(height: 22),
                  Text('Peça vendida', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  if (_availableProducts.isEmpty)
                    _emptyBox('Nenhuma peça em estoque')
                  else
                    ..._availableProducts.map(_productOption),
                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Quantidade', style: AppTheme.ui(12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _quantity,
                            style: AppTheme.uiMoney(15),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(hintText: '1'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                if (_showAmount) ...[
                  const SizedBox(height: 22),
                  Text(_amountLabel, style: AppTheme.ui(12, color: AppColors.textMuted)),
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
                  if (_isFashionIncome && _qty > 0 && parseCurrency(_amount.text) > 0) ...[
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
                  Text('Descrição', style: AppTheme.ui(12, color: AppColors.textMuted)),
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
          Icon(Icons.add_circle_outline, size: 17, color: selected ? AppColors.accent : AppColors.textMuted),
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

  Widget _carOption(Car car) {
    final selected = _carId == car.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _tile(
        selected: selected,
        onTap: () => setState(() => _carId = car.id),
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
        onTap: () => setState(() => _productId = p.id),
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
      onTap: () => setState(() => _costType = t.id),
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
      onTap: () => setState(() => _pieceType = t.id),
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
        _categoryIndex = _options.indexWhere((o) => o.id == c.id);
        _categoryMode = false;
        _carId = null;
        _productId = null;
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