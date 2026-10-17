import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tqvp/core/storage/preferences.dart';
import 'package:tqvp/features/converters/currency/currency_converter.dart';
import 'package:tqvp/features/converters/currency/currency_models.dart';
import 'package:tqvp/features/converters/currency/currency_repository.dart';
import 'package:tqvp/features/converters/currency/currency_screen.dart';

Decimal d(String s) => Decimal.parse(s);

final _body = jsonEncode([
  {'date': '2026-10-16', 'base': 'BRL', 'quote': 'USD', 'rate': 0.2},
  {'date': '2026-10-15', 'base': 'BRL', 'quote': 'EUR', 'rate': 0.18},
  {'date': '2026-10-16', 'base': 'BRL', 'quote': 'JPY', 'rate': 31.25},
]);

MockClient okClient() => MockClient((_) async => http.Response(_body, 200));
MockClient failClient() =>
    MockClient((_) async => throw http.ClientException('x'));

Future<CurrencyRepository> repo(
  http.Client c, {
  Map<String, Object> prefs = const {},
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  return CurrencyRepository(
    client: c,
    prefs: p,
    now: () => now ?? DateTime.utc(2026, 10, 16, 12),
  );
}

void main() {
  group('domínio', () {
    final rates = {'BRL': d('1'), 'USD': d('0.2'), 'EUR': d('0.16')};

    test('BRL para USD', () {
      final r = convertCurrency(d('100'), 'BRL', 'USD', rates)!;
      expect(r.amount, d('20'));
      expect(r.rate, d('0.2'));
    });

    test('USD para BRL e taxa cruzada USD para EUR', () {
      expect(convertCurrency(d('10'), 'USD', 'BRL', rates)!.amount, d('50'));
      expect(crossRate(rates, 'USD', 'EUR'), d('0.8'));
    });

    test('mesma moeda e moeda ausente', () {
      expect(convertCurrency(d('7.5'), 'EUR', 'EUR', rates)!.amount, d('7.5'));
      expect(convertCurrency(d('1'), 'EUR', 'XXX', rates), isNull);
    });

    test('desatualizado após 24h', () {
      final r = ExchangeRates(
        rates: rates,
        dates: {},
        fetchedAt: DateTime.utc(2026, 10, 15, 10),
      );
      expect(isStale(r, DateTime.utc(2026, 10, 16, 9)), isFalse);
      expect(isStale(r, DateTime.utc(2026, 10, 16, 11)), isTrue);
    });
  });

  group('repositório', () {
    test('sucesso grava cache e lê datas', () async {
      final r = await repo(okClient());
      final load = await r.load();
      expect(load.fromCache, isFalse);
      expect(load.rates!.rates['USD'], d('0.2'));
      expect(load.rates!.rates['BRL'], d('1'));
      expect(load.rates!.dates['EUR'], '2026-10-15');
      expect(r.readCache()!.rates['JPY'], d('31.25'));
    });

    test('falha com cache usa cache', () async {
      final ok = await repo(okClient());
      await ok.load();
      final raw = ok.prefs.getString(currencyCacheKey)!;
      final r = await repo(failClient(), prefs: {currencyCacheKey: raw});
      final load = await r.load();
      expect(load.fromCache, isTrue);
      expect(load.error, isNotNull);
      expect(load.rates!.rates['USD'], d('0.2'));
    });

    test('falha sem cache', () async {
      final r = await repo(failClient());
      final load = await r.load();
      expect(load.rates, isNull);
      expect(load.error, isNotNull);
    });

    test('HTTP 500 e corpo inválido tratados como falha', () async {
      expect(
        (await (await repo(
          MockClient((_) async => http.Response('', 500)),
        )).load()).rates,
        isNull,
      );
      expect(
        (await (await repo(
          MockClient((_) async => http.Response('{}', 200)),
        )).load()).rates,
        isNull,
      );
    });
  });

  group('tela', () {
    Future<void> pump(
      WidgetTester tester,
      http.Client c,
      Map<String, Object> prefs,
    ) async {
      SharedPreferences.setMockInitialValues(prefs);
      final p = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(p),
            currencyHttpClientProvider.overrideWithValue(c),
          ],
          child: const MaterialApp(home: CurrencyScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sucesso mostra resultado, taxa e fonte', (tester) async {
      await pump(tester, okClient(), {});
      // 1 USD -> BRL = 5 (1 / 0.2)
      expect(find.textContaining('5,00 BRL'), findsOneWidget);
      expect(
        find.textContaining('Taxa aplicada: 1 USD = 5 BRL'),
        findsOneWidget,
      );
      expect(find.textContaining('Fonte:'), findsOneWidget);
      expect(find.textContaining('Atualizado em'), findsOneWidget);
    });

    testWidgets('inverter troca as moedas', (tester) async {
      await pump(tester, okClient(), {});
      await tester.tap(find.byTooltip('Inverter moedas'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Taxa aplicada: 1 BRL = 0,2 USD'),
        findsOneWidget,
      );
    });

    testWidgets('falha sem cache mostra Tentar novamente', (tester) async {
      var fail = true;
      final c = MockClient((_) async {
        if (fail) throw http.ClientException('x');
        return http.Response(_body, 200);
      });
      await pump(tester, c, {});
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.textContaining('Taxa aplicada'), findsNothing);
      fail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Taxa aplicada'), findsOneWidget);
    });

    testWidgets('falha com cache antigo mostra desatualizada', (tester) async {
      final cached = ExchangeRates(
        rates: {'BRL': d('1'), 'USD': d('0.25')},
        dates: {'USD': '2020-01-01'},
        fetchedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      await pump(tester, failClient(), {
        currencyCacheKey: jsonEncode(cached.toJson()),
      });
      expect(find.textContaining('desatualizada'), findsOneWidget);
      expect(
        find.textContaining('Taxa aplicada: 1 USD = 4 BRL'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}
