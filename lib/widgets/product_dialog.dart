import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/fashion.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

Future<Product?> showProductDialog(BuildContext context) =>
    showDialog<Product>(context: context, builder: (_) => const _ProductDialog());

Future<(int, double)?> showSellPieceDialog(BuildContext context, Product product) =>
    showDialog<(int, double)>(context: context, builder: (_) => _SellPieceDialog(product: product));

InputDecoration _moneyInput() => InputDecoration(
      hintText: '0,00',
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Text('R\$', style: AppTheme.uiMoney(15, color: AppColors.textSecondary)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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

class _ProductDialog extends StatefulWidget {
  const _ProductDialog();

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _total = TextEditingController();
  final _quantity = TextEditingController(text: '1');

  final _dialogFocus = FocusNode();
  final _brandFocus = FocusNode();

  int _typeIndex = 0;
  bool _typeMode = true;

  DateTime _date = DateTime.now();
  String _type = 'vestido';
  String? _error;

  int get _qty => int.tryParse(_quantity.text) ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _dialogFocus.requestFocus());
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _total.dispose();
    _quantity.dispose();
    _dialogFocus.dispose();
    _brandFocus.dispose();
    super.dispose();
  }

  void _moveType(int delta) {
    if (!_typeMode) return;
    final next = (_typeIndex + delta).clamp(0, PieceTypes.all.length - 1);
    setState(() {
      _typeIndex = next;
      _type = PieceTypes.all[next].id;
    });
  }

  void _confirmType() {
    setState(() => _typeMode = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _brandFocus.requestFocus());
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_typeMode) {
        _confirmType();
        return;
      }
      _save();
      return;
    }
    if (!_typeMode) return;

    if (key == LogicalKeyboardKey.arrowRight) _moveType(1);
    if (key == LogicalKeyboardKey.arrowLeft) _moveType(-1);
    if (key == LogicalKeyboardKey.arrowDown) _moveType(3);
    if (key == LogicalKeyboardKey.arrowUp) _moveType(-3);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final total = parseCurrency(_total.text);

    if (_brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      setState(() => _error = 'Informe marca e modelo');
      return;
    }
    if (_qty <= 0) {
      setState(() => _error = 'Informe a quantidade');
      return;
    }
    if (total <= 0) {
      setState(() => _error = 'Informe o valor total pago');
      return;
    }

    Navigator.of(context).pop(
      Product(
        id: '',
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        type: _type,
        purchaseDate: _date,
        unitCost: total / _qty,
        quantity: _qty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = parseCurrency(_total.text);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
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
                Text('Nova peça', style: AppTheme.display(24)),
                const SizedBox(height: 4),
                Text('Entra no estoque da Vise Versa', style: AppTheme.ui(12, color: AppColors.textMuted)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text('Tipo da peça', style: AppTheme.ui(12, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    if (_typeMode)
                      Text(
                        'setas para navegar, enter para confirmar',
                        style: AppTheme.ui(10, color: AppColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const columns = 3;
                    const gap = 8.0;
                    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: PieceTypes.all
                          .map((t) => SizedBox(width: width, child: _typeChip(t)))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text('Dados da peça', style: AppTheme.ui(12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _brand,
                        focusNode: _brandFocus,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Valor total pago', style: AppTheme.ui(12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _total,
                            style: AppTheme.uiMoney(15),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [CurrencyInputFormatter()],
                            onChanged: (_) => setState(() {}),
                            decoration: _moneyInput(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_qty > 0 && total > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Custo por peça', style: AppTheme.ui(12, color: AppColors.textMuted)),
                      const SizedBox(width: 10),
                      Text(
                        money(total / _qty),
                        style: AppTheme.uiMoney(13, color: AppColors.accent, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Text('Data da compra', style: AppTheme.ui(12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(dayLabel(_date), style: AppTheme.ui(14)),
                      ],
                    ),
                  ),
                ),
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

  Widget _typeChip(PieceType t) {
    final selected = _type == t.id;
    return InkWell(
      onTap: () => setState(() {
        _type = t.id;
        _typeIndex = PieceTypes.all.indexWhere((o) => o.id == t.id);
        _typeMode = false;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
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
        ),
      ),
    );
  }
}

class _SellPieceDialog extends StatefulWidget {
  const _SellPieceDialog({required this.product});

  final Product product;

  @override
  State<_SellPieceDialog> createState() => _SellPieceDialogState();
}

class _SellPieceDialogState extends State<_SellPieceDialog> {
  final _quantity = TextEditingController(text: '1');
  final _total = TextEditingController();
  String? _error;

  int get _qty => int.tryParse(_quantity.text) ?? 0;

  @override
  void dispose() {
    _quantity.dispose();
    _total.dispose();
    super.dispose();
  }

  void _save() {
    final total = parseCurrency(_total.text);

    if (_qty <= 0) {
      setState(() => _error = 'Informe a quantidade');
      return;
    }
    if (_qty > widget.product.stock) {
      setState(() => _error = 'Só há ${widget.product.stock} em estoque');
      return;
    }
    if (total <= 0) {
      setState(() => _error = 'Informe o valor da venda');
      return;
    }

    Navigator.of(context).pop((_qty, total));
  }

  @override
  Widget build(BuildContext context) {
    final total = parseCurrency(_total.text);
    final cost = widget.product.unitCost * _qty;
    final profit = total - cost;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): _save,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): _save,
          },
          child: Focus(
            autofocus: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Registrar venda', style: AppTheme.display(24)),
                  const SizedBox(height: 4),
                  Text(widget.product.name, style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text('Em estoque', style: AppTheme.ui(12, color: AppColors.textMuted))),
                        Text('${widget.product.stock}', style: AppTheme.uiMoney(14, weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Quantidade vendida', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quantity,
                    autofocus: true,
                    style: AppTheme.uiMoney(15),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '1'),
                  ),
                  const SizedBox(height: 18),
                  Text('Valor total recebido', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _total,
                    style: AppTheme.uiMoney(15),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: _moneyInput(),
                  ),
                  if (total > 0 && _qty > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text('Lucro da venda', style: AppTheme.ui(12, color: AppColors.textMuted)),
                        const Spacer(),
                        Text(
                          money(profit),
                          style: AppTheme.uiMoney(
                            15,
                            color: profit >= 0 ? AppColors.income : AppColors.expense,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: AppTheme.ui(13, color: AppColors.expense)),
                  ],
                  const SizedBox(height: 26),
                  FilledButton(onPressed: _save, child: const Text('Confirmar venda')),
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
      ),
    );
  }
} 