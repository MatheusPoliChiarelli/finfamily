import 'package:flutter/material.dart';

import '../data/banks.dart';
import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
    this.emptyMessage = 'Nenhum lançamento',
    this.showDate = true,
    this.showBank = false,
    this.filter = 'all',
  });

  final List<AppTransaction> transactions;
  final ValueChanged<String> onDelete;
  final ValueChanged<AppTransaction> onEdit;
  final String emptyMessage;
  final bool showDate;
  final bool showBank;
  final String filter;

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<AppTransaction> get _filtered {
    if (widget.filter == 'income') return widget.transactions.where((t) => t.isIncome).toList();
    if (widget.filter == 'expense') return widget.transactions.where((t) => !t.isIncome).toList();
    return widget.transactions;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                widget.filter == 'all' ? widget.emptyMessage : 'Nada neste filtro',
                style: AppTheme.ui(13, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...list.map(_row),
      ],
    );
  }



  Widget _row(AppTransaction t) {
    final meta = widget.showDate ? dayLabel(t.date) : '';
    final bank = Banks.byId(t.bankId);

    return InkWell(
      onTap: () => widget.onEdit(t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1F2429), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Categories.byId(t.categoryId).icon, size: 16, color: Color(t.categoryColor)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(t.description, style: AppTheme.ui(13), overflow: TextOverflow.ellipsis),
                      ),
                      if (t.isRecurring) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.repeat, size: 13, color: AppColors.accent),
                      ],
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(meta, style: AppTheme.ui(11, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 110,
              child: Text(
                '${t.isIncome ? '+' : '-'} ${plain(t.amount)}',
                textAlign: TextAlign.left,
                style: AppTheme.uiMoney(13, color: t.isIncome ? AppColors.income : AppColors.expense),
              ),
            ),
            const SizedBox(width: 20),
            const Spacer(),
            if (widget.showBank) ...[
              SizedBox(
                width: 132,
                child: t.bankId.isEmpty
                    ? const SizedBox()
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bank.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: bank.color.withValues(alpha: 0.5), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (bank.logo != null) ...[
                                Container(
                                  width: 13,
                                  height: 13,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(shape: BoxShape.circle),
                                  child: Image.asset(bank.logo!, fit: BoxFit.contain),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                bank.name,
                                style: AppTheme.ui(10, color: bank.color, weight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
            const SizedBox(width: 6),
            InkWell(
              onTap: () => widget.onDelete(t.id),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}