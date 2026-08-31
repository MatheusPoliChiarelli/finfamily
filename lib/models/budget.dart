import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String month;
  final Map<String, double> limits;

  const Budget({required this.month, required this.limits});

  factory Budget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = (doc.data()?['limits'] as Map<String, dynamic>?) ?? {};
    return Budget(
      month: doc.id,
      limits: raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  double limitFor(String categoryId) => limits[categoryId] ?? 0;

  Map<String, dynamic> toMap(String uid) => {
        'limits': limits,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      };
}