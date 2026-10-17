import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tqvp/core/storage/preferences.dart';
import 'package:tqvp/features/utilities/countdown/countdown.dart';
import 'package:tqvp/features/utilities/countdown/countdown_screen.dart';

void main() {
  test('futuro', () {
    final r = computeRemaining(
      DateTime(2024, 1, 2, 3, 4, 5),
      DateTime(2024, 1, 1),
    );
    expect(
      [r.days, r.hours, r.minutes, r.seconds, r.past],
      [1, 3, 4, 5, false],
    );
  });

  test('passado', () {
    final r = computeRemaining(
      DateTime(2024, 1, 1),
      DateTime(2024, 1, 1, 0, 1, 1),
    );
    expect(r.past, isTrue);
    expect(formatRemaining(r), 'já passou há 0 d 0 h 1 min 1 s');
  });

  test('persistência título+data', () {
    final s = SavedCountdown('Viagem | férias', DateTime(2030, 5, 6, 7, 8));
    final back = SavedCountdown.decode(s.encode())!;
    expect(back.title, s.title);
    expect(back.target, s.target);
    expect(SavedCountdown.decode('lixo'), isNull);
  });

  testWidgets('tick de 1s atualiza e dispose cancela o timer', (tester) async {
    final target = DateTime(2030, 1, 1, 0, 0, 10);
    SharedPreferences.setMockInitialValues({
      'countdown.saved': SavedCountdown('Meta', target).encode(),
    });
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2030, 1, 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          countdownClockProvider.overrideWithValue(() => now),
        ],
        child: const MaterialApp(home: CountdownScreen()),
      ),
    );
    expect(find.textContaining('0 d 0 h 0 min 10 s'), findsOneWidget);
    now = DateTime(2030, 1, 1, 0, 0, 4);
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('0 d 0 h 0 min 6 s'), findsOneWidget);

    // Pausa em background: relógio muda mas o texto não.
    for (final st in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    now = DateTime(2030, 1, 1, 0, 0, 8);
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('0 d 0 h 0 min 6 s'), findsOneWidget);
    for (final st in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await tester.pump();
    expect(find.textContaining('0 d 0 h 0 min 2 s'), findsOneWidget);

    now = DateTime(2030, 1, 1, 0, 0, 12);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.textContaining('já passou há 0 d 0 h 0 min 2 s'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    expect(tester.hasRunningAnimations, isFalse);
    // Falha se restar Timer pendente ao final do teste.
  });
}
