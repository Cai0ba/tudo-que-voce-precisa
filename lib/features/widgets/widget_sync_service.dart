import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../tools/catalog.dart';
import '../tools/tool.dart';

/// Máximo de atalhos exibidos no widget nativo.
const int maxWidgetFavorites = 4;

/// Nome (simples) do AppWidgetProvider Kotlin em br.com.tqvp.tqvp.
const String favoritesWidgetProviderName = 'FavoritesWidgetProvider';

/// Porta para a plataforma: permite testar o serviço sem canais nativos.
abstract class WidgetGateway {
  Future<void> save(String key, Object? value);
  Future<void> refresh();
}

/// Implementação real (home_widget). Só age no Android.
class HomeWidgetGateway implements WidgetGateway {
  const HomeWidgetGateway();

  @override
  Future<void> save(String key, Object? value) =>
      HomeWidget.saveWidgetData<dynamic>(key, value);

  @override
  Future<void> refresh() => HomeWidget.updateWidget(
    qualifiedAndroidName: 'br.com.tqvp.tqvp.$favoritesWidgetProviderName',
  );
}

/// Gateway que não faz nada (iOS, desktop, web e testes).
class NoopWidgetGateway implements WidgetGateway {
  const NoopWidgetGateway();

  @override
  Future<void> save(String key, Object? value) async {}

  @override
  Future<void> refresh() async {}
}

WidgetGateway defaultWidgetGateway() =>
    !kIsWeb && Platform.isAndroid && !_isFlutterTest
    ? const HomeWidgetGateway()
    : const NoopWidgetGateway();

bool get _isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');

/// Gera o payload (chave -> valor) a partir dos ids favoritos.
/// Ids desconhecidos são ignorados; limita a [maxWidgetFavorites].
Map<String, Object?> buildWidgetPayload(
  List<String> favoriteIds, {
  Tool? Function(String id) lookup = toolById,
}) {
  final tools = <Tool>[];
  for (final id in favoriteIds) {
    final t = lookup(id);
    if (t != null) tools.add(t);
    if (tools.length == maxWidgetFavorites) break;
  }
  final payload = <String, Object?>{'fav_count': tools.length};
  for (var i = 0; i < maxWidgetFavorites; i++) {
    final t = i < tools.length ? tools[i] : null;
    payload['fav_${i}_id'] = t?.id;
    payload['fav_${i}_name'] = t?.name;
    payload['fav_${i}_cat'] = t?.category.name;
  }
  return payload;
}

class WidgetSyncService {
  WidgetSyncService(this._gateway, {Tool? Function(String id)? lookup})
    : _lookup = lookup ?? toolById;

  final WidgetGateway _gateway;
  final Tool? Function(String id) _lookup;

  /// Grava o payload e pede atualização do widget. Nunca lança.
  Future<void> sync(List<String> favoriteIds) async {
    try {
      final payload = buildWidgetPayload(favoriteIds, lookup: _lookup);
      for (final e in payload.entries) {
        await _gateway.save(e.key, e.value);
      }
      await _gateway.refresh();
    } catch (e) {
      debugPrint('Widget: falha ao sincronizar ($e)');
    }
  }
}

final widgetSyncServiceProvider = Provider<WidgetSyncService>(
  (ref) => WidgetSyncService(defaultWidgetGateway()),
);
