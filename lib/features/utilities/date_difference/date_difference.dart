/// Domínio puro: diferença de calendário entre duas datas (só ano/mês/dia).
class DateDifference {
  const DateDifference({
    required this.start,
    required this.end,
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.inverted,
  });

  /// Data menor (início efetivo).
  final DateTime start;

  /// Data maior (fim efetivo).
  final DateTime end;
  final int years;
  final int months;
  final int days;

  /// Total de dias (sempre >= 0).
  final int totalDays;

  /// Verdadeiro se as datas informadas estavam em ordem inversa.
  final bool inverted;
}

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

bool isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

/// Calcula a diferença entre [a] e [b]. Se [a] > [b], troca a ordem e marca
/// `inverted`. Ignora hora e fuso.
DateDifference dateDifference(DateTime a, DateTime b) {
  var s = _dateOnly(a);
  var e = _dateOnly(b);
  final inverted = s.isAfter(e);
  if (inverted) {
    final t = s;
    s = e;
    e = t;
  }
  var totalMonths = (e.year - s.year) * 12 + (e.month - s.month);
  if (e.day < s.day) totalMonths--;
  // Âncora: início + totalMonths, com o dia limitado ao fim do mês.
  final idx = s.year * 12 + (s.month - 1) + totalMonths;
  final ay = idx ~/ 12;
  final am = idx % 12 + 1;
  final ad = s.day < daysInMonth(ay, am) ? s.day : daysInMonth(ay, am);
  final anchor = DateTime.utc(ay, am, ad);
  return DateDifference(
    start: s,
    end: e,
    years: totalMonths ~/ 12,
    months: totalMonths % 12,
    days: e.difference(anchor).inDays,
    totalDays: e.difference(s).inDays,
    inverted: inverted,
  );
}
