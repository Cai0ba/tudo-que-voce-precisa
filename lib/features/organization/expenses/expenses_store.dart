import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';
import '../json_list_store.dart';
import 'expenses_domain.dart';

const expensesStore = JsonListStore<ExpenseEntry>(
  key: 'organization_expenses',
  fromJson: ExpenseEntry.fromJson,
  toJson: _toJson,
);
Map<String, dynamic> _toJson(ExpenseEntry e) => e.toJson();

class ExpensesNotifier extends Notifier<List<ExpenseEntry>> {
  @override
  List<ExpenseEntry> build() =>
      expensesStore.load(ref.read(sharedPreferencesProvider));

  Future<bool> _commit(List<ExpenseEntry> next) {
    state = next;
    return expensesStore.save(ref.read(sharedPreferencesProvider), next);
  }

  Future<bool> add({
    required EntryType type,
    required int cents,
    required String description,
    required ExpenseCategory category,
    required DateTime date,
  }) => _commit([
    ExpenseEntry(
      id: generateId(),
      type: type,
      cents: cents,
      description: description.trim(),
      category: category,
      date: dateOnly(date),
    ),
    ...state,
  ]);

  Future<bool> update(ExpenseEntry entry) => _commit([
    for (final e in state)
      e.id == entry.id ? entry.copyWith(date: dateOnly(entry.date)) : e,
  ]);

  Future<bool> remove(String id) =>
      _commit(state.where((e) => e.id != id).toList());
}

final expensesProvider = NotifierProvider<ExpensesNotifier, List<ExpenseEntry>>(
  ExpensesNotifier.new,
);
