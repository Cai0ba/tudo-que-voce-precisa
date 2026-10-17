import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../json_list_store.dart';
import '../org_widgets.dart';
import 'notes_store.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  void _open(BuildContext context, String? id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoteEditorScreen(noteId: id)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Note n) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(
      context,
      title: 'Excluir nota?',
      message: 'Esta ação não pode ser desfeita.',
    );
    if (!ok) return;
    if (!await ref.read(notesProvider.notifier).remove(n.id)) {
      showSaveError(messenger);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final theme = Theme.of(context);
    return ToolScaffold(
      title: 'Notas',
      children: [
        AddCard(
          icon: Icons.sticky_note_2_outlined,
          title: 'Suas notas',
          subtitle: 'Guarde ideias e lembretes.',
          buttonLabel: 'Nova nota',
          tooltip: 'Adicionar nota',
          onPressed: () => _open(context, null),
        ),
        if (notes.isEmpty)
          EmptyStateCard(
            icon: Icons.sticky_note_2_outlined,
            message: 'Nenhuma nota ainda. Escreva a primeira!',
            buttonLabel: 'Criar primeira nota',
            onPressed: () => _open(context, null),
          ),
        for (final n in notes)
          KeyedSubtree(
            key: ValueKey(n.id),
            child: AppCard(
              onTap: () => _open(context, n.id),
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.md,
                Spacing.xs,
                Spacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title.trim().isEmpty ? 'Sem título' : n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (n.body.trim().isNotEmpty) ...[
                          const SizedBox(height: Spacing.xs),
                          Text(
                            n.body.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: Spacing.sm),
                        Text(
                          _fmt(n.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir nota',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, ref, n),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _fmt(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({this.noteId, super.key});
  final String? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  static const _debounce = Duration(milliseconds: 500);

  late final NotesNotifier _notifier = ref.read(notesProvider.notifier);
  late final TextEditingController _title;
  late final TextEditingController _body;
  ScaffoldMessengerState? _messenger;
  String? _id;
  Timer? _timer;
  bool _dirty = false;
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    _id = widget.noteId;
    final existing = ref
        .read(notesProvider)
        .where((n) => n.id == _id)
        .firstOrNull;
    _title = TextEditingController(text: existing?.title ?? '');
    _body = TextEditingController(text: existing?.body ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  void _changed() {
    _dirty = true;
    _timer?.cancel();
    _timer = Timer(_debounce, _flush);
  }

  Future<void> _flush() async {
    _timer?.cancel();
    if (!_dirty || _deleted) return;
    final title = _title.text;
    final body = _body.text;
    if (_id == null && title.trim().isEmpty && body.trim().isEmpty) {
      _dirty = false;
      return;
    }
    _dirty = false;
    _id ??= generateId();
    final ok = await _notifier.save(_id!, title, body);
    if (!ok) {
      _dirty = true;
      final m = _messenger;
      if (m != null) showSaveError(m);
    }
  }

  Future<void> _delete() async {
    final nav = Navigator.of(context);
    final ok = await confirmDelete(
      context,
      title: 'Excluir nota?',
      message: 'Esta ação não pode ser desfeita.',
    );
    if (!ok) return;
    _timer?.cancel();
    _deleted = true;
    if (_id != null) await _notifier.remove(_id!);
    nav.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Salva pendências ao sair (controllers só são descartados após o envio).
    final title = _title.text;
    final body = _body.text;
    if (_dirty &&
        !_deleted &&
        (_id != null || (title + body).trim().isNotEmpty)) {
      _id ??= generateId();
      final m = _messenger;
      unawaited(
        _notifier.save(_id!, title, body).then((ok) {
          if (!ok && m != null && m.mounted) showSaveError(m);
        }),
      );
    }
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota'),
        actions: [
          IconButton(
            tooltip: 'Excluir nota',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Brand.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(Spacing.sm),
                    child: TextField(
                      controller: _title,
                      onChanged: (_) => _changed(),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: TextField(
                        controller: _body,
                        onChanged: (_) => _changed(),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Conteúdo',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
