import 'package:decimal/decimal.dart';

/// Unidade de medida com fator exato para a unidade-base da grandeza
/// (ex.: comprimento em metros). O fator é ignorado por conversores que
/// usam fórmula própria (temperatura).
class ConversionUnit {
  const ConversionUnit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.factor,
  });

  final String id;
  final String name;
  final String symbol;
  final Decimal factor;

  /// Texto exibido nos seletores, ex.: "Polegada (in)".
  String get label => '$name ($symbol)';
}

/// Atalho para declarar fatores exatos a partir de texto decimal.
Decimal dec(String s) => Decimal.parse(s);

/// Conversão linear exata: [value] em [from] para [to], via unidade-base.
/// Usa aritmética racional; só arredonda (trunca) em 20 casas se a razão
/// não tiver representação decimal finita.
Decimal convertLinear(Decimal value, ConversionUnit from, ConversionUnit to) {
  if (from.id == to.id) return value;
  return (value * from.factor / to.factor).toDecimal(
    scaleOnInfinitePrecision: 20,
  );
}
