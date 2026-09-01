import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../theme/app_theme.dart';

Future<Map<String, double>?> showBudgetDialog(
  BuildContext context,
  Map<String, double> current,
) {
  return showDialog<Map<String, double>>(
    context: context,
    builder: (_) => _BudgetDialog(current: current),
  );
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.current});

  final Map<String, double> current;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final c in Categories.expenses)
        c.id: TextEditingController(
          text: widget.current[c.id] == null ? '' : widget.current[c.id]!.toStringAsFixed(0),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final result = <String, double>{};
    _controllers.forEach((id, controller) {
      final raw = controller.text.replaceAll('.', '').replaceAll(',', '.');
      final value = double.tryParse(raw);
      if (value != null && value > 0) result[id] = value;
    });
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orçamento do mês', style: AppTheme.display(24)),
                  const SizedBox(height: 6),
                  Text(
                    'Deixe em branco para não acompanhar a categoria',
                    style: AppTheme.ui(13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shrinkWrap: true,
                children: Categories.expenses
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(c.icon, size: 17, color: Color(c.color)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(c.name, style: AppTheme.ui(14))),
                              SizedBox(
                                width: 130,
                                child: TextField(
                                  controller: _controllers[c.id],
                                  style: AppTheme.uiMoney(14),
                                  textAlign: TextAlign.right,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Column(
                children: [
                  FilledButton(onPressed: _save, child: const Text('Salvar orçamento')),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar', style: AppTheme.ui(13, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}