import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/categories.dart';
import '../models/fixed_bill.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';

Future<FixedBill?> showFixedBillDialog(BuildContext context) {
  return showDialog<FixedBill>(
    context: context,
    builder: (_) => const _FixedBillDialog(),
  );
}

class _FixedBillDialog extends StatefulWidget {
  const _FixedBillDialog();

  @override
  State<_FixedBillDialog> createState() => _FixedBillDialogState();
}

class _FixedBillDialogState extends State<_FixedBillDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();

  Category _category = Categories.expenses.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final value = parseCurrency(_amount.text);

    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome da conta');
      return;
    }
    if (value <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }

    Navigator.of(context).pop(
      FixedBill(
        id: '',
        name: _name.text.trim(),
        amount: value,
        categoryId: _category.id,
        categoryName: _category.name,
        categoryColor: _category.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470, maxHeight: 620),
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
                  Text('Nova conta fixa', style: AppTheme.display(24)),
                  const SizedBox(height: 4),
                  Text(
                    'Serve como referência do custo mensal da casa',
                    style: AppTheme.ui(12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 22),
                  Text('Nome da conta', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    style: AppTheme.ui(14),
                    decoration: const InputDecoration(hintText: 'Aluguel, internet, energia'),
                  ),
                  const SizedBox(height: 20),
                  Text('Valor mensal', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amount,
                    style: AppTheme.uiMoney(15),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '0,00',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Text('R\$', style: AppTheme.uiMoney(15, color: AppColors.textSecondary)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Categoria', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const columns = 3;
                      const gap = 8.0;
                      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: Categories.expenses
                            .map((c) => SizedBox(width: width, child: _categoryChip(c)))
                            .toList(),
                      );
                    },
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
      ),
    );
  }

  Widget _categoryChip(Category c) {
    final selected = _category.id == c.id;
    return InkWell(
      onTap: () => setState(() => _category = c),
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
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 7),
            Icon(c.icon, size: 14, color: Color(c.color)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                c.name,
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