import 'package:flutter/material.dart';

class PieceType {
  final String id;
  final String name;
  final IconData icon;

  const PieceType({required this.id, required this.name, required this.icon});
}

class PieceTypes {
  static const all = <PieceType>[
    PieceType(id: 'vestido', name: 'Vestido', icon: Icons.checkroom_outlined),
    PieceType(id: 'saia', name: 'Saia', icon: Icons.dry_cleaning_outlined),
    PieceType(id: 'calca', name: 'Calça', icon: Icons.straighten_outlined),
    PieceType(id: 'blusa', name: 'Blusa', icon: Icons.woman_outlined),
    PieceType(id: 'cropped', name: 'Cropped', icon: Icons.crop_outlined),
    PieceType(id: 'conjunto', name: 'Conjunto', icon: Icons.layers_outlined),
    PieceType(id: 'macacao', name: 'Macacão', icon: Icons.accessibility_new_outlined),
    PieceType(id: 'short', name: 'Short', icon: Icons.crop_square_outlined),
    PieceType(id: 'body', name: 'Body', icon: Icons.circle_outlined),
    PieceType(id: 'jaqueta', name: 'Jaqueta', icon: Icons.ac_unit_outlined),
    PieceType(id: 'outro', name: 'Outro', icon: Icons.category_outlined),
  ];

  static PieceType byId(String? id) => all.firstWhere(
        (t) => t.id == id,
        orElse: () => all.last,
      );
}