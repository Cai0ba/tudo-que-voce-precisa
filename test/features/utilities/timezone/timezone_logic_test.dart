import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/features/utilities/timezone/timezone_logic.dart';

const _sp = 'America/Sao_Paulo';

void main() {
  setUpAll(ensureTimeZones);

  test('Lisboa no inverno: +3 h de São Paulo, sem verão', () async {
    await ensureTimeZones();
    final r = convertInstant(
      DateTime.utc(2026, 1, 15, 18),
      'Europe/Lisbon',
      _sp,
    );
    expect(formatClock(r.local), '18:00');
    expect(r.diff, const Duration(hours: 3));
    expect(formatDiff(r.diff), '+3 h');
    expect(r.isDst, isFalse);
    expect(r.dayDelta, 0);
  });

  test('horário de verão EUA começa antes do europeu', () async {
    await ensureTimeZones();
    // 10/03/2026: EUA já em verão (desde 8/3); Europa ainda não (29/3).
    final mar = DateTime.utc(2026, 3, 10, 12);
    final ny = convertInstant(mar, 'America/New_York', 'Europe/London');
    expect(ny.isDst, isTrue);
    expect(ny.offset, const Duration(hours: -4));
    expect(ny.diff, const Duration(hours: -4));
    expect(convertInstant(mar, 'Europe/London', _sp).isDst, isFalse);
    // Em janeiro a diferença Londres-Nova York é de 5 h.
    final jan = DateTime.utc(2026, 1, 10, 12);
    expect(
      convertInstant(jan, 'America/New_York', 'Europe/London').diff,
      const Duration(hours: -5),
    );
    // Em julho Londres está em verão.
    final jul = DateTime.utc(2026, 7, 10, 12);
    final lon = convertInstant(jul, 'Europe/London', 'Europe/London');
    expect(lon.isDst, isTrue);
    expect(formatClock(lon.local), '13:00');
  });

  test('virada do horário de verão europeu (29/03/2026 01:00 UTC)', () async {
    await ensureTimeZones();
    final before = convertInstant(
      DateTime.utc(2026, 3, 29, 0, 59),
      'Europe/Paris',
      'Europe/Paris',
    );
    final after = convertInstant(
      DateTime.utc(2026, 3, 29, 1),
      'Europe/Paris',
      'Europe/Paris',
    );
    expect(formatClock(before.local), '01:59');
    expect(formatClock(after.local), '03:00');
    expect(before.isDst, isFalse);
    expect(after.isDst, isTrue);
  });

  test('hemisfério sul: Sydney em verão em janeiro', () async {
    await ensureTimeZones();
    final r = convertInstant(
      DateTime.utc(2026, 1, 15, 18),
      'Australia/Sydney',
      _sp,
    );
    expect(r.isDst, isTrue);
    expect(r.diff, const Duration(hours: 14));
    expect(r.dayDelta, 1);
    expect(dayLabel(r.dayDelta), 'amanhã');
  });

  test('offsets de 30 e 45 minutos', () async {
    await ensureTimeZones();
    final i = DateTime.utc(2026, 1, 15, 18);
    final kol = convertInstant(i, 'Asia/Kolkata', _sp);
    expect(formatClock(kol.local), '23:30');
    expect(formatDiff(kol.diff), '+8 h 30 min');
    expect(formatUtcOffset(kol.offset), 'UTC+5:30');
    final kat = convertInstant(i, 'Asia/Kathmandu', _sp);
    expect(formatClock(kat.local), '23:45');
    expect(formatDiff(kat.diff), '+8 h 45 min');
  });

  test('ontem, diferenças negativas e Miami', () async {
    await ensureTimeZones();
    // 01:00 em São Paulo = 04:00 UTC; Los Angeles (UTC-8) = 20:00 do dia anterior.
    final r = convertInstant(
      DateTime.utc(2026, 1, 15, 4),
      'America/Los_Angeles',
      _sp,
    );
    expect(r.dayDelta, -1);
    expect(dayLabel(r.dayDelta), 'ontem');
    expect(formatDiff(r.diff), '-5 h');
    final mia = convertInstant(
      DateTime.utc(2026, 1, 15, 4),
      'America/Miami',
      _sp,
    );
    expect(formatClock(mia.local), '23:00');
    expect(formatDiff(Duration.zero), 'mesmo horário');
  });

  test('hora de parede da origem <-> instante', () async {
    await ensureTimeZones();
    final i = instantFromWallClock('Europe/Lisbon', DateTime(2026, 7, 1, 12));
    expect(i, DateTime.utc(2026, 7, 1, 11));
    expect(wallClockOf(i, 'Europe/Lisbon'), DateTime(2026, 7, 1, 12));
  });

  test('catálogo: ids únicos e todos existem na base', () async {
    await ensureTimeZones();
    expect(cityCatalog.map((c) => c.id).toSet().length, cityCatalog.length);
    for (final c in cityCatalog) {
      expect(
        () => convertInstant(DateTime.utc(2026), c.id, _sp),
        returnsNormally,
        reason: c.id,
      );
    }
  });

  test('busca sem acento/maiúsculas e com exclusão', () {
    expect(searchCities('toquio').map((c) => c.name), ['Tóquio']);
    expect(searchCities('SAO').first.name, 'São Paulo');
    expect(searchCities('brasil').length, greaterThan(3));
    expect(searchCities('xyz'), isEmpty);
    expect(searchCities('londres', exclude: ['Europe/London']), isEmpty);
  });
}
