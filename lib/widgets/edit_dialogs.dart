import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/fashion.dart';
import '../models/car.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

Future<Map<String, dynamic>?> showEditCarDialog(BuildContext context, Car car) =>
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditCarDialog(car: car),
    );

Future<Map<String, dynamic>?> showEditProductDialog(BuildContext context, Product product) =>
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditProductDialog(product: product),
    );

InputDecoration _moneyInput() => InputDecoration(
      hintText: '0,00',
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Text('R\$', style: AppTheme.uiMoney(15, color: AppColors.textSecondary)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );

Widget _label(String text) =>
    Text(text, style: AppTheme.ui(12, color: AppColors.textMuted));

Widget _shell({
  required BuildContext context,
  required VoidCallback onSave,
  required List<Widget> children,
}) {
  return Dialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): onSave,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): onSave,
        },
        child: Focus(
          autofocus: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

class _EditCarDialog extends StatefulWidget {
  const _EditCarDialog({required this.car});

  final Car car;

  @override
  State<_EditCarDialog> createState() => _EditCarDialogState();
}

class _EditCarDialogState extends State<_EditCarDialog> {
  late final TextEditingController _name;
  late final TextEditingController _year;
  late final TextEditingController _plate;
  late final TextEditingController _price;
  late final TextEditingController _salePrice;

  late DateTime _purchaseDate;
  DateTime? _saleDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.car;
    _name = TextEditingController(text: c.name);
    _year = TextEditingController(text: c.year);
    _plate = TextEditingController(text: c.plate);
    _price = TextEditingController(text: currencyMask(c.purchasePrice));
    _salePrice = TextEditingController(
      text: c.salePrice == null ? '' : currencyMask(c.salePrice!),
    );
    _purchaseDate = c.purchaseDate;
    _saleDate = c.saleDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    _plate.dispose();
    _price.dispose();
    _salePrice.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _pickSaleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate ?? DateTime.now(),
      firstDate: _purchaseDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _saleDate = picked);
  }

  void _save() {
    final price = parseCurrency(_price.text);
    final sale = parseCurrency(_salePrice.text);

    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome do carro');
      return;
    }
    if (price <= 0) {
      setState(() => _error = 'Informe o valor de compra');
      return;
    }

    Navigator.of(context).pop({
      'name': _name.text.trim(),
      'year': _year.text.trim(),
      'plate': _plate.text.trim().toUpperCase(),
      'purchasePrice': price,
      'purchaseDate': Timestamp.fromDate(_purchaseDate),
      'salePrice': sale > 0 ? sale : null,
      'saleDate': sale > 0 && _saleDate != null ? Timestamp.fromDate(_saleDate!) : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final sold = parseCurrency(_salePrice.text) > 0;

    return _shell(
      context: context,
      onSave: _save,
      children: [
        Text('Editar carro', style: AppTheme.display(24)),
        const SizedBox(height: 4),
        Text(widget.car.name, style: AppTheme.ui(12, color: AppColors.textMuted)),
        const SizedBox(height: 22),
        _label('Nome do carro'),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          style: AppTheme.ui(14),
          decoration: const InputDecoration(hintText: 'Marca e modelo'),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Ano'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _year,
                    style: AppTheme.uiMoney(14),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(hintText: '2018/2019'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Placa'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _plate,
                    style: AppTheme.ui(14),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'ABC1D23'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Valor de compra'),
        const SizedBox(height: 8),
        TextField(
          controller: _price,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          decoration: _moneyInput(),
        ),
        const SizedBox(height: 18),
        _label('Data da compra'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickPurchaseDate,
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
                Text(dayLabel(_purchaseDate), style: AppTheme.ui(14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('Valor da venda'),
        const SizedBox(height: 8),
        TextField(
          controller: _salePrice,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: _moneyInput(),
        ),
        const SizedBox(height: 6),
        Text(
          'Deixe zerado para voltar o carro ao estoque',
          style: AppTheme.ui(10, color: AppColors.textMuted),
        ),
        if (sold) ...[
          const SizedBox(height: 18),
          _label('Data da venda'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickSaleDate,
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
                  Text(
                    _saleDate == null ? 'Escolher data' : dayLabel(_saleDate!),
                    style: AppTheme.ui(14),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: AppTheme.ui(13, color: AppColors.expense)),
        ],
        const SizedBox(height: 26),
        FilledButton(onPressed: _save, child: const Text('Salvar alterações')),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTheme.ui(13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _EditProductDialog extends StatefulWidget {
  const _EditProductDialog({required this.product});

  final Product product;

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _quantity;
  late final TextEditingController _sold;
  late final TextEditingController _unitCost;
  late final TextEditingController _revenue;

  late String _type;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _brand = TextEditingController(text: p.brand);
    _model = TextEditingController(text: p.model);
    _quantity = TextEditingController(text: '${p.quantity}');
    _sold = TextEditingController(text: '${p.sold}');
    _unitCost = TextEditingController(text: currencyMask(p.unitCost));
    _revenue = TextEditingController(text: currencyMask(p.revenue));
    _type = p.type;
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _quantity.dispose();
    _sold.dispose();
    _unitCost.dispose();
    _revenue.dispose();
    super.dispose();
  }


  void _save() {
    final qty = int.tryParse(_quantity.text) ?? 0;
    final sold = int.tryParse(_sold.text) ?? 0;
    final cost = parseCurrency(_unitCost.text);
    final revenue = parseCurrency(_revenue.text);

    if (_brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      setState(() => _error = 'Informe marca e modelo');
      return;
    }
    if (qty <= 0) {
      setState(() => _error = 'Informe a quantidade');
      return;
    }
    if (sold > qty) {
      setState(() => _error = 'Vendidas não pode ser maior que a quantidade');
      return;
    }
    if (cost <= 0) {
      setState(() => _error = 'Informe o custo unitário');
      return;
    }

    Navigator.of(context).pop({
      'brand': _brand.text.trim(),
      'model': _model.text.trim(),
      'type': _type,
      'quantity': qty,
      'sold': sold,
      'unitCost': cost,
      'revenue': revenue,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _shell(
      context: context,
      onSave: _save,
      children: [
        Text('Editar peça', style: AppTheme.display(24)),
        const SizedBox(height: 4),
        Text(widget.product.name, style: AppTheme.ui(12, color: AppColors.textMuted)),
        const SizedBox(height: 22),
        _label('Marca e modelo'),
        const SizedBox(height: 8),
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
        _label('Tipo da peça'),
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
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Quantidade comprada'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quantity,
                    style: AppTheme.uiMoney(15),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
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
                  _label('Quantidade vendida'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sold,
                    style: AppTheme.uiMoney(15),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Custo por peça'),
        const SizedBox(height: 8),
        TextField(
          controller: _unitCost,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          decoration: _moneyInput(),
        ),
        const SizedBox(height: 18),
        _label('Faturamento total das vendas'),
        const SizedBox(height: 8),
        TextField(
          controller: _revenue,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          decoration: _moneyInput(),
        ),


        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: AppTheme.ui(13, color: AppColors.expense)),
        ],
        const SizedBox(height: 26),
        FilledButton(onPressed: _save, child: const Text('Salvar alterações')),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTheme.ui(13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _typeChip(PieceType t) {
    final selected = _type == t.id;
    return InkWell(
      onTap: () => setState(() => _type = t.id),
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
            Icon(t.icon, size: 14, color: selected ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 7),
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