import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';
import '../widgets/widget_sync_service.dart';

const _key = 'favorite_tool_ids';

class FavoritesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref.read(sharedPreferencesProvider).getStringList(_key) ?? const [];

  Future<void> toggle(String id) async {
    final next = state.contains(id)
        ? state.where((e) => e != id).toList()
        : [...state, id];
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_key, next);
    await ref.read(widgetSyncServiceProvider).sync(next);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);
