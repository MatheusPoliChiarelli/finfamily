import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../models/recurring_rule.dart';
import '../utils/format.dart';

class FirestoreService {
  FirestoreService(this.householdId);

  final String householdId;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _house =>
      _db.collection('households').doc(householdId);

  CollectionReference<Map<String, dynamic>> get _transactions => _house.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _recurring => _house.collection('recurring');
  CollectionReference<Map<String, dynamic>> get _budgets => _house.collection('budgets');

  Stream<List<AppTransaction>> transactionsOfMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppTransaction.fromDoc).toList());
  }

  Future<void> addTransaction(AppTransaction transaction) => _transactions.add(transaction.toMap());

  Future<void> deleteTransaction(String id) => _transactions.doc(id).delete();

  Stream<Budget> budgetOfMonth(DateTime month) =>
      _budgets.doc(monthKey(month)).snapshots().map(Budget.fromDoc);

  Future<void> saveBudget(DateTime month, Map<String, double> limits, String uid) =>
      _budgets.doc(monthKey(month)).set({
        'limits': limits,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }, SetOptions(merge: true));

  Future<void> saveOpeningBalance(DateTime month, double value, String uid) =>
      _budgets.doc(monthKey(month)).set({
        'openingBalance': value,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }, SetOptions(merge: true));

  Future<void> saveClosingBalance(DateTime month, double value, String uid) =>
      _budgets.doc(monthKey(month)).set({
        'closingBalance': value,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }, SetOptions(merge: true));

      
  Stream<List<RecurringRule>> recurringRules() => _recurring
      .orderBy('dayOfMonth')
      .snapshots()
      .map((snap) => snap.docs.map(RecurringRule.fromDoc).toList());

  Future<void> addRecurring(RecurringRule rule) => _recurring.add(rule.toMap());

  Future<void> deleteRecurring(String id) => _recurring.doc(id).delete();

  Future<void> ensureRecurringForMonth(DateTime month, String uid, String userName) async {
    final key = monthKey(month);
    final metaRef = _house.collection('meta').doc('recurringRuns');

    final meta = await metaRef.get();
    final processed = (meta.data()?['processed'] as Map<String, dynamic>?) ?? {};
    if (processed[key] == true) return;

    final rules = await _recurring.where('active', isEqualTo: true).get();
    final batch = _db.batch();
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    for (final doc in rules.docs) {
      final rule = RecurringRule.fromDoc(doc);
      if (rule.startMonth.compareTo(key) > 0) continue;
      if (rule.endMonth != null && rule.endMonth!.compareTo(key) < 0) continue;

      final day = rule.dayOfMonth.clamp(1, lastDay);
      final transaction = AppTransaction(
        id: '',
        amount: rule.amount,
        isIncome: rule.isIncome,
        date: DateTime(month.year, month.month, day),
        description: rule.description,
        categoryId: rule.categoryId,
        categoryName: rule.categoryName,
        categoryColor: rule.categoryColor,
        createdBy: uid,
        createdByName: userName,
        recurringId: rule.id,
      );
      batch.set(_transactions.doc(), transaction.toMap());
    }

    batch.set(metaRef, {
      'processed': {key: true}
    }, SetOptions(merge: true));

    await batch.commit();
  }
}