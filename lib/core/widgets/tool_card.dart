import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../features/favorites/favorites_provider.dart';
import '../../features/tools/tool.dart';
import 'components.dart';

/// Card quadrado de ferramenta para grades: ícone, nome, descrição e estrela.
class ToolGridCard extends ConsumerWidget {
  const ToolGridCard(this.tool, {super.key});
  final Tool tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(tool.id);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${tool.name}. ${tool.description}',
      excludeSemantics: true,
      onTap: () => context.push(tool.route),
      child: AppCard(
        onTap: () => context.push(tool.route),
        padding: const EdgeInsets.all(Spacing.md),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(tool.icon),
                const Spacer(),
                Text(
                  tool.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  tool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Positioned(
              top: -8,
              right: -8,
              child: IconButton(
                tooltip: isFav
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav
                      ? const Color(0xFFF5B301)
                      : theme.colorScheme.outline,
                ),
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggle(tool.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grade de cards de ferramentas (como sliver).
class ToolGrid extends StatelessWidget {
  const ToolGrid(this.tools, {super.key});
  final List<Tool> tools;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: Spacing.md,
        crossAxisSpacing: Spacing.md,
        mainAxisExtent: 168 + 40 * (scale - 1).clamp(0, 1.5),
      ),
      delegate: SliverChildBuilderDelegate(
        (_, i) => ToolGridCard(tools[i]),
        childCount: tools.length,
      ),
    );
  }
}
