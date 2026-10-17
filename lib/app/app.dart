import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../features/widgets/widget_link.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TqvpApp extends StatefulWidget {
  const TqvpApp({super.key});

  @override
  State<TqvpApp> createState() => _TqvpAppState();
}

class _TqvpAppState extends State<TqvpApp> {
  late final GoRouter _router = buildRouter();
  StreamSubscription<Uri?>? _widgetSub;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    listenWidgetClicks(_openFromWidget).then((sub) {
      if (_disposed) {
        sub?.cancel();
      } else {
        _widgetSub = sub;
      }
    });
  }

  void _openFromWidget(String route) {
    if (_disposed) return;
    _router.go('/');
    if (route != '/') _router.push(route);
  }

  @override
  void dispose() {
    _disposed = true;
    _widgetSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tudo Que Você Precisa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
