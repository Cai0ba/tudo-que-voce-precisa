import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';
import '../json_list_store.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.done = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  Task copyWith({String? title, bool? done}) => Task(
    id: id,
    title: title ?? this.title,
    done: done ?? this.done,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    title: j['title'] as String,
    done: j['done'] as bool? ?? false,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

const tasksStore = JsonListStore<Task>(
  key: 'organization_tasks',
  fromJson: Task.fromJson,
  toJson: _taskToJson,
);
Map<String, dynamic> _taskToJson(Task t) => t.toJson();

class TasksNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() => tasksStore.load(ref.read(sharedPreferencesProvider));

  Future<bool> _commit(List<Task> next) {
    state = next;
    return tasksStore.save(ref.read(sharedPreferencesProvider), next);
  }

  Future<bool> add(String title) {
    final t = title.trim();
    if (t.isEmpty) return Future.value(true);
    return _commit([
      Task(id: generateId(), title: t, createdAt: DateTime.now()),
      ...state,
    ]);
  }

  Future<bool> edit(String id, String title) {
    final t = title.trim();
    if (t.isEmpty) return Future.value(true);
    return _commit([
      for (final e in state) e.id == id ? e.copyWith(title: t) : e,
    ]);
  }

  Future<bool> setDone(String id, bool done) =>
      _commit([for (final e in state) e.id == id ? e.copyWith(done: done) : e]);

  Future<bool> remove(String id) =>
      _commit(state.where((e) => e.id != id).toList());
}

final tasksProvider = NotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);
