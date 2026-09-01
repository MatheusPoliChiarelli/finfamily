import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransaction {
  final String id;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String description;
  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final String createdBy;
  final String createdByName;
  final String? recurringId;
  final DateTime? createdAt;

  const AppTransaction({
    required this.id,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.createdBy,
    required this.createdByName,
    this.recurringId,
    this.createdAt,
  });

  bool get isRecurring => recurringId != null;

  DateTime get sortKey => createdAt ?? date;

  factory AppTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppTransaction(
      id: doc.id,
      amount: (d['amount'] as num).toDouble(),
      isIncome: d['type'] == 'income',
      date: (d['date'] as Timestamp).toDate(),
      description: d['description'] as String? ?? '',
      categoryId: d['categoryId'] as String? ?? 'outros',
      categoryName: d['categoryName'] as String? ?? 'Outros',
      categoryColor: d['categoryColor'] as int? ?? 0xFF888780,
      createdBy: d['createdBy'] as String? ?? '',
      createdByName: d['createdByName'] as String? ?? '',
      recurringId: d['recurringId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'type': isIncome ? 'income' : 'expense',
        'date': Timestamp.fromDate(date),
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryColor': categoryColor,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'recurringId': recurringId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}