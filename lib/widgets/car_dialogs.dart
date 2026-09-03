import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/car.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';
import '../data/car_costs.dart';
Future<Car?> showCarDialog(BuildContext context) =>
    showDialog<Car>(context: context, builder: (_) => const _CarDialog());

Future<CarCost?> showCostDialog(BuildContext context) =>
    showDialog<CarCost>(context: context, builder: (_) => const _CostDialog());

Future<(double, DateTime)?> showSellDialog(BuildContext context, Car car) =>
    showDialog<(double, DateTime)>(context: context, builder: (_) => _SellDialog(car: car));

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.onSave, required this.children});

  final VoidCallback onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470, maxHeight: 640),
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
}

InputDecoration _moneyDecoration() => InputDecoration(
      hintText: '0,00',
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Text('R\$', style: AppTheme.uiMoney(15, color: AppColors.textSecondary)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );

Widget _label(String text) => Text(text, style: AppTheme.ui(12, color: AppColors.textMuted));

Widget _dateField(BuildContext context, DateTime date, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
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
          Text(dayLabel(date), style: AppTheme.ui(14)),
        ],
      ),
    ),
  );
}

class _CarDialog extends StatefulWidget {
  const _CarDialog();

  @override
  State<_CarDialog> createState() => _CarDialogState();
}

class _CarDialogState extends State<_CarDialog> {
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();

  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _price.dispose();
    super.dispose();
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
    final price = parseCurrency(_price.text);
    if (_brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      setState(() => _error = 'Informe marca e modelo');
      return;
    }
    if (price <= 0) {
      setState(() => _error = 'Informe o valor de compra');
      return;
    }

    Navigator.of(context).pop(
      Car(
        id: '',
        name: '${_brand.text.trim()} ${_model.text.trim()}',
        plate: '',
        year: _year.text.trim(),
        purchaseDate: _date,
        purchasePrice: price,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      onSave: _save,
      children: [
        Text('Novo carro', style: AppTheme.display(24)),
        const SizedBox(height: 4),
        Text('Entra como ativo no estoque', style: AppTheme.ui(12, color: AppColors.textMuted)),
        const SizedBox(height: 22),
        _label('Dados do carro'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _brand,
                autofocus: true,
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
        ),
        const SizedBox(height: 20),
        _label('Valor de compra'),
        const SizedBox(height: 8),
        TextField(
          controller: _price,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          decoration: _moneyDecoration(),
        ),
        const SizedBox(height: 20),
        _label('Data da compra'),
        const SizedBox(height: 8),
        _dateField(context, _date, _pickDate),
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
    );
  }
}

class _CostDialog extends StatefulWidget {
  const _CostDialog();

  @override
  State<_CostDialog> createState() => _CostDialogState();
}

class _CostDialogState extends State<_CostDialog> {
  final _description = TextEditingController();
  final _amount = TextEditingController();

  DateTime _date = DateTime.now();
  String _typeId = 'cautelar';
  String? _error;

  bool get _isOther => _typeId == 'outro';

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
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
    final amount = parseCurrency(_amount.text);
    if (amount <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }
    if (_isOther && _description.text.trim().isEmpty) {
      setState(() => _error = 'Informe a descrição do custo');
      return;
    }

    Navigator.of(context).pop(
      CarCost(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        description: _isOther ? _description.text.trim() : CarCostTypes.byId(_typeId).name,
        amount: amount,
        date: _date,
        typeId: _typeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      onSave: _save,
      children: [
        Text('Novo custo', style: AppTheme.display(24)),
        const SizedBox(height: 22),
        _label('Tipo do custo'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            const gap = 8.0;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: CarCostTypes.all
                  .where((t) => t.id != 'compra')
                  .map((t) => SizedBox(width: width, child: _costChip(t)))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _label('Valor'),
        const SizedBox(height: 8),
        TextField(
          controller: _amount,
          autofocus: true,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          decoration: _moneyDecoration(),
        ),
        const SizedBox(height: 20),
        _label('Data'),
        const SizedBox(height: 8),
        _dateField(context, _date, _pickDate),
        if (_isOther) ...[
          const SizedBox(height: 20),
          _label('Descrição'),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            style: AppTheme.ui(14),
            decoration: const InputDecoration(hintText: 'Do que se trata'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: AppTheme.ui(13, color: AppColors.expense)),
        ],
        const SizedBox(height: 26),
        FilledButton(onPressed: _save, child: const Text('Adicionar custo')),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTheme.ui(13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _costChip(CarCostType t) {
    final selected = _typeId == t.id;
    return InkWell(
      onTap: () => setState(() => _typeId = t.id),
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
            Container(
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
            ),
            const SizedBox(width: 7),
            Icon(t.icon, size: 14, color: selected ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t.name,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.ui(
                  12,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellDialog extends StatefulWidget {
  const _SellDialog({required this.car});

  final Car car;

  @override
  State<_SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends State<_SellDialog> {
  final _price = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.car.purchaseDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final price = parseCurrency(_price.text);
    if (price <= 0) {
      setState(() => _error = 'Informe o valor da venda');
      return;
    }
    Navigator.of(context).pop((price, _date));
  }

  @override
  Widget build(BuildContext context) {
    final invested = widget.car.totalInvested;
    final price = parseCurrency(_price.text);
    final profit = price > 0 ? price - invested : null;

    return _DialogShell(
      onSave: _save,
      children: [
        Text('Registrar venda', style: AppTheme.display(24)),
        const SizedBox(height: 4),
        Text(widget.car.name, style: AppTheme.ui(12, color: AppColors.textMuted)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: Text('Total investido', style: AppTheme.ui(12, color: AppColors.textMuted))),
              Text(money(invested), style: AppTheme.uiMoney(14, weight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label('Valor da venda'),
        const SizedBox(height: 8),
        TextField(
          controller: _price,
          autofocus: true,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: _moneyDecoration(),
        ),
        if (profit != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Lucro previsto', style: AppTheme.ui(12, color: AppColors.textMuted)),
              const SizedBox(width: 10),
              Text(
                money(profit),
                style: AppTheme.uiMoney(
                  14,
                  color: profit >= 0 ? AppColors.income : AppColors.expense,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        _label('Data da venda'),
        const SizedBox(height: 8),
        _dateField(context, _date, _pickDate),
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
    );
  }
}