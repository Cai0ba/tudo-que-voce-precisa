import 'package:decimal/decimal.dart';

/// Medidas caseiras brasileiras usadas pelo conversor (ver
/// docs/cooking-sources.md): xícara de chá = 240 mL, colher de sopa = 15 mL,
/// colher de chá = 5 mL.
const int cupMl = 240;

/// Unidade culinária. Unidades de volume têm [ml] fixo; a unidade de massa
/// (gramas) depende do ingrediente e por isso tem [ml] nulo.
class CookingUnit {
  const CookingUnit({
    required this.id,
    required this.name,
    required this.symbol,
    this.ml,
  });

  final String id;
  final String name;
  final String symbol;

  /// Volume em mL de 1 unidade; nulo para gramas.
  final int? ml;

  bool get isMass => ml == null;

  String get label => '$name ($symbol)';
}

const cookingUnits = <CookingUnit>[
  CookingUnit(id: 'cup', name: 'Xícara', symbol: 'xíc.', ml: cupMl),
  CookingUnit(id: 'tbsp', name: 'Colher de sopa', symbol: 'c. sopa', ml: 15),
  CookingUnit(id: 'tsp', name: 'Colher de chá', symbol: 'c. chá', ml: 5),
  CookingUnit(id: 'ml', name: 'Mililitro', symbol: 'mL', ml: 1),
  CookingUnit(id: 'l', name: 'Litro', symbol: 'L', ml: 1000),
  CookingUnit(id: 'g', name: 'Grama', symbol: 'g'),
];

/// Ingrediente com massa aproximada de uma xícara de 240 mL.
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.gramsPerCup,
  });

  final String id;
  final String name;

  /// Gramas em 1 xícara (240 mL), valor arredondado e aproximado.
  final int gramsPerCup;

  Decimal get gramsPerCupDecimal => Decimal.fromInt(gramsPerCup);
}

/// Valores arredondados a partir de várias fontes; ver
/// docs/cooking-sources.md para faixas e critérios.
const ingredients = <Ingredient>[
  Ingredient(id: 'water', name: 'Água', gramsPerCup: 240),
  Ingredient(id: 'milk', name: 'Leite', gramsPerCup: 245),
  Ingredient(id: 'sugar', name: 'Açúcar refinado', gramsPerCup: 200),
  Ingredient(id: 'brown_sugar', name: 'Açúcar mascavo', gramsPerCup: 215),
  Ingredient(id: 'wheat_flour', name: 'Farinha de trigo', gramsPerCup: 120),
  Ingredient(id: 'cornstarch', name: 'Amido de milho', gramsPerCup: 120),
  Ingredient(id: 'rice', name: 'Arroz cru', gramsPerCup: 200),
  Ingredient(id: 'butter', name: 'Manteiga', gramsPerCup: 230),
  Ingredient(id: 'oil', name: 'Óleo', gramsPerCup: 220),
  Ingredient(id: 'honey', name: 'Mel', gramsPerCup: 340),
  Ingredient(id: 'salt', name: 'Sal', gramsPerCup: 290),
  Ingredient(id: 'cocoa', name: 'Cacau em pó', gramsPerCup: 90),
];

const cookingDisclaimer =
    'Valores aproximados: variam com a marca e com a forma de medir o '
    'ingrediente (peneirado, compactado, medida rasa). Para receitas '
    'delicadas, prefira pesar na balança.';
