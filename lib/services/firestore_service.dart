import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../models/fixed_bill.dart';
import '../utils/format.dart';
import '../models/car.dart';
import '../models/product.dart';

class FirestoreService {
  FirestoreService(this.householdId);

  final String householdId;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _house =>
      _db.collection('households').doc(householdId);

  CollectionReference<Map<String, dynamic>> get _transactions => _house.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _budgets => _house.collection('budgets');
  CollectionReference<Map<String, dynamic>> get _fixedBills => _house.collection('fixedBills');

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


  Stream<List<AppTransaction>> transactionsOfYear(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppTransaction.fromDoc).toList());
  }

  Stream<List<Budget>> budgetsOfYear(int year) => _budgets
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$year-01')
      .where(FieldPath.documentId, isLessThanOrEqualTo: '$year-12')
      .snapshots()
      .map((snap) => snap.docs.map(Budget.fromDoc).toList());

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

  Future<void> saveOpeningBalance(DateTime month, String bankId, double value, String uid) =>
      _budgets.doc(monthKey(month)).set({
        'openingBalances': {bankId: value},
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }, SetOptions(merge: true));

  Future<void> saveClosingBalance(DateTime month, String bankId, double value, String uid) =>
      _budgets.doc(monthKey(month)).set({
        'closingBalances': {bankId: value},
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }, SetOptions(merge: true));

  Stream<List<FixedBill>> fixedBills() => _fixedBills
      .orderBy('amount', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(FixedBill.fromDoc).toList());

  Future<void> addFixedBill(FixedBill bill) => _fixedBills.add(bill.toMap());

  Future<void> deleteFixedBill(String id) => _fixedBills.doc(id).delete();


  CollectionReference<Map<String, dynamic>> get _cars => _house.collection('cars');

  Stream<List<Car>> cars() => _cars
      .orderBy('purchaseDate', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Car.fromDoc).toList());

  Future<void> addCar(Car car) => _cars.add(car.toMap());

  Future<void> deleteCar(String id) => _cars.doc(id).delete();

  Future<void> updateCosts(String carId, List<CarCost> costs) =>
      _cars.doc(carId).update({'costs': costs.map((c) => c.toMap()).toList()});

  Future<void> sellCar(String carId, double price, DateTime date) => _cars.doc(carId).update({
        'salePrice': price,
        'saleDate': Timestamp.fromDate(date),
      });

  Future<void> reopenCar(String carId) => _cars.doc(carId).update({
        'salePrice': null,
        'saleDate': null,
      });

  CollectionReference<Map<String, dynamic>> get _products => _house.collection('products');

  Stream<List<Product>> products() => _products
      .orderBy('purchaseDate', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Product.fromDoc).toList());

  Future<void> addProduct(Product product) => _products.add(product.toMap());

  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  Future<void> registerSale(String productId, int currentSold, double currentRevenue, int units, double total) =>
      _products.doc(productId).update({
        'sold': currentSold + units,
        'revenue': currentRevenue + total,
      });


  Stream<List<Product>> productsAll() => products();

  Future<void> reopenProduct(String productId) =>
      _products.doc(productId).update({'sold': 0, 'revenue': 0});







}

