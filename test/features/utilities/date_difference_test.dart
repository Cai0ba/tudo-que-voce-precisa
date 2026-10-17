import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/features/utilities/date_difference/date_difference.dart';
import 'package:tqvp/features/utilities/date_difference/date_difference_screen.dart';

void main() {
  DateDifference d(DateTime a, DateTime b) => dateDifference(a, b);

  test('mesmo dia', () {
    final r = d(DateTime(2024, 5, 5), DateTime(2024, 5, 5));
    expect([r.years, r.months, r.days, r.totalDays], [0, 0, 0, 0]);
    expect(r.inverted, isFalse);
  });

  test('fim de mês: 31/01 a 01/03 em ano comum e bissexto', () {
    var r = d(DateTime(2023, 1, 31), DateTime(2023, 3, 1));
    expect([r.years, r.months, r.days, r.totalDays], [0, 1, 1, 29]);
    r = d(DateTime(2024, 1, 31), DateTime(2024, 3, 1));
    expect([r.years, r.months, r.days, r.totalDays], [0, 1, 1, 30]);
  });

  test('bissexto', () {
    expect(isLeapYear(2000), isTrue);
    expect(isLeapYear(1900), isFalse);
    final r = d(DateTime(2024, 2, 29), DateTime(2025, 2, 28));
    expect([r.years, r.months, r.days, r.totalDays], [0, 11, 30, 365]);
    final r2 = d(DateTime(2020, 2, 29), DateTime(2024, 2, 29));
    expect([r2.years, r2.months, r2.days, r2.totalDays], [4, 0, 0, 1461]);
  });

  test('anos meses dias', () {
    final r = d(DateTime(2000, 1, 15), DateTime(2024, 3, 20));
    expect([r.years, r.months, r.days], [24, 2, 5]);
  });

  test('ordem invertida dá o mesmo resultado e marca inverted', () {
    final a = d(DateTime(2024, 1, 31), DateTime(2024, 3, 1));
    final b = d(DateTime(2024, 3, 1), DateTime(2024, 1, 31));
    expect(b.inverted, isTrue);
    expect(b.start, a.start);
    expect(
      [b.years, b.months, b.days, b.totalDays],
      [a.years, a.months, a.days, a.totalDays],
    );
  });

  test('ignora hora (sem DST)', () {
    final r = d(DateTime(2024, 3, 9, 23, 59), DateTime(2024, 3, 11, 0, 1));
    expect(r.totalDays, 2);
  });

  testWidgets('tela renderiza e mostra instrução inicial', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DateDifferenceScreen()));
    expect(find.text('Data de início'), findsOneWidget);
    expect(find.textContaining('Escolha as duas datas'), findsOneWidget);
  });
}
