import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';
import '../json_list_store.dart';

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );
}

const notesStore = JsonListStore<Note>(
  key: 'organization_notes',
  fromJson: Note.fromJson,
  toJson: _toJson,
);
Map<String, dynamic> _toJson(Note n) => n.toJson();

class NotesNotifier extends Notifier<List<Note>> {
  @override
  List<Note> build() {
    final l = notesStore.load(ref.read(sharedPreferencesProvider));
    l.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return l;
  }

  Future<bool> _commit(List<Note> next) {
    state = next;
    return notesStore.save(ref.read(sharedPreferencesProvider), next);
  }

  /// Insere ou atualiza (a nota mais recente vai para o topo).
  Future<bool> save(String id, String title, String body) {
    final n = Note(id: id, title: title, body: body, updatedAt: DateTime.now());
    return _commit([n, ...state.where((e) => e.id != id)]);
  }

  Future<bool> remove(String id) =>
      _commit(state.where((e) => e.id != id).toList());
}

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);
