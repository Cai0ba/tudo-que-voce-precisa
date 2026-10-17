import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/storage/preferences.dart';
import 'features/favorites/favorites_provider.dart';
import 'features/widgets/widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  // Sincroniza o widget da tela inicial na inicialização (sem bloquear).
  unawaited(
    container
        .read(widgetSyncServiceProvider)
        .sync(container.read(favoritesProvider)),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const TqvpApp()),
  );
}
