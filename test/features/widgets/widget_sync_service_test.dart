import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/features/widgets/widget_link.dart';
import 'package:tqvp/features/widgets/widget_sync_service.dart';

class _FakeGateway implements WidgetGateway {
  final saved = <String, Object?>{};
  int refreshes = 0;
  bool fail = false;

  @override
  Future<void> save(String key, Object? value) async {
    if (fail) throw StateError('boom');
    saved[key] = value;
  }

  @override
  Future<void> refresh() async => refreshes++;
}

void main() {
  test('payload usa nome, id e categoria do catálogo', () {
    final p = buildWidgetPayload(['bmi', 'discount']);
    expect(p['fav_count'], 2);
    expect(p['fav_0_id'], 'bmi');
    expect(p['fav_0_name'], 'IMC');
    expect(p['fav_0_cat'], 'calculators');
    expect(p['fav_1_id'], 'discount');
    expect(p['fav_2_id'], isNull);
  });

  test('payload limita a 4 e ignora ids desconhecidos', () {
    final p = buildWidgetPayload([
      'nao_existe',
      'bmi',
      'age',
      'discount',
      'percentage',
      'currency',
    ]);
    expect(p['fav_count'], 4);
    expect(p['fav_0_id'], 'bmi');
    expect(p['fav_3_id'], 'percentage');
  });

  test('sem favoritos zera tudo', () {
    final p = buildWidgetPayload([]);
    expect(p['fav_count'], 0);
    expect(p['fav_0_name'], isNull);
  });

  test('sync grava payload e atualiza o widget', () async {
    final g = _FakeGateway();
    await WidgetSyncService(g).sync(['bmi']);
    expect(g.saved['fav_0_name'], 'IMC');
    expect(g.refreshes, 1);
  });

  test('sync não lança quando a plataforma falha', () async {
    final g = _FakeGateway()..fail = true;
    await WidgetSyncService(g).sync(['bmi']);
    expect(g.refreshes, 0);
  });

  test('deep links do widget viram rotas', () {
    expect(routeForWidgetUri(Uri.parse('tqvp://tool/bmi')), '/tool/bmi');
    expect(routeForWidgetUri(Uri.parse('tqvp://home')), '/');
    expect(routeForWidgetUri(Uri.parse('tqvp://tool/xxx')), isNull);
    expect(routeForWidgetUri(Uri.parse('http://tool/bmi')), isNull);
    expect(routeForWidgetUri(null), isNull);
  });
}
