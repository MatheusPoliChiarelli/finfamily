import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format.dart';

Future<AppTransaction?> showTransactionDialog(
  BuildContext context,
  DateTime initialDate, {
  bool isIncome = false,
}) {
  return showDialog<AppTransaction>(
    context: context,
    builder: (_) => _TransactionDialog(initialDate: initialDate, isIncome: isIncome),
  );
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.initialDate, required this.isIncome});

  final DateTime initialDate;
  final bool isIncome;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _amount = TextEditingController();
  final _description = TextEditingController();

  late bool _isIncome;
  late DateTime _date;
  late Category _category;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _isIncome = widget.isIncome;
    _category = _options.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  List<Category> get _options => _isIncome ? Categories.incomes : Categories.expenses;

  void _switchType(bool income) {
    setState(() {
      _isIncome = income;
      _category = _options.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final value = parseCurrency(_amount.text);
    if (value <= 0) {
      setState(() => _error = 'Informe um valor válido');
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final description = _description.text.trim();

    Navigator.of(context).pop(
      AppTransaction(
        id: '',
        amount: value,
        isIncome: _isIncome,
        date: _date,
        description: description.isEmpty ? _category.name : description,
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isIncome ? 'Nova entrada' : 'Nova saída', style: AppTheme.display(24)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _typeButton('Saída', false, AppColors.expense, Icons.arrow_upward)),
                  const SizedBox(width: 10),
                  Expanded(child: _typeButton('Entrada', true, AppColors.income, Icons.arrow_downward)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Valor', style: AppTheme.ui(12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                autofocus: true,
                style: AppTheme.uiMoney(15),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(hintText: '0,00', prefixText: 'R\$  '),
              ),
              const SizedBox(height: 20),
              Text('Categoria', style: AppTheme.ui(12, color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.map(_categoryChip).toList(),
              ),
              const SizedBox(height: 20),
              Text('Data', style: AppTheme.ui(12, color: AppColors.textMuted)),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Descrição', style: AppTheme.ui(12, color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                  Text('opcional', style: AppTheme.ui(11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                style: AppTheme.ui(14),
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(hintText: 'Compra do mês, farmácia, uber'),
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
    );
  }

  Widget _categoryChip(Category c) {
    final selected = _category.id == c.id;
    return InkWell(
      onTap: () => setState(() => _category = c),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 14, 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 15,
              height: 15,
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
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Icon(c.icon, size: 14, color: Color(c.color)),
            const SizedBox(width: 7),
            Text(
              c.name,
              style: AppTheme.ui(
                12,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
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
        height: 48,
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