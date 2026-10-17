import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../tools/catalog.dart';

/// Converte o deep link do widget (`tqvp://tool/<id>` ou `tqvp://home`)
/// em rota do go_router. Retorna null se inválido/desconhecido.
String? routeForWidgetUri(Uri? uri) {
  if (uri == null || uri.scheme != 'tqvp') return null;
  if (uri.host == 'home') return '/';
  if (uri.host == 'tool' && uri.pathSegments.length == 1) {
    final id = uri.pathSegments.first;
    if (toolById(id) != null) return '/tool/$id';
  }
  return null;
}

bool get _supported =>
    !kIsWeb &&
    Platform.isAndroid &&
    !Platform.environment.containsKey('FLUTTER_TEST');

/// Liga os cliques do widget à navegação. [open] recebe a rota
/// (ex.: `/tool/bmi`). Retorna a assinatura para cancelar no dispose.
/// No-op fora do Android/testes; falhas de plataforma são ignoradas.
Future<StreamSubscription<Uri?>?> listenWidgetClicks(
  void Function(String route) open,
) async {
  if (!_supported) return null;
  void handle(Uri? uri) {
    final route = routeForWidgetUri(uri);
    if (route != null) open(route);
  }

  try {
    handle(await HomeWidget.initiallyLaunchedFromHomeWidget());
    return HomeWidget.widgetClicked.listen(
      handle,
      onError: (Object e) => debugPrint('Widget: erro no clique ($e)'),
    );
  } catch (e) {
    debugPrint('Widget: clique indisponível ($e)');
    return null;
  }
}
