import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/car.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

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
  final _name = TextEditingController();
  final _plate = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();

  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
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
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Informe o modelo do carro');
      return;
    }
    if (price <= 0) {
      setState(() => _error = 'Informe o valor de compra');
      return;
    }

    Navigator.of(context).pop(
      Car(
        id: '',
        name: _name.text.trim(),
        plate: _plate.text.trim().toUpperCase(),
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
        _label('Modelo'),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          autofocus: true,
          style: AppTheme.ui(14),
          decoration: const InputDecoration(hintText: 'Onix 1.0 LT'),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(width: 12),
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
          decoration: _moneyDecoration(),
        ),
        const SizedBox(height: 18),
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
  String? _error;

  static const _suggestions = [
    'Documentação',
    'Manutenção',
    'Funilaria',
    'Pintura',
    'Pneus',
    'Lavagem',
    'Transporte',
    'IPVA',
  ];

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
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'Informe a descrição do custo');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }

    Navigator.of(context).pop(
      CarCost(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        description: _description.text.trim(),
        amount: amount,
        date: _date,
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
        _label('Descrição'),
        const SizedBox(height: 8),
        TextField(
          controller: _description,
          autofocus: true,
          style: AppTheme.ui(14),
          decoration: const InputDecoration(hintText: 'Troca de embreagem'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _suggestions
              .map((s) => InkWell(
                    onTap: () => setState(() => _description.text = s),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Text(s, style: AppTheme.ui(11, color: AppColors.textSecondary)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 18),
        _label('Valor'),
        const SizedBox(height: 8),
        TextField(
          controller: _amount,
          style: AppTheme.uiMoney(15),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          decoration: _moneyDecoration(),
        ),
        const SizedBox(height: 18),
        _label('Data'),
        const SizedBox(height: 8),
        _dateField(context, _date, _pickDate),
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