/// Domínio puro da contagem regressiva.
class CountdownRemaining {
  const CountdownRemaining({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.past,
  });

  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  /// Verdadeiro se o alvo já passou (valores são o tempo decorrido).
  final bool past;
}

CountdownRemaining computeRemaining(DateTime target, DateTime now) {
  final diff = target.difference(now);
  final past = diff.isNegative;
  final total = diff.abs().inSeconds;
  return CountdownRemaining(
    days: total ~/ 86400,
    hours: total % 86400 ~/ 3600,
    minutes: total % 3600 ~/ 60,
    seconds: total % 60,
    past: past,
  );
}

String formatRemaining(CountdownRemaining r) {
  final text = '${r.days} d ${r.hours} h ${r.minutes} min ${r.seconds} s';
  return r.past ? 'já passou há $text' : text;
}

/// Contagem salva: apenas título + data/hora.
class SavedCountdown {
  const SavedCountdown(this.title, this.target);
  final String title;
  final DateTime target;

  String encode() => '${target.millisecondsSinceEpoch}|$title';

  static SavedCountdown? decode(String? raw) {
    if (raw == null) return null;
    final i = raw.indexOf('|');
    if (i < 0) return null;
    final ms = int.tryParse(raw.substring(0, i));
    if (ms == null) return null;
    return SavedCountdown(
      raw.substring(i + 1),
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }
}
