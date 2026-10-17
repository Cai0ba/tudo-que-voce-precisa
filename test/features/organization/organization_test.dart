import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tqvp/core/storage/preferences.dart';
import 'package:tqvp/features/organization/checklists/checklists_screen.dart';
import 'package:tqvp/features/organization/checklists/checklists_store.dart';
import 'package:tqvp/features/organization/json_list_store.dart';
import 'package:tqvp/features/organization/notes/notes_screen.dart';
import 'package:tqvp/features/organization/notes/notes_store.dart';
import 'package:tqvp/features/organization/tasks/tasks_screen.dart';
import 'package:tqvp/features/organization/tasks/tasks_store.dart';

Future<Widget> app(Widget home) async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: home),
  );
}

/// Recria o ProviderScope (mesmos prefs mock) simulando reabrir o app.
Future<void> reopen(WidgetTester t, Widget home) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(await app(home));
  await t.pumpAndSettle();
}

void main() {
  group('modelos e store', () {
    test('round-trip JSON', () {
      final t = Task(
        id: 'a',
        title: 'x',
        done: true,
        createdAt: DateTime(2024),
      );
      expect(Task.fromJson(t.toJson()).toJson(), t.toJson());
      const c = Checklist(
        id: 'c',
        title: 't',
        items: [ChecklistItem(id: 'i', text: 'a', checked: true)],
      );
      expect(Checklist.fromJson(c.toJson()).toJson(), c.toJson());
      final n = Note(id: 'n', title: 't', body: 'b', updatedAt: DateTime(2024));
      expect(Note.fromJson(n.toJson()).toJson(), n.toJson());
    });

    test('JSON corrompido é descartado sem crash', () async {
      SharedPreferences.setMockInitialValues({'organization_tasks': '{[oops'});
      final p = await SharedPreferences.getInstance();
      expect(tasksStore.load(p), isEmpty);
      SharedPreferences.setMockInitialValues({'organization_tasks': '{"a":1}'});
      final p2 = await SharedPreferences.getInstance();
      expect(tasksStore.load(p2), isEmpty);
      SharedPreferences.setMockInitialValues({
        'organization_tasks':
            '[{"id":"1","title":"ok","createdAt":"2024-01-01T00:00:00.000"},'
            '{"id":2},"lixo"]',
      });
      final p3 = await SharedPreferences.getInstance();
      expect(tasksStore.load(p3).map((e) => e.title), ['ok']);
    });

    test('ids são únicos', () {
      expect({for (var i = 0; i < 1000; i++) generateId()}.length, 1000);
    });

    test('duplicar checklist gera cópia profunda com novos ids', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final n = c.read(checklistsProvider.notifier);
      await n.create('Viagem');
      final id = c.read(checklistsProvider).first.id;
      await n.addItem(id, 'Passaporte');
      await n.duplicate(id);
      var l = c.read(checklistsProvider);
      expect(l.length, 2);
      expect(l[1].id, isNot(id));
      expect(l[1].items.single.id, isNot(l[0].items.single.id));
      await n.addItem(l[1].id, 'Extra');
      l = c.read(checklistsProvider);
      expect(l[0].items.length, 1);
      expect(l[1].items.length, 2);
    });
  });

  group('widgets', () {
    testWidgets('tarefas: criar, concluir, editar, excluir e persistir', (
      t,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(await app(const TasksScreen()));
      expect(find.textContaining('Nenhuma tarefa'), findsOneWidget);

      await t.tap(find.byTooltip('Adicionar tarefa'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Comprar pão');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Comprar pão'), findsOneWidget);
      expect(find.text('Pendentes (1)'), findsOneWidget);

      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      expect(find.text('Concluídas (1)'), findsOneWidget);

      await reopen(t, const TasksScreen());
      expect(find.text('Concluídas (1)'), findsOneWidget);

      await t.tap(find.byTooltip('Editar tarefa'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Comprar leite');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Comprar leite'), findsOneWidget);

      await t.tap(find.byTooltip('Excluir tarefa'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(find.text('Comprar leite'), findsOneWidget);
      await t.tap(find.byTooltip('Excluir tarefa'));
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();
      expect(find.text('Comprar leite'), findsNothing);

      await reopen(t, const TasksScreen());
      expect(find.textContaining('Nenhuma tarefa'), findsOneWidget);
    });

    testWidgets('checklists: criar, itens, duplicar, excluir, persistir', (
      t,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(await app(const ChecklistsScreen()));

      await t.tap(find.byTooltip('Adicionar checklist'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Mercado');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();

      await t.tap(find.text('Mercado'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Arroz');
      await t.tap(find.byTooltip('Adicionar item'));
      await t.pumpAndSettle();
      expect(find.text('Arroz'), findsOneWidget);
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Editar item'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, 'Feijão');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Feijão'), findsOneWidget);

      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.text('1 de 1 itens'), findsOneWidget);

      await t.tap(find.byTooltip('Duplicar checklist'));
      await t.pumpAndSettle();
      expect(find.text('Mercado (cópia)'), findsOneWidget);

      await reopen(t, const ChecklistsScreen());
      expect(find.text('Mercado (cópia)'), findsOneWidget);
      await t.tap(find.text('Mercado (cópia)'));
      await t.pumpAndSettle();
      expect(find.text('Feijão'), findsOneWidget);
      await t.tap(find.byTooltip('Remover item'));
      await t.pumpAndSettle();
      expect(find.text('Feijão'), findsNothing);
      await t.pageBack();
      await t.pumpAndSettle();
      // original continua com seu item
      expect(find.text('1 de 1 itens'), findsOneWidget);

      await t.tap(find.byTooltip('Excluir checklist').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Mercado (cópia)'), findsNothing);
    });

    testWidgets('notas: criar com autosave, editar, sair, excluir', (t) async {
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(await app(const NotesScreen()));
      expect(find.textContaining('Nenhuma nota'), findsOneWidget);

      await t.tap(find.byTooltip('Adicionar nota'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, 'Título'), 'Ideia');
      await t.enterText(
        find.widgetWithText(TextField, 'Conteúdo'),
        'Texto longo da nota',
      );
      // sai antes do debounce: salvamento ao sair
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.text('Ideia'), findsOneWidget);
      expect(find.text('Texto longo da nota'), findsOneWidget);

      await reopen(t, const NotesScreen());
      expect(find.text('Ideia'), findsOneWidget);

      await t.tap(find.text('Ideia'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, 'Título'), 'Ideia 2');
      await t.pump(const Duration(milliseconds: 700)); // debounce
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.text('Ideia 2'), findsOneWidget);
      expect(find.text('Ideia'), findsNothing);

      await t.tap(find.byTooltip('Excluir nota'));
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();
      expect(find.textContaining('Nenhuma nota'), findsOneWidget);
    });
  });
}
