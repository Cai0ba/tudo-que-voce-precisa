import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tqvp/core/storage/preferences.dart';
import 'package:tqvp/features/utilities/timezone/timezone_screen.dart';

Future<SharedPreferences> _pump(
  WidgetTester tester,
  DateTime Function() clock, {
  Map<String, Object> initial = const {},
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        timezoneClockProvider.overrideWithValue(clock),
      ],
      child: const MaterialApp(home: TimezoneScreen()),
    ),
  );
  // A base de fusos carrega de forma assíncrona.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
  return prefs;
}

void main() {
  // 15/01/2026 15:00 em São Paulo (UTC-3) = 18:00 UTC.
  var now = DateTime.utc(2026, 1, 15, 18);

  testWidgets('mostra origem e cidades padrão com diferença', (tester) async {
    await _pump(tester, () => now);
    expect(find.textContaining('São Paulo'), findsWidgets);
    expect(find.textContaining('15/01/2026 15:00'), findsOneWidget);
    expect(find.text('Lisboa'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(find.textContaining('+3 h'), findsOneWidget);
    expect(find.text('Nova York'), findsOneWidget);
    expect(find.textContaining('-2 h'), findsOneWidget);
  });

  testWidgets('adicionar e remover cidade persiste só ids', (tester) async {
    final prefs = await _pump(tester, () => now);
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'toquio');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tóquio'));
    await tester.pumpAndSettle();
    expect(find.text('Tóquio'), findsOneWidget);
    expect(find.text('03:00'), findsOneWidget);
    expect(find.textContaining('amanhã'), findsOneWidget);
    expect(prefs.getStringList('timezone.cities'), [
      'Europe/Lisbon',
      'America/New_York',
      'Asia/Tokyo',
    ]);

    await tester.tap(find.byTooltip('Remover Lisboa'));
    await tester.pump();
    expect(find.text('Lisboa'), findsNothing);
    expect(prefs.getStringList('timezone.cities'), [
      'America/New_York',
      'Asia/Tokyo',
    ]);
  });

  testWidgets('carrega cidades salvas e mostra horário de verão', (
    tester,
  ) async {
    now = DateTime.utc(2026, 1, 15, 18);
    await _pump(
      tester,
      () => now,
      initial: {
        'timezone.cities': ['Australia/Sydney'],
      },
    );
    expect(find.text('Sydney'), findsOneWidget);
    expect(find.text('Horário de verão'), findsOneWidget);
    expect(find.text('Lisboa'), findsNothing);
  });

  testWidgets('timer de 1 min atualiza; pausa em background; dispose cancela', (
    tester,
  ) async {
    now = DateTime.utc(2026, 1, 15, 18);
    await _pump(tester, () => now);
    expect(find.text('18:00'), findsOneWidget);
    now = DateTime.utc(2026, 1, 15, 18, 5);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('18:05'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime.utc(2026, 1, 15, 19);
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('18:05'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('19:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    // Sem timers pendentes após dispose (o framework falha se houver).
  });

  testWidgets('320x568 com fonte 200%: sem overflow e alvos de toque ok', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({
      'timezone.cities': ['Asia/Kathmandu', 'Australia/Sydney'],
    });
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          timezoneClockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const TimezoneScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.scrollUntilVisible(find.text('Katmandu'), 200);
    await tester.scrollUntilVisible(find.text('Sydney'), 200);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
