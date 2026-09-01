import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

Future<AppTransaction?> showTransactionDialog(
  BuildContext context,
  DateTime date, {
  required bool isIncome,
}) {
  return showDialog<AppTransaction>(
    context: context,
    builder: (_) => _TransactionDialog(date: date, isIncome: isIncome),
  );
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.date, required this.isIncome});

  final DateTime date;
  final bool isIncome;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _amount = TextEditingController();
  final _description = TextEditingController();

  late Category _category;
  String? _error;

  List<Category> get _options => widget.isIncome ? Categories.incomes : Categories.expenses;

  Color get _accent => widget.isIncome ? AppColors.income : AppColors.expense;

  bool get _needsDescription =>
      _category.id == 'outros' || _category.id == 'outras_receitas';

  @override
  void initState() {
    super.initState();
    _category = _options.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final value = parseCurrency(_amount.text);
    if (value <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final typed = _needsDescription ? _description.text.trim() : '';

    Navigator.of(context).pop(
      AppTransaction(
        id: '',
        amount: value,
        isIncome: widget.isIncome,
        date: widget.date,
        description: typed.isEmpty ? _category.name : typed,
        categoryId: _category.id,
        categoryName: _category.name,
        categoryColor: _category.color,
        createdBy: user.uid,
        createdByName: user.displayName ?? 'Alguém',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
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
                  Row(
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
                            Text(
                              widget.isIncome ? 'Nova entrada' : 'Nova saída',
                              style: AppTheme.display(24),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fullDayLabel(widget.date),
                              style: AppTheme.ui(12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Valor', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amount,
                    autofocus: true,
                    style: AppTheme.uiMoney(15),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    onSubmitted: (_) => _save(),
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
                        children: _options
                            .map((c) => SizedBox(width: width, child: _categoryChip(c)))
                            .toList(),
                      );
                    },
                  ),
                  if (_needsDescription) ...[
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