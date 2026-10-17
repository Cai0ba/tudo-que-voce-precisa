import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/tool_card.dart';
import '../tools/catalog.dart';
import 'favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    final tools = [for (final id in ids) ?toolById(id)];
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Brand.maxContentWidth),
          child: tools.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(Spacing.md),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconBadge(Icons.star_border_rounded, size: 64),
                          SizedBox(height: Spacing.md),
                          Text(
                            'Você ainda não tem favoritos.\nToque na estrela de uma ferramenta para fixá-la aqui.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(Spacing.md),
                      sliver: ToolGrid(tools),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
