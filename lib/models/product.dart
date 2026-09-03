import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String brand;
  final String model;
  final String type;
  final DateTime purchaseDate;
  final double unitCost;
  final int quantity;
  final int sold;
  final double revenue;

  const Product({
    required this.id,
    required this.brand,
    required this.model,
    required this.type,
    required this.purchaseDate,
    required this.unitCost,
    required this.quantity,
    this.sold = 0,
    this.revenue = 0,
  });

  String get name => '$brand $model'.trim();

  int get stock => quantity - sold;

  bool get soldOut => stock <= 0;

  double get invested => unitCost * quantity;

  double get stockValue => unitCost * stock;

  double get profit => revenue - (unitCost * sold);

  double get avgSalePrice => sold == 0 ? 0 : revenue / sold;

  double get margin => revenue == 0 ? 0 : profit / revenue * 100;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Product(
      id: doc.id,
      brand: d['brand'] as String? ?? '',
      model: d['model'] as String? ?? '',
      type: d['type'] as String? ?? 'outro',
      purchaseDate: (d['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unitCost: (d['unitCost'] as num?)?.toDouble() ?? 0,
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      sold: (d['sold'] as num?)?.toInt() ?? 0,
      revenue: (d['revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'brand': brand,
        'model': model,
        'type': type,
        'purchaseDate': Timestamp.fromDate(purchaseDate),
        'unitCost': unitCost,
        'quantity': quantity,
        'sold': sold,
        'revenue': revenue,
        'createdAt': FieldValue.serverTimestamp(),
      };
}