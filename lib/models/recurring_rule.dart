import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringRule {
  final String id;
  final String description;
  final double amount;
  final bool isIncome;
  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final int dayOfMonth;
  final String startMonth;
  final String? endMonth;
  final bool active;

  const RecurringRule({
    required this.id,
    required this.description,
    required this.amount,
    required this.isIncome,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.dayOfMonth,
    required this.startMonth,
    this.endMonth,
    this.active = true,
  });

  factory RecurringRule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RecurringRule(
      id: doc.id,
      description: d['description'] as String? ?? '',
      amount: (d['amount'] as num).toDouble(),
      isIncome: d['type'] == 'income',
      categoryId: d['categoryId'] as String? ?? 'outros',
      categoryName: d['categoryName'] as String? ?? 'Outros',
      categoryColor: d['categoryColor'] as int? ?? 0xFF888780,
      dayOfMonth: d['dayOfMonth'] as int? ?? 1,
      startMonth: d['startMonth'] as String? ?? '',
      endMonth: d['endMonth'] as String?,
      active: d['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
        'type': isIncome ? 'income' : 'expense',
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryColor': categoryColor,
        'dayOfMonth': dayOfMonth,
        'startMonth': startMonth,
        'endMonth': endMonth,
        'active': active,
      };
}