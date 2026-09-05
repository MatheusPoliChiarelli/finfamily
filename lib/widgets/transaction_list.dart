import 'package:flutter/material.dart';

import '../data/banks.dart';
import '../data/categories.dart';
import '../models/app_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    required this.onDelete,
    this.emptyMessage = 'Nenhum lançamento',
    this.showDate = true,
    this.showBank = false,
  });

  final List<AppTransaction> transactions;
  final ValueChanged<String> onDelete;
  final String emptyMessage;
  final bool showDate;
  final bool showBank;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(emptyMessage, style: AppTheme.ui(13, color: AppColors.textMuted)),
        ),
      );
    }

    return Column(children: transactions.map(_row).toList());
  }

  Widget _row(AppTransaction t) {
    final meta = showDate
        ? '${t.categoryName} · ${t.createdByName} · ${dayLabel(t.date)}'
        : '${t.categoryName} · ${t.createdByName}';

    final bank = Banks.byId(t.bankId);

    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(t.description, style: AppTheme.ui(13), overflow: TextOverflow.ellipsis),
                    ),
                    if (showBank && t.bankId.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
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
                                child: Image.asset(bank.logo!, fit: BoxFit.cover),
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
                    ],
                    if (t.isRecurring) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.repeat, size: 13, color: AppColors.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(meta, style: AppTheme.ui(11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            '${t.isIncome ? '+' : '-'} ${plain(t.amount)}',
            style: AppTheme.uiMoney(13, color: t.isIncome ? AppColors.income : AppColors.expense),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => onDelete(t.id),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}