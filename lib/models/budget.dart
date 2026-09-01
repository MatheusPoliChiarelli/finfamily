import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String month;
  final Map<String, double> limits;
  final double openingBalance;
  final double closingBalance;

  const Budget({
    required this.month,
    required this.limits,
    this.openingBalance = 0,
    this.closingBalance = 0,
  });

  factory Budget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final raw = (data?['limits'] as Map<String, dynamic>?) ?? {};
    return Budget(
      month: doc.id,
      limits: raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      openingBalance: (data?['openingBalance'] as num?)?.toDouble() ?? 0,
      closingBalance: (data?['closingBalance'] as num?)?.toDouble() ?? 0,
    );
  }

  double get monthBalance => closingBalance - openingBalance;

  double limitFor(String categoryId) => limits[categoryId] ?? 0;
}