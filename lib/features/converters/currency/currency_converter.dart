import 'package:decimal/decimal.dart';

import 'currency_models.dart';

/// Casas decimais usadas ao materializar divisões não exatas.
const _scale = 12;

/// Taxa cruzada 1 [from] = x [to], a partir de taxas relativas ao BRL.
/// Retorna null se alguma moeda não existir nas taxas.
Decimal? crossRate(Map<String, Decimal> rates, String from, String to) {
  final f = rates[from];
  final t = rates[to];
  if (f == null || t == null || f <= Decimal.zero) return null;
  return (t / f).toDecimal(scaleOnInfinitePrecision: _scale);
}

/// Converte [amount] de [from] para [to]. Null se faltar taxa.
ConversionResult? convertCurrency(
  Decimal amount,
  String from,
  String to,
  Map<String, Decimal> rates,
) {
  final f = rates[from];
  final t = rates[to];
  if (f == null || t == null || f <= Decimal.zero) return null;
  final rate = (t / f).toDecimal(scaleOnInfinitePrecision: _scale);
  // Usa a razão exata para o valor, evitando erro de arredondamento da taxa.
  final value = (amount * t / f).toDecimal(scaleOnInfinitePrecision: _scale);
  return ConversionResult(rate: rate, amount: value);
}

/// Data de referência mais antiga entre as moedas usadas (AAAA-MM-DD).
String? referenceDate(ExchangeRates r, String from, String to) {
  final ds = [r.dates[from], r.dates[to]].whereType<String>().toList()..sort();
  return ds.isEmpty ? null : ds.first;
}

/// Indica se as taxas têm mais de 24 h desde a obtenção.
bool isStale(ExchangeRates r, DateTime now) =>
    now.difference(r.fetchedAt) > const Duration(hours: 24);
