import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/tool_card.dart';
import '../favorites/favorites_provider.dart';
import '../search/tool_search.dart';
import '../tools/catalog.dart';
import '../tools/tool.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final favIds = ref.watch(favoritesProvider);
    final favorites = [for (final id in favIds) ?toolById(id)];
    final searching = _query.trim().isNotEmpty;
    final results = searching ? searchTools(_query) : const <Tool>[];

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Brand.maxContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(onChanged: (v) => setState(() => _query = v)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.md)),
              if (searching) ...[
                if (results.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Spacing.md),
                      child: AppCard(
                        child: Center(
                          child: Text('Nenhuma ferramenta encontrada.'),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    sliver: ToolGrid(results),
                  ),
              ] else ...[
                if (favorites.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: Spacing.md),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader('Favoritos'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 176,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                        ),
                        itemCount: favorites.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: Spacing.md),
                        itemBuilder: (_, i) => SizedBox(
                          width: 160,
                          child: ToolGridCard(favorites[i]),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
                ],
                for (final cat in ToolCategory.values) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    sliver: SliverToBoxAdapter(child: SectionHeader(cat.label)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    sliver: ToolGrid([
                      for (final t in toolCatalog)
                        if (t.category == cat) t,
                    ]),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.md)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        MediaQuery.paddingOf(context).top + Spacing.md,
        Spacing.md,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Tudo Que Você Precisa',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Favoritos',
                icon: const Icon(
                  Icons.star_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: () => context.push('/favorites'),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Calculadoras, conversores e utilidades em um só lugar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Spacing.md),
          SearchBar(
            hintText: 'Buscar ferramenta (ex.: desconto, dólar)',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
