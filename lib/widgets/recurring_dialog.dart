import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/categories.dart';
import '../models/recurring_rule.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

Future<RecurringRule?> showRecurringDialog(BuildContext context, DateTime month) {
  return showDialog<RecurringRule>(
    context: context,
    builder: (_) => _RecurringDialog(month: month),
  );
}

class _RecurringDialog extends StatefulWidget {
  const _RecurringDialog({required this.month});

  final DateTime month;

  @override
  State<_RecurringDialog> createState() => _RecurringDialogState();
}

class _RecurringDialogState extends State<_RecurringDialog> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '5');

  bool _isIncome = false;
  late Category _category;
  String? _error;

  List<Category> get _options => _isIncome ? Categories.incomes : Categories.expenses;

  @override
  void initState() {
    super.initState();
    _category = _options.first;
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _day.dispose();
    super.dispose();
  }

  void _switchType(bool income) {
    setState(() {
      _isIncome = income;
      _category = _options.first;
    });
  }

  void _save() {
    final value = parseCurrency(_amount.text);
    final day = int.tryParse(_day.text) ?? 0;

    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome da conta');
      return;
    }
    if (value <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }
    if (day < 1 || day > 31) {
      setState(() => _error = 'O dia deve estar entre 1 e 31');
      return;
    }

    Navigator.of(context).pop(
      RecurringRule(
        id: '',
        description: _description.text.trim(),
        amount: value,
        isIncome: _isIncome,
        categoryId: _category.id,
        categoryName: _category.name,
        categoryColor: _category.color,
        dayOfMonth: day,
        startMonth: monthKey(widget.month),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470, maxHeight: 680),
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
                    'Será lançada automaticamente todo mês',
                    style: AppTheme.ui(12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _typeButton('Saída', false, AppColors.expense, Icons.arrow_upward)),
                      const SizedBox(width: 10),
                      Expanded(child: _typeButton('Entrada', true, AppColors.income, Icons.arrow_downward)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Nome da conta', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    autofocus: true,
                    style: AppTheme.ui(14),
                    decoration: const InputDecoration(hintText: 'Aluguel, internet, energia'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Valor', style: AppTheme.ui(12, color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _amount,
                              style: AppTheme.uiMoney(15),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: const InputDecoration(hintText: '0,00', prefixText: 'R\$  '),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Dia', style: AppTheme.ui(12, color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _day,
                              style: AppTheme.uiMoney(15),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              decoration: const InputDecoration(hintText: '5'),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        children: _options
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

  Widget _typeButton(String label, bool income, Color color, IconData icon) {
    final selected = _isIncome == income;
    return InkWell(
      onTap: () => _switchType(income),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 9),
            Text(
              label,
              style: AppTheme.ui(
                14,
                color: selected ? color : AppColors.textSecondary,
                weight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}