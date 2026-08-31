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
    Category(id: 'moradia', name: 'Moradia', icon: Icons.home_outlined, color: 0xFF7F77DD),
    Category(id: 'mercado', name: 'Mercado', icon: Icons.shopping_cart_outlined, color: 0xFF5DCAA5),
    Category(id: 'transporte', name: 'Transporte', icon: Icons.directions_car_outlined, color: 0xFF85B7EB),
    Category(id: 'saude', name: 'Saúde', icon: Icons.favorite_outline, color: 0xFFED93B1),
    Category(id: 'educacao', name: 'Educação', icon: Icons.school_outlined, color: 0xFFEF9F27),
    Category(id: 'lazer', name: 'Lazer', icon: Icons.local_activity_outlined, color: 0xFFF0997B),
    Category(id: 'alimentacao', name: 'Alimentação', icon: Icons.restaurant_outlined, color: 0xFF97C459),
    Category(id: 'assinaturas', name: 'Assinaturas', icon: Icons.subscriptions_outlined, color: 0xFFAFA9EC),
    Category(id: 'outros', name: 'Outros', icon: Icons.more_horiz, color: 0xFF888780),
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