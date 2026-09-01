import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final int color;
  final bool isIncome;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });
}

class Categories {
  static const expenses = <Category>[
    Category(id: 'mercado', name: 'Mercado', icon: Icons.shopping_cart_outlined, color: 0xFF5DCAA5),
    Category(id: 'combustivel', name: 'Combustível', icon: Icons.local_gas_station_outlined, color: 0xFFEF9F27),
    Category(id: 'energia', name: 'Energia', icon: Icons.bolt_outlined, color: 0xFFFAC775),
    Category(id: 'agua', name: 'Água', icon: Icons.water_drop_outlined, color: 0xFF85B7EB),
    Category(id: 'aluguel', name: 'Aluguel', icon: Icons.home_outlined, color: 0xFF7F77DD),
    Category(id: 'unimed', name: 'Unimed', icon: Icons.local_hospital_outlined, color: 0xFFED93B1),
    Category(id: 'lazer', name: 'Lazer', icon: Icons.local_activity_outlined, color: 0xFFF0997B),
    Category(id: 'emprestimos', name: 'Empréstimos', icon: Icons.account_balance_outlined, color: 0xFFE24B4A),
    Category(id: 'farmacia', name: 'Farmácia', icon: Icons.medication_outlined, color: 0xFFF4C0D1),
    Category(id: 'contador', name: 'Contador', icon: Icons.calculate_outlined, color: 0xFFAFA9EC),
    Category(id: 'impostos', name: 'Impostos', icon: Icons.receipt_long_outlined, color: 0xFFBA7517),
    Category(id: 'singular', name: 'Singular', icon: Icons.apartment_outlined, color: 0xFF9FE1CB),
    Category(id: 'celular', name: 'Celular', icon: Icons.smartphone_outlined, color: 0xFF378ADD),
    Category(id: 'uber', name: 'Uber', icon: Icons.local_taxi_outlined, color: 0xFFB4B2A9),
    Category(id: 'academia', name: 'Academia', icon: Icons.fitness_center_outlined, color: 0xFF97C459),
    Category(id: 'meta_ads', name: 'Meta Ads', icon: Icons.campaign_outlined, color: 0xFF534AB7),
    Category(id: 'outros', name: 'Outros', icon: Icons.category_outlined, color: 0xFF888780),
  ];

  static const incomes = <Category>[
    Category(id: 'salario', name: 'Salário', icon: Icons.payments_outlined, color: 0xFF5FD4A0, isIncome: true),
    Category(id: 'freelance', name: 'Freelance', icon: Icons.work_outline, color: 0xFF5DCAA5, isIncome: true),
    Category(id: 'investimentos', name: 'Investimentos', icon: Icons.trending_up, color: 0xFF97C459, isIncome: true),
    Category(id: 'outras_receitas', name: 'Outras receitas', icon: Icons.add_circle_outline, color: 0xFF888780, isIncome: true),
  ];

  static List<Category> get all => [...expenses, ...incomes];

  static Category byId(String id) => all.firstWhere(
        (c) => c.id == id,
        orElse: () => expenses.last,
      );
}