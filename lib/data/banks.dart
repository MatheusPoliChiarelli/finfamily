import 'package:flutter/material.dart';

class Bank {
  final String id;
  final String name;
  final String short;
  final Color color;
  final Color onColor;
  final String? logo;

  const Bank({
    required this.id,
    required this.name,
    required this.short,
    required this.color,
    required this.onColor,
    this.logo,
  });
}

class Banks {
  static const geral = Bank(
    id: 'geral',
    name: 'Geral',
    short: 'G',
    color: Color(0xFF4DA3FF),
    onColor: Color(0xFF08121F),
  );

  static const sicoob = Bank(
    id: 'sicoob',
    name: 'Sicoob',
    short: 'S',
    color: Color(0xFF00AE9D),
    onColor: Color(0xFF04231F),
    logo: 'assets/banks/sicoob.png',
  );

  static const itau = Bank(
    id: 'itau',
    name: 'Itaú',
    short: 'I',
    color: Color(0xFFEC7000),
    onColor: Color(0xFF2A1400),
    logo: 'assets/banks/itau.png',
  );

  static const nubank = Bank(
    id: 'nubank',
    name: 'Nubank',
    short: 'N',
    color: Color(0xFF9B4DFF),
    onColor: Color(0xFF1B0733),
    logo: 'assets/banks/nubank.png',
  );

  static const all = <Bank>[geral, sicoob, itau, nubank];

  static const accounts = <Bank>[sicoob, itau, nubank];

  static Bank byId(String? id) => all.firstWhere(
        (b) => b.id == id,
        orElse: () => geral,
      );
}