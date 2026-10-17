import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/core/widgets/tool_scaffold.dart';
import 'package:tqvp/features/calculators/fuel/fuel_screen.dart';

Widget wrap(Widget child) => MaterialApp(
  locale: const Locale('pt', 'BR'),
  supportedLocales: const [Locale('pt', 'BR')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

Future<void> type(WidgetTester t, String label, String text) async {
  final f = find.widgetWithText(TextField, label);
  await t.ensureVisible(f);
  await t.enterText(f, text);
  await t.pump();
}

Future<void> tapText(WidgetTester t, String text) async {
  final f = find.text(text);
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pump();
}

void main() {
  testWidgets('álcool × gasolina', (t) async {
    await t.pumpWidget(wrap(const FuelScreen()));
    expect(find.textContaining('Informe o preço do etanol'), findsOneWidget);
    await type(t, 'Preço do etanol', '4,00');
    await type(t, 'Preço da gasolina', '6,00');
    expect(find.text('Abasteça com etanol'), findsOneWidget);
    expect(find.text('66,7%'), findsOneWidget);
    expect(find.textContaining('aproximação'), findsOneWidget);

    await type(t, 'Preço do etanol', '5');
    expect(find.text('Abasteça com gasolina'), findsOneWidget);

    await type(t, 'Preço da gasolina', '0');
    expect(find.byType(ErrorBanner), findsOneWidget);
    await type(t, 'Preço da gasolina', 'abc');
    expect(find.textContaining('número válido'), findsOneWidget);
    await type(t, 'Preço da gasolina', '6');

    await tapText(t, 'Ajustes avançados');
    await type(t, 'Limite', '85');
    expect(find.text('Abasteça com etanol'), findsOneWidget);
    await type(t, 'Consumo com etanol (opcional)', '7');
    expect(find.textContaining('dos dois combustíveis'), findsOneWidget);
    await type(t, 'Consumo com gasolina (opcional)', '10');
    expect(find.text('Abasteça com gasolina'), findsOneWidget);
    expect(find.textContaining('por km'), findsOneWidget);
  });

  testWidgets('consumo', (t) async {
    await t.pumpWidget(wrap(const FuelScreen()));
    await tapText(t, 'Consumo');
    expect(find.textContaining('Informe a distância'), findsOneWidget);
    await type(t, 'Distância', '300');
    await type(t, 'Litros', '25');
    expect(find.text('12 km/l'), findsOneWidget);
    await type(t, 'Litros', '0');
    expect(find.textContaining('maiores que zero'), findsOneWidget);
  });

  testWidgets('custo de viagem com ida e volta', (t) async {
    await t.pumpWidget(wrap(const FuelScreen()));
    await tapText(t, 'Custo de viagem');
    await type(t, 'Distância', '300');
    await type(t, 'Consumo', '12');
    await type(t, 'Preço do litro', '6');
    expect(find.text('25 l'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Custo total: R\$\s150,00')),
      findsOneWidget,
    );
    await tapText(t, 'Ida e volta');
    expect(find.text('50 l'), findsOneWidget);
    await type(t, 'Consumo', '0');
    expect(find.byType(ErrorBanner), findsOneWidget);
  });
}
