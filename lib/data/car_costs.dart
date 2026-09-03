import 'package:flutter/material.dart';

class CarCostType {
  final String id;
  final String name;
  final IconData icon;

  const CarCostType({required this.id, required this.name, required this.icon});
}

class CarCostTypes {
  static const all = <CarCostType>[
    CarCostType(id: 'compra', name: 'Compra do carro', icon: Icons.directions_car_outlined),
    CarCostType(id: 'cautelar', name: 'Cautelar', icon: Icons.fact_check_outlined),
    CarCostType(id: 'cartorio', name: 'Cartório', icon: Icons.account_balance_outlined),
    CarCostType(id: 'vistoria', name: 'Vistoria', icon: Icons.search_outlined),
    CarCostType(id: 'placa', name: 'Placa', icon: Icons.badge_outlined),
    CarCostType(id: 'velocimetro', name: 'Velocímetro', icon: Icons.speed_outlined),
    CarCostType(id: 'documento', name: 'Documento', icon: Icons.description_outlined),
    CarCostType(id: 'anuncios', name: 'Anúncios', icon: Icons.campaign_outlined),
    CarCostType(id: 'outro', name: 'Outro', icon: Icons.category_outlined),
  ];

  static const selectable = all;




    static CarCostType byId(String? id) => all.firstWhere(
        (t) => t.id == id,
        orElse: () => all.last,
      );
}

