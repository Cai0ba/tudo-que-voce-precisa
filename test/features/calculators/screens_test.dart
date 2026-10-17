import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/core/widgets/tool_scaffold.dart';
import 'package:tqvp/features/calculators/age/age_screen.dart';
import 'package:tqvp/features/calculators/bmi/bmi_screen.dart';
import 'package:tqvp/features/calculators/discount/discount_screen.dart';
import 'package:tqvp/features/calculators/percentage/percentage_screen.dart';
import 'package:tqvp/features/calculators/rule_of_three/rule_of_three_screen.dart';

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
  await t.enterText(find.widgetWithText(TextField, label), text);
  await t.pump();
}

Finder money(String v) => find.byWidgetPredicate(
  (w) => w is Text && RegExp('^R\\\$\\s$v\$').hasMatch(w.data ?? ''),
);

Finder result(String label) => find.bySemanticsLabel(RegExp(label));

void main() {
  testWidgets('porcentagem: X% de Y, erro e abas', (t) async {
    await t.pumpWidget(wrap(const PercentageScreen()));
    expect(find.textContaining('Preencha os dois campos'), findsOneWidget);
    await type(t, 'Porcentagem (X)', '15');
    await type(t, 'Valor (Y)', '200');
    expect(find.text('30'), findsOneWidget);

    await type(t, 'Valor (Y)', 'abc');
    expect(find.byType(ErrorBanner), findsOneWidget);

    await t.tap(find.text('Quanto %'));
    await t.pump();
    await type(t, 'Valor X', '1');
    await type(t, 'Valor Y', '0');
    expect(find.textContaining('dividir por zero'), findsOneWidget);
    await type(t, 'Valor Y', '4');
    expect(find.text('25%'), findsOneWidget);

    await t.tap(find.text('Redução'));
    await t.pump();
    await type(t, 'Valor inicial', '100');
    await type(t, 'Redução', '150');
    expect(find.text('A redução não pode passar de 100%.'), findsOneWidget);
    await type(t, 'Redução', '10');
    expect(find.text('90'), findsOneWidget);
  });

  testWidgets('desconto: resultado e erros', (t) async {
    await t.pumpWidget(wrap(const DiscountScreen()));
    await type(t, 'Preço', '200');
    await type(t, 'Desconto', '25');
    expect(money('150,00'), findsOneWidget);
    expect(money('50,00'), findsOneWidget);

    await type(t, 'Desconto', '120');
    expect(find.byType(ErrorBanner), findsOneWidget);
    await type(t, 'Preço', '-5');
    await type(t, 'Desconto', '10');
    expect(find.textContaining('negativo'), findsOneWidget);
  });

  testWidgets('regra de três: resultado e divisão por zero', (t) async {
    await t.pumpWidget(wrap(const RuleOfThreeScreen()));
    await type(t, 'A', '2');
    await type(t, 'B', '10');
    await type(t, 'C', '6');
    expect(find.text('30'), findsOneWidget);
    expect(find.textContaining('Conta:'), findsOneWidget);
    await type(t, 'A', '0');
    expect(find.textContaining('dividir por zero'), findsOneWidget);
    await type(t, 'A', 'x');
    expect(find.textContaining('número válido'), findsOneWidget);
  });

  testWidgets('IMC: cm, m, aviso e erro', (t) async {
    await t.pumpWidget(wrap(const BmiScreen()));
    expect(find.textContaining('Não é um diagnóstico'), findsOneWidget);
    await type(t, 'Peso', '70');
    await type(t, 'Altura', '175');
    expect(find.text('22,9'), findsOneWidget);
    expect(find.textContaining('Peso normal'), findsOneWidget);

    await t.tap(find.text('Metros'));
    await t.pump();
    expect(find.byType(ErrorBanner), findsOneWidget); // 175 m
    await type(t, 'Altura', '1,75');
    expect(find.text('22,9'), findsOneWidget);
    await type(t, 'Peso', '0');
    expect(find.textContaining('maior que zero'), findsOneWidget);
  });

  testWidgets('idade: escolhe data e mostra anos/meses/dias', (t) async {
    await t.pumpWidget(wrap(AgeScreen(today: DateTime(2024, 6, 15))));
    expect(find.textContaining('Escolha a data'), findsOneWidget);
    await t.tap(find.text('Escolher data de nascimento'));
    await t.pumpAndSettle();
    // Data inicial sugerida: 15/06/1994 (30 anos antes de "hoje").
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.text('15/06/1994'), findsOneWidget);
    expect(find.text('30 anos'), findsOneWidget);
    expect(find.textContaining('0 meses e 0 dias'), findsOneWidget);
  });
}
