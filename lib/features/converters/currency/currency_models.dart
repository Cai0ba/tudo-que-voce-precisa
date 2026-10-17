import 'package:decimal/decimal.dart';

/// Nome da fonte exibida ao usuário.
const currencySourceName = 'Frankfurter (bancos centrais)';

/// Cotações em relação ao BRL (BRL = 1) numa data/hora de obtenção.
class ExchangeRates {
  ExchangeRates({
    required Map<String, Decimal> rates,
    required Map<String, String> dates,
    required this.fetchedAt,
    this.source = currencySourceName,
  }) : rates = Map.unmodifiable(rates),
       dates = Map.unmodifiable(dates);

  /// Valor de 1 BRL em cada moeda (inclui `BRL: 1`).
  final Map<String, Decimal> rates;

  /// Data de referência (AAAA-MM-DD) de cada moeda, quando informada.
  final Map<String, String> dates;

  /// Quando o app obteve estas taxas da fonte.
  final DateTime fetchedAt;
  final String source;

  Map<String, Object?> toJson() => {
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'source': source,
    'rates': rates.map((k, v) => MapEntry(k, v.toString())),
    'dates': dates,
  };

  /// Retorna null se o JSON for inválido.
  static ExchangeRates? fromJson(Object? json) {
    try {
      if (json is! Map) return null;
      final fetched = DateTime.tryParse('${json['fetchedAt']}');
      final rawRates = json['rates'];
      if (fetched == null || rawRates is! Map) return null;
      final rates = <String, Decimal>{};
      for (final e in rawRates.entries) {
        final d = Decimal.tryParse('${e.value}');
        if (d != null && d > Decimal.zero) rates['${e.key}'] = d;
      }
      if (!rates.containsKey('BRL') || rates.length < 2) return null;
      final rawDates = json['dates'];
      final dates = <String, String>{
        if (rawDates is Map)
          for (final e in rawDates.entries) '${e.key}': '${e.value}',
      };
      return ExchangeRates(
        rates: rates,
        dates: dates,
        fetchedAt: fetched,
        source: '${json['source'] ?? currencySourceName}',
      );
    } on Object {
      return null;
    }
  }
}

/// Resultado de uma conversão.
class ConversionResult {
  const ConversionResult({required this.rate, required this.amount});

  /// Taxa aplicada (1 origem = [rate] destino).
  final Decimal rate;

  /// Valor convertido.
  final Decimal amount;
}
