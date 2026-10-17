import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/tools/catalog.dart';
import 'tool_screens.dart';

GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
    GoRoute(
      path: '/tool/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final builder = toolScreens[id];
        if (builder == null || toolById(id) == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ferramenta')),
            body: const Center(child: Text('Ferramenta não encontrada.')),
          );
        }
        return builder(context);
      },
    ),
  ],
);
