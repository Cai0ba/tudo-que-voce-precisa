import 'dart:math' as math;

import '../shared/calc_support.dart';

class AgeResult {
  const AgeResult({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
  });
  final int years;
  final int months;
  final int days;
  final int totalDays;
}

/// Domínio puro de idade. Usa só ano/mês/dia (sem hora nem fuso).
/// Quem nasceu em 29/fev faz aniversário em 1º/mar nos anos não bissextos.
abstract final class AgeCalculator {
  static AgeResult calculate({
    required DateTime birth,
    required DateTime today,
  }) {
    final b = _date(birth);
    final t = _date(today);
    if (b.isAfter(t)) {
      throw const CalcException('A data de nascimento não pode ser no futuro.');
    }
    var years = t.year - b.year;
    if (_anniversary(b, b.year + years).isAfter(t)) years--;
    final base = _anniversary(b, b.year + years);

    var months = 0;
    for (var m = 11; m > 0; m--) {
      if (!_addMonths(base, m).isAfter(t)) {
        months = m;
        break;
      }
    }
    final days = t.difference(_addMonths(base, months)).inDays;
    return AgeResult(
      years: years,
      months: months,
      days: days,
      totalDays: t.difference(b).inDays,
    );
  }

  static DateTime _date(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  static int _daysInMonth(int y, int m) => DateTime.utc(y, m + 1, 0).day;

  static DateTime _anniversary(DateTime b, int year) {
    if (b.month == 2 && b.day == 29 && !_isLeap(year)) {
      return DateTime.utc(year, 3, 1);
    }
    return DateTime.utc(year, b.month, b.day);
  }

  /// Soma meses limitando o dia ao fim do mês (31/jan + 1 = 28 ou 29/fev).
  static DateTime _addMonths(DateTime d, int months) {
    final total = d.year * 12 + (d.month - 1) + months;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    return DateTime.utc(y, m, math.min(d.day, _daysInMonth(y, m)));
  }
}
