import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../json_list_store.dart';
import '../org_widgets.dart';
import 'tasks_store.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  Future<void> _run(BuildContext context, Future<bool> f) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await f) showSaveError(messenger);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final t = await promptText(
      context,
      title: 'Nova tarefa',
      label: 'Descrição da tarefa',
    );
    if (t == null || !context.mounted) return;
    await _run(context, ref.read(tasksProvider.notifier).add(t));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Task task) async {
    final t = await promptText(
      context,
      title: 'Editar tarefa',
      label: 'Descrição da tarefa',
      initial: task.title,
    );
    if (t == null || !context.mounted) return;
    await _run(context, ref.read(tasksProvider.notifier).edit(task.id, t));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Task task) async {
    final ok = await confirmDelete(
      context,
      title: 'Excluir tarefa?',
      message: 'Esta ação não pode ser desfeita.',
    );
    if (!ok || !context.mounted) return;
    await _run(context, ref.read(tasksProvider.notifier).remove(task.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();

    Widget tile(Task t) => _TaskTile(
      task: t,
      onToggle: (v) =>
          _run(context, ref.read(tasksProvider.notifier).setDone(t.id, v)),
      onEdit: () => _edit(context, ref, t),
      onDelete: () => _delete(context, ref, t),
    );

    return ToolScaffold(
      title: 'Tarefas',
      children: [
        AddCard(
          icon: Icons.task_alt,
          title: 'Suas tarefas',
          subtitle: tasks.isEmpty
              ? 'Anote o que precisa fazer.'
              : '${done.length} de ${tasks.length} concluídas',
          buttonLabel: 'Nova tarefa',
          tooltip: 'Adicionar tarefa',
          onPressed: () => _add(context, ref),
        ),
        if (tasks.isEmpty)
          EmptyStateCard(
            icon: Icons.task_alt,
            message: 'Nenhuma tarefa ainda. Que tal criar a primeira?',
            buttonLabel: 'Criar primeira tarefa',
            onPressed: () => _add(context, ref),
          ),
        if (pending.isNotEmpty)
          _Section(
            title: 'Pendentes (${pending.length})',
            children: [for (final t in pending) tile(t)],
          ),
        if (done.isNotEmpty)
          _Section(
            title: 'Concluídas (${done.length})',
            children: [for (final t in done) tile(t)],
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          children[i],
        ],
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: task.done ? 0.75 : 1,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: Spacing.xs,
        ),
        child: Row(
          children: [
            RoundCheck(
              value: task.done,
              onChanged: onToggle,
              label: task.title,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Text(
                  task.title,
                  style: doneStyle(
                    context,
                    theme.textTheme.bodyLarge,
                    task.done,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Editar tarefa',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Excluir tarefa',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
