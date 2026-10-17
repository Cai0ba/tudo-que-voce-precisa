import 'package:decimal/decimal.dart';

import 'cooking_data.dart';

Decimal _toMl(Decimal v, CookingUnit u, Ingredient ing) {
  if (u.isMass) {
    return (v * Decimal.fromInt(cupMl) / ing.gramsPerCupDecimal).toDecimal(
      scaleOnInfinitePrecision: 20,
    );
  }
  return v * Decimal.fromInt(u.ml!);
}

Decimal _fromMl(Decimal ml, CookingUnit u, Ingredient ing) {
  if (u.isMass) {
    return (ml * ing.gramsPerCupDecimal / Decimal.fromInt(cupMl)).toDecimal(
      scaleOnInfinitePrecision: 20,
    );
  }
  return (ml / Decimal.fromInt(u.ml!)).toDecimal(scaleOnInfinitePrecision: 20);
}

/// Converte [value] de [from] para [to]. O [ingredient] só influencia
/// conversões que envolvem gramas (volume <-> massa).
Decimal convertCooking(
  Decimal value,
  CookingUnit from,
  CookingUnit to,
  Ingredient ingredient,
) {
  if (from.id == to.id) return value;
  return _fromMl(_toMl(value, from, ingredient), to, ingredient);
}
