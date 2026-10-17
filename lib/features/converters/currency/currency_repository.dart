import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import 'currency_models.dart';

const currencyApiUrl = 'https://api.frankfurter.dev/v2/rates?base=BRL';
const currencyCacheKey = 'currency.rates.v1';

/// Resultado do carregamento. Exatamente um dos casos:
/// - [fromCache] false: taxas novas da rede;
/// - [fromCache] true: rede falhou, usando cache (veja [error]);
/// - [rates] null: falha sem cache.
class CurrencyLoad {
  const CurrencyLoad({this.rates, this.fromCache = false, this.error});
  final ExchangeRates? rates;
  final bool fromCache;
  final String? error;
}

class CurrencyRepository {
  CurrencyRepository({
    required this.client,
    required this.prefs,
    this.timeout = const Duration(seconds: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final http.Client client;
  final SharedPreferences prefs;
  final Duration timeout;
  final DateTime Function() _now;

  ExchangeRates? readCache() {
    final raw = prefs.getString(currencyCacheKey);
    if (raw == null) return null;
    try {
      return ExchangeRates.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<CurrencyLoad> load() async {
    try {
      final fresh = await _fetch();
      await prefs.setString(currencyCacheKey, jsonEncode(fresh.toJson()));
      return CurrencyLoad(rates: fresh);
    } on Object catch (e) {
      final cached = readCache();
      final msg = e is TimeoutException
          ? 'A consulta demorou demais.'
          : 'Não foi possível obter as cotações.';
      return CurrencyLoad(rates: cached, fromCache: cached != null, error: msg);
    }
  }

  Future<ExchangeRates> _fetch() async {
    final res = await client.get(Uri.parse(currencyApiUrl)).timeout(timeout);
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! List) throw const FormatException('formato inesperado');
    final rates = <String, Decimal>{'BRL': Decimal.one};
    final dates = <String, String>{};
    for (final item in body) {
      if (item is! Map) continue;
      final quote = item['quote'];
      final rate = item['rate'];
      if (quote is! String || rate is! num) continue;
      final d = Decimal.tryParse(rate.toString());
      if (d == null || d <= Decimal.zero) continue;
      rates[quote] = d;
      final date = item['date'];
      if (date is String) dates[quote] = date;
    }
    if (rates.length < 2) throw const FormatException('sem cotações');
    return ExchangeRates(rates: rates, dates: dates, fetchedAt: _now());
  }
}

final currencyHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final currencyRepositoryProvider = Provider<CurrencyRepository>(
  (ref) => CurrencyRepository(
    client: ref.watch(currencyHttpClientProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  ),
);
