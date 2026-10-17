import 'package:decimal/decimal.dart';

import '../shared/calc_support.dart';

/// Domínio puro da regra de três simples direta:
/// A está para B assim como C está para X, logo X = (B × C) ÷ A.
/// Resultado arredondado a 4 casas (meio para cima).
abstract final class RuleOfThreeCalculator {
  static Decimal solve(Decimal a, Decimal b, Decimal c) {
    requireNonNegative(a, 'A');
    requireNonNegative(b, 'B');
    requireNonNegative(c, 'C');
    if (a == Decimal.zero) {
      throw const CalcException(
        'A não pode ser zero: não dá para dividir por zero.',
      );
    }
    return roundTo(divide(b * c, a), 4);
  }
}
