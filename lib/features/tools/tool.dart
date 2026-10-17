import 'package:flutter/material.dart';

enum ToolCategory {
  calculators('Calculadoras', Icons.calculate_outlined),
  converters('Conversores', Icons.swap_horiz),
  organization('Organização', Icons.checklist),
  utilities('Utilidades', Icons.handyman_outlined);

  const ToolCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Entrada estática do catálogo. [id] é estável e usado em favoritos/rotas.
class Tool {
  const Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    this.keywords = const [],
  });

  final String id;
  final String name;
  final String description;
  final ToolCategory category;
  final IconData icon;
  final List<String> keywords;

  String get route => '/tool/$id';
}
