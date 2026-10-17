import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';
import '../json_list_store.dart';

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.text,
    this.checked = false,
  });

  final String id;
  final String text;
  final bool checked;

  ChecklistItem copyWith({String? text, bool? checked}) => ChecklistItem(
    id: id,
    text: text ?? this.text,
    checked: checked ?? this.checked,
  );

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'checked': checked};

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
    id: j['id'] as String,
    text: j['text'] as String,
    checked: j['checked'] as bool? ?? false,
  );
}

class Checklist {
  const Checklist({
    required this.id,
    required this.title,
    this.items = const [],
  });

  final String id;
  final String title;
  final List<ChecklistItem> items;

  Checklist copyWith({String? title, List<ChecklistItem>? items}) =>
      Checklist(id: id, title: title ?? this.title, items: items ?? this.items);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory Checklist.fromJson(Map<String, dynamic> j) {
    final raw = j['items'];
    final items = <ChecklistItem>[];
    if (raw is List) {
      for (final e in raw) {
        try {
          if (e is Map) {
            items.add(ChecklistItem.fromJson(Map<String, dynamic>.from(e)));
          }
        } catch (_) {}
      }
    }
    return Checklist(
      id: j['id'] as String,
      title: j['title'] as String,
      items: items,
    );
  }
}

const checklistsStore = JsonListStore<Checklist>(
  key: 'organization_checklists',
  fromJson: Checklist.fromJson,
  toJson: _toJson,
);
Map<String, dynamic> _toJson(Checklist c) => c.toJson();

class ChecklistsNotifier extends Notifier<List<Checklist>> {
  @override
  List<Checklist> build() =>
      checklistsStore.load(ref.read(sharedPreferencesProvider));

  Future<bool> _commit(List<Checklist> next) {
    state = next;
    return checklistsStore.save(ref.read(sharedPreferencesProvider), next);
  }

  Future<bool> _update(String id, Checklist Function(Checklist) f) =>
      _commit([for (final c in state) c.id == id ? f(c) : c]);

  /// Cria e devolve o id via [onCreated] antes de persistir.
  Future<bool> create(String title, {void Function(String id)? onCreated}) {
    final t = title.trim();
    if (t.isEmpty) return Future.value(true);
    final c = Checklist(id: generateId(), title: t);
    onCreated?.call(c.id);
    return _commit([c, ...state]);
  }

  Future<bool> rename(String id, String title) {
    final t = title.trim();
    if (t.isEmpty) return Future.value(true);
    return _update(id, (c) => c.copyWith(title: t));
  }

  Future<bool> remove(String id) =>
      _commit(state.where((c) => c.id != id).toList());

  /// Cópia profunda: novo id para a lista e para cada item.
  Future<bool> duplicate(String id, {String suffix = ' (cópia)'}) {
    final i = state.indexWhere((c) => c.id == id);
    if (i < 0) return Future.value(true);
    final src = state[i];
    final copy = Checklist(
      id: generateId(),
      title: '${src.title}$suffix',
      items: [
        for (final it in src.items)
          ChecklistItem(id: generateId(), text: it.text, checked: it.checked),
      ],
    );
    return _commit([...state]..insert(i + 1, copy));
  }

  Future<bool> addItem(String id, String text) {
    final t = text.trim();
    if (t.isEmpty) return Future.value(true);
    return _update(
      id,
      (c) => c.copyWith(
        items: [
          ...c.items,
          ChecklistItem(id: generateId(), text: t),
        ],
      ),
    );
  }

  Future<bool> editItem(String id, String itemId, String text) {
    final t = text.trim();
    if (t.isEmpty) return Future.value(true);
    return _update(
      id,
      (c) => c.copyWith(
        items: [
          for (final e in c.items) e.id == itemId ? e.copyWith(text: t) : e,
        ],
      ),
    );
  }

  Future<bool> setChecked(String id, String itemId, bool v) => _update(
    id,
    (c) => c.copyWith(
      items: [
        for (final e in c.items) e.id == itemId ? e.copyWith(checked: v) : e,
      ],
    ),
  );

  Future<bool> removeItem(String id, String itemId) => _update(
    id,
    (c) => c.copyWith(items: c.items.where((e) => e.id != itemId).toList()),
  );
}

final checklistsProvider =
    NotifierProvider<ChecklistsNotifier, List<Checklist>>(
      ChecklistsNotifier.new,
    );
