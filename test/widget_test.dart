import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tqvp/app/app.dart';
import 'package:tqvp/app/router/tool_screens.dart';
import 'package:tqvp/core/storage/preferences.dart';
import 'package:tqvp/features/search/tool_search.dart';
import 'package:tqvp/features/tools/catalog.dart';

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('pt_BR');
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TqvpApp(),
  );
}

void main() {
  test('todo item do catálogo tem tela registrada e ids únicos', () {
    expect(toolCatalog.map((t) => t.id).toSet().length, toolCatalog.length);
    for (final t in toolCatalog) {
      expect(toolScreens.containsKey(t.id), isTrue, reason: t.id);
    }
  });

  test('busca encontra por termos comuns', () {
    expect(searchTools('desconto').first.id, 'discount');
    expect(searchTools('dólar').first.id, 'currency');
    expect(searchTools('dolar').first.id, 'currency');
    expect(searchTools('peso').map((t) => t.id), contains('mass'));
    expect(searchTools('quantos anos').first.id, 'age');
    expect(searchTools('xyzxyz'), isEmpty);
  });

  testWidgets('home mostra busca e favoritos persistem', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();
    expect(find.text('Tudo Que Você Precisa'), findsOneWidget);
    await tester.enterText(find.byType(SearchBar), 'desconto');
    await tester.pumpAndSettle();
    expect(find.text('Descontos'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });
}
