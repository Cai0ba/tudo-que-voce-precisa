import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../json_list_store.dart';
import '../org_widgets.dart';
import 'checklists_store.dart';

Future<void> _run(BuildContext context, Future<bool> f) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await f) showSaveError(messenger);
}

class ChecklistsScreen extends ConsumerWidget {
  const ChecklistsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final t = await promptText(
      context,
      title: 'Nova checklist',
      label: 'Título da checklist',
    );
    if (t == null || !context.mounted) return;
    await _run(context, ref.read(checklistsProvider.notifier).create(t));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Checklist c) async {
    final ok = await confirmDelete(
      context,
      title: 'Excluir checklist?',
      message: 'A checklist e todos os seus itens serão excluídos.',
    );
    if (!ok || !context.mounted) return;
    await _run(context, ref.read(checklistsProvider.notifier).remove(c.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(checklistsProvider);
    return ToolScaffold(
      title: 'Checklists',
      children: [
        AddCard(
          icon: Icons.checklist,
          title: 'Suas checklists',
          subtitle: 'Listas de itens para marcar um a um.',
          buttonLabel: 'Nova checklist',
          tooltip: 'Adicionar checklist',
          onPressed: () => _create(context, ref),
        ),
        if (lists.isEmpty)
          EmptyStateCard(
            icon: Icons.checklist,
            message: 'Nenhuma checklist ainda. Crie a primeira!',
            buttonLabel: 'Criar primeira checklist',
            onPressed: () => _create(context, ref),
          ),
        for (final c in lists)
          _ChecklistCard(
            checklist: c,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChecklistDetailScreen(checklistId: c.id),
              ),
            ),
            onDuplicate: () => _run(
              context,
              ref.read(checklistsProvider.notifier).duplicate(c.id),
            ),
            onDelete: () => _delete(context, ref, c),
          ),
      ],
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.checklist,
    required this.onOpen,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Checklist checklist;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = checklist.items.where((e) => e.checked).length;
    final total = checklist.items.length;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.xs,
        Spacing.sm,
      ),
      onTap: onOpen,
      child: Row(
        children: [
          const IconBadge(Icons.checklist, size: 44),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checklist.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text('$done de $total itens', style: theme.textTheme.bodySmall),
                const SizedBox(height: Spacing.sm),
                ProgressBar(done: done, total: total),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Duplicar checklist',
                icon: const Icon(Icons.copy_outlined),
                onPressed: onDuplicate,
              ),
              IconButton(
                tooltip: 'Excluir checklist',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChecklistDetailScreen extends ConsumerStatefulWidget {
  const ChecklistDetailScreen({required this.checklistId, super.key});
  final String checklistId;

  @override
  ConsumerState<ChecklistDetailScreen> createState() =>
      _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ConsumerState<ChecklistDetailScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _c.text;
    if (text.trim().isEmpty) return;
    _c.clear();
    await _run(
      context,
      ref.read(checklistsProvider.notifier).addItem(widget.checklistId, text),
    );
  }

  Future<void> _editItem(ChecklistItem item) async {
    final t = await promptText(
      context,
      title: 'Editar item',
      label: 'Texto do item',
      initial: item.text,
    );
    if (t == null || !mounted) return;
    await _run(
      context,
      ref
          .read(checklistsProvider.notifier)
          .editItem(widget.checklistId, item.id, t),
    );
  }

  Future<void> _rename(Checklist cl) async {
    final t = await promptText(
      context,
      title: 'Renomear checklist',
      label: 'Título da checklist',
      initial: cl.title,
    );
    if (t == null || !mounted) return;
    await _run(context, ref.read(checklistsProvider.notifier).rename(cl.id, t));
  }

  @override
  Widget build(BuildContext context) {
    final cl = ref
        .watch(checklistsProvider)
        .where((c) => c.id == widget.checklistId)
        .firstOrNull;
    if (cl == null) {
      return const ToolScaffold(
        title: 'Checklist',
        children: [Text('Esta checklist não existe mais.')],
      );
    }
    final notifier = ref.read(checklistsProvider.notifier);
    final doneCount = cl.items.where((e) => e.checked).length;
    return ToolScaffold(
      title: cl.title,
      actions: [
        IconButton(
          tooltip: 'Renomear checklist',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _rename(cl),
        ),
      ],
      children: [
        SectionCard(
          title: 'Progresso',
          children: [
            Text(
              '$doneCount de ${cl.items.length} concluídos',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            ProgressBar(done: doneCount, total: cl.items.length),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Novo item'),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                IconButton.filled(
                  tooltip: 'Adicionar item',
                  icon: const Icon(Icons.add),
                  onPressed: _add,
                ),
              ],
            ),
          ],
        ),
        if (cl.items.isEmpty)
          const EmptyStateCard(
            icon: Icons.playlist_add_check,
            message: 'Nenhum item. Digite acima para adicionar.',
          ),
        for (final it in cl.items)
          Opacity(
            key: ValueKey(it.id),
            opacity: it.checked ? 0.75 : 1,
            child: AppCard(
              padding: const EdgeInsets.all(Spacing.xs),
              child: Row(
                children: [
                  RoundCheck(
                    value: it.checked,
                    label: it.text,
                    onChanged: (v) =>
                        _run(context, notifier.setChecked(cl.id, it.id, v)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      child: Text(
                        it.text,
                        style: doneStyle(
                          context,
                          Theme.of(context).textTheme.bodyLarge,
                          it.checked,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar item',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editItem(it),
                  ),
                  IconButton(
                    tooltip: 'Remover item',
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        _run(context, notifier.removeItem(cl.id, it.id)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
