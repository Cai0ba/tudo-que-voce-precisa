import 'package:decimal/decimal.dart';

import '../shared/calc_support.dart';

class DiscountResult {
  const DiscountResult({required this.saved, required this.finalPrice});
  final Decimal saved;
  final Decimal finalPrice;
}

/// Domínio puro de desconto. Valores em reais, 2 casas, meio para cima.
/// A economia é arredondada e o preço final é preço - economia, de modo que
/// os dois sempre somam o preço original.
abstract final class DiscountCalculator {
  static DiscountResult apply(Decimal price, Decimal percent) {
    requireNonNegative(price, 'preço');
    requireNonNegative(percent, 'desconto');
    if (percent > Decimal.fromInt(100)) {
      throw const CalcException('O desconto não pode passar de 100%.');
    }
    final saved = roundTo(divide(price * percent, Decimal.fromInt(100)), 2);
    return DiscountResult(saved: saved, finalPrice: roundTo(price, 2) - saved);
  }
}
