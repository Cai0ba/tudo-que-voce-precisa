import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Cidade da lista curada: nome em pt-BR, país e id IANA.
class City {
  const City(this.id, this.name, this.country, {String? tzId})
    : tzId = tzId ?? id;

  /// Chave persistida (id IANA; Miami usa chave própria, pois não é id IANA).
  final String id;

  /// Id IANA usado para consultar a base de fusos.
  final String tzId;
  final String name;
  final String country;
}

const defaultOriginId = 'America/Sao_Paulo';
const defaultCityIds = ['Europe/Lisbon', 'America/New_York'];

const cityCatalog = <City>[
  City('America/Sao_Paulo', 'São Paulo', 'Brasil'),
  City('America/Manaus', 'Manaus', 'Brasil'),
  City('America/Rio_Branco', 'Rio Branco', 'Brasil'),
  City('America/Noronha', 'Fernando de Noronha', 'Brasil'),
  City('America/Fortaleza', 'Fortaleza', 'Brasil'),
  City('Europe/Lisbon', 'Lisboa', 'Portugal'),
  City('Europe/London', 'Londres', 'Reino Unido'),
  City('Europe/Paris', 'Paris', 'França'),
  City('Europe/Madrid', 'Madri', 'Espanha'),
  City('Europe/Berlin', 'Berlim', 'Alemanha'),
  City('Europe/Rome', 'Roma', 'Itália'),
  City('Europe/Moscow', 'Moscou', 'Rússia'),
  City('America/New_York', 'Nova York', 'Estados Unidos'),
  City('America/Chicago', 'Chicago', 'Estados Unidos'),
  City('America/Denver', 'Denver', 'Estados Unidos'),
  City('America/Los_Angeles', 'Los Angeles', 'Estados Unidos'),
  City('America/Miami', 'Miami', 'Estados Unidos', tzId: 'America/New_York'),
  City('America/Toronto', 'Toronto', 'Canadá'),
  City('America/Mexico_City', 'Cidade do México', 'México'),
  City('America/Argentina/Buenos_Aires', 'Buenos Aires', 'Argentina'),
  City('America/Santiago', 'Santiago', 'Chile'),
  City('America/Bogota', 'Bogotá', 'Colômbia'),
  City('Africa/Cairo', 'Cairo', 'Egito'),
  City('Africa/Johannesburg', 'Joanesburgo', 'África do Sul'),
  City('Asia/Dubai', 'Dubai', 'Emirados Árabes'),
  City('Asia/Kolkata', 'Calcutá', 'Índia'),
  City('Asia/Kathmandu', 'Katmandu', 'Nepal'),
  City('Asia/Shanghai', 'Pequim', 'China'),
  City('Asia/Tokyo', 'Tóquio', 'Japão'),
  City('Asia/Seoul', 'Seul', 'Coreia do Sul'),
  City('Australia/Sydney', 'Sydney', 'Austrália'),
  City('Pacific/Auckland', 'Auckland', 'Nova Zelândia'),
];

City? cityById(String id) {
  for (final c in cityCatalog) {
    if (c.id == id) return c;
  }
  return null;
}

String _fold(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

/// Busca por nome ou país, sem acentos nem maiúsculas.
List<City> searchCities(String query, {Iterable<String> exclude = const []}) {
  final q = _fold(query.trim());
  final skip = exclude.toSet();
  return [
    for (final c in cityCatalog)
      if (!skip.contains(c.id) &&
          (q.isEmpty ||
              _fold(c.name).contains(q) ||
              _fold(c.country).contains(q)))
        c,
  ];
}

String _tzOf(String id) => cityById(id)?.tzId ?? id;

Future<void>? _init;
bool _loaded = false;

/// Carrega a base de fusos uma única vez, sem bloquear o primeiro frame.
/// Depois de carregada, devolve um futuro síncrono.
Future<void> ensureTimeZones() {
  if (_loaded) return SynchronousFuture<void>(null);
  return _init ??= Future<void>(() {
    tzdata.initializeTimeZones();
    _loaded = true;
  });
}

/// Hora de uma cidade em um instante, relativa à cidade de origem.
class ZonedTime {
  const ZonedTime({
    required this.local,
    required this.offset,
    required this.isDst,
    required this.diff,
    required this.dayDelta,
  });

  /// Hora de parede na cidade.
  final tz.TZDateTime local;
  final Duration offset;
  final bool isDst;

  /// Diferença de fuso em relação à origem (positivo = à frente).
  final Duration diff;

  /// -1 ontem, 0 hoje, 1 amanhã (data local da cidade vs. da origem).
  final int dayDelta;
}

/// Converte [instant] para o fuso de [cityId], comparando com [originId].
/// Exige a base de fusos inicializada.
ZonedTime convertInstant(DateTime instant, String cityId, String originId) {
  final ms = instant.millisecondsSinceEpoch;
  final loc = tz.getLocation(_tzOf(cityId));
  final origin = tz.getLocation(_tzOf(originId));
  final local = tz.TZDateTime.fromMillisecondsSinceEpoch(loc, ms);
  final o = tz.TZDateTime.fromMillisecondsSinceEpoch(origin, ms);
  final dayDelta = DateTime.utc(
    local.year,
    local.month,
    local.day,
  ).difference(DateTime.utc(o.year, o.month, o.day)).inDays;
  return ZonedTime(
    local: local,
    offset: local.timeZoneOffset,
    isDst: loc.timeZone(ms).isDst,
    diff: local.timeZoneOffset - o.timeZoneOffset,
    dayDelta: dayDelta,
  );
}

/// Instante correspondente à hora de parede informada na cidade [originId].
DateTime instantFromWallClock(String originId, DateTime wall) => tz.TZDateTime(
  tz.getLocation(_tzOf(originId)),
  wall.year,
  wall.month,
  wall.day,
  wall.hour,
  wall.minute,
).toUtc();

/// Hora de parede de [instant] em [cityId] (como DateTime sem fuso).
DateTime wallClockOf(DateTime instant, String cityId) {
  final l = tz.TZDateTime.fromMillisecondsSinceEpoch(
    tz.getLocation(_tzOf(cityId)),
    instant.millisecondsSinceEpoch,
  );
  return DateTime(l.year, l.month, l.day, l.hour, l.minute);
}

String _two(int n) => n.toString().padLeft(2, '0');

String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String formatDate(DateTime t) => '${_two(t.day)}/${_two(t.month)}/${t.year}';

/// '+4 h', '-3 h', '+5 h 30 min', '+5 h 45 min' ou 'mesmo horário'.
String formatDiff(Duration d) {
  if (d == Duration.zero) return 'mesmo horário';
  final sign = d.isNegative ? '-' : '+';
  final mins = d.inMinutes.abs();
  final h = mins ~/ 60;
  final m = mins % 60;
  if (m == 0) return '$sign$h h';
  if (h == 0) return '$sign$m min';
  return '$sign$h h $m min';
}

String dayLabel(int delta) => switch (delta) {
  0 => 'hoje',
  1 => 'amanhã',
  -1 => 'ontem',
  > 1 => 'em $delta dias',
  _ => 'há ${-delta} dias',
};

/// 'UTC+5:45' / 'UTC-3'.
String formatUtcOffset(Duration d) {
  final mins = d.inMinutes.abs();
  final sign = d.isNegative ? '-' : '+';
  final m = mins % 60;
  return 'UTC$sign${mins ~/ 60}${m == 0 ? '' : ':${_two(m)}'}';
}
