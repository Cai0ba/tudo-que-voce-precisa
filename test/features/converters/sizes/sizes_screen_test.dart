import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tqvp/features/converters/cooking/cooking_screen.dart';
import 'package:tqvp/features/converters/sizes/sizes_screen.dart';

Future<void> pump(WidgetTester tester, Widget screen) async {
  await initializeDateFormatting('pt_BR');
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: screen,
    ),
  );
}

void main() {
  testWidgets('tamanhos: roupas e calçados sem overflow', (tester) async {
    await pump(tester, const SizesScreen());
    await tester.tap(find.text('Roupas'));
    await tester.pump();
    await tester.tap(find.text('Masculino'));
    await tester.pump();
    await tester.ensureVisible(find.text('Parte de baixo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parte de baixo'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.textContaining('variam por marca'),
      300,
    );
    expect(find.textContaining('variam por marca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('culinária: aviso e entrada sem overflow', (tester) async {
    await pump(tester, const CookingScreen());
    await tester.enterText(find.byType(TextField), '2');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.textContaining('variam com a marca'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('variam com a marca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
