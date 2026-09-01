import 'package:cloud_firestore/cloud_firestore.dart';

class FixedBill {
  final String id;
  final String name;
  final double amount;
  final String categoryId;
  final String categoryName;
  final int categoryColor;

  const FixedBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  factory FixedBill.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return FixedBill(
      id: doc.id,
      name: d['name'] as String? ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      categoryId: d['categoryId'] as String? ?? 'outros',
      categoryName: d['categoryName'] as String? ?? 'Outros',
      categoryColor: d['categoryColor'] as int? ?? 0xFF888780,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryColor': categoryColor,
        'createdAt': FieldValue.serverTimestamp(),
      };
}