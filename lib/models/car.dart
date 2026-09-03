import 'package:cloud_firestore/cloud_firestore.dart';

class CarCost {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String typeId;

  const CarCost({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.typeId = 'outro',
  });

  factory CarCost.fromMap(Map<String, dynamic> m) => CarCost(
        id: m['id'] as String? ?? '',
        description: m['description'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        typeId: m['typeId'] as String? ?? 'outro',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'typeId': typeId,
      };
}


class Car {
  final String id;
  final String name;
  final String plate;
  final String year;
  final DateTime purchaseDate;
  final double purchasePrice;
  final List<CarCost> costs;
  final DateTime? saleDate;
  final double? salePrice;

  const Car({
    required this.id,
    required this.name,
    required this.plate,
    required this.year,
    required this.purchaseDate,
    required this.purchasePrice,
    this.costs = const [],
    this.saleDate,
    this.salePrice,
  });

  bool get isSold => salePrice != null;

  double get totalCosts => costs.fold<double>(0, (s, c) => s + c.amount);

  double get totalInvested => purchasePrice + totalCosts;

  double get profit => isSold ? salePrice! - totalInvested : 0;

  double get margin => totalInvested == 0 ? 0 : profit / totalInvested * 100;

  int get daysHeld => (saleDate ?? DateTime.now()).difference(purchaseDate).inDays;

  factory Car.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawCosts = (d['costs'] as List<dynamic>? ?? [])
        .map((e) => CarCost.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Car(
      id: doc.id,
      name: d['name'] as String? ?? '',
      plate: d['plate'] as String? ?? '',
      year: d['year'] as String? ?? '',
      purchaseDate: (d['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      purchasePrice: (d['purchasePrice'] as num?)?.toDouble() ?? 0,
      costs: rawCosts,
      saleDate: (d['saleDate'] as Timestamp?)?.toDate(),
      salePrice: (d['salePrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'plate': plate,
        'year': year,
        'purchaseDate': Timestamp.fromDate(purchaseDate),
        'purchasePrice': purchasePrice,
        'costs': costs.map((c) => c.toMap()).toList(),
        'saleDate': saleDate == null ? null : Timestamp.fromDate(saleDate!),
        'salePrice': salePrice,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

