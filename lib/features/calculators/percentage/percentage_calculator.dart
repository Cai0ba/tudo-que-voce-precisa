import 'package:decimal/decimal.dart';

import '../shared/calc_support.dart';

final Decimal _hundred = Decimal.fromInt(100);

/// Domínio puro de porcentagem. Resultados arredondados a 2 casas
/// (meio para cima). Valores negativos são rejeitados.
abstract final class PercentageCalculator {
  /// [percent]% de [base].
  static Decimal percentOf(Decimal percent, Decimal base) {
    requireNonNegative(percent, 'porcentagem');
    requireNonNegative(base, 'valor');
    return roundTo(divide(base * percent, _hundred), 2);
  }

  /// Quanto por cento [part] representa de [total].
  static Decimal whatPercent(Decimal part, Decimal total) {
    requireNonNegative(part, 'valor X');
    requireNonNegative(total, 'valor Y');
    if (total == Decimal.zero) {
      throw const CalcException(
        'Y não pode ser zero: não dá para dividir por zero.',
      );
    }
    return roundTo(divide(part * _hundred, total), 2);
  }

  /// [value] aumentado em [percent]%.
  static Decimal increase(Decimal value, Decimal percent) {
    requireNonNegative(value, 'valor inicial');
    requireNonNegative(percent, 'porcentagem');
    return roundTo(value + divide(value * percent, _hundred), 2);
  }

  /// [value] reduzido em [percent]% (no máximo 100%).
  static Decimal decrease(Decimal value, Decimal percent) {
    requireNonNegative(value, 'valor inicial');
    requireNonNegative(percent, 'porcentagem');
    if (percent > _hundred) {
      throw const CalcException('A redução não pode passar de 100%.');
    }
    return roundTo(value - divide(value * percent, _hundred), 2);
  }
}
