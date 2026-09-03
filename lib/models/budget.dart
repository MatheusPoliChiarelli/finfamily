import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String month;
  final Map<String, double> limits;
  final Map<String, double> openingBalances;
  final Map<String, double> closingBalances;

  const Budget({
    required this.month,
    required this.limits,
    this.openingBalances = const {},
    this.closingBalances = const {},
  });

  factory Budget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final raw = (data?['limits'] as Map<String, dynamic>?) ?? {};
    final opening = (data?['openingBalances'] as Map<String, dynamic>?) ?? {};
    final closing = (data?['closingBalances'] as Map<String, dynamic>?) ?? {};

    return Budget(
      month: doc.id,
      limits: raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      openingBalances: opening.map((k, v) => MapEntry(k, (v as num).toDouble())),
      closingBalances: closing.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  double openingFor(String bankId) {
    if (bankId == 'geral') {
      return openingBalances.values.fold<double>(0, (s, v) => s + v);
    }
    return openingBalances[bankId] ?? 0;
  }

  double closingFor(String bankId) {
    if (bankId == 'geral') {
      return closingBalances.values.fold<double>(0, (s, v) => s + v);
    }
    return closingBalances[bankId] ?? 0;
  }

  double limitFor(String categoryId) => limits[categoryId] ?? 0;
}