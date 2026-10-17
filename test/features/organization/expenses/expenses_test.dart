import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tqvp/core/storage/preferences.dart';
import 'package:tqvp/features/organization/expenses/expenses_domain.dart';
import 'package:tqvp/features/organization/expenses/expenses_screen.dart';
import 'package:tqvp/features/organization/expenses/expenses_store.dart';

ExpenseEntry e(
  EntryType t,
  int cents,
  DateTime d, [
  ExpenseCategory c = ExpenseCategory.other,
]) => ExpenseEntry(
  id: '${d.microsecondsSinceEpoch}$cents',
  type: t,
  cents: cents,
  description: 'x',
  category: c,
  date: d,
);

Future<Widget> app() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: ExpensesScreen()),
  );
}

Future<void> reopen(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(await app());
  await t.pumpAndSettle();
}

Future<void> addEntry(
  WidgetTester t,
  String value,
  String desc, {
  bool income = false,
}) async {
  await t.tap(find.byTooltip('Adicionar lançamento'));
  await t.pumpAndSettle();
  if (income) {
    await t.tap(find.text('Entrada'));
    await t.pumpAndSettle();
  }
  await t.enterText(find.widgetWithText(TextField, 'Valor'), value);
  await t.enterText(find.widgetWithText(TextField, 'Descrição'), desc);
  await t.tap(find.text('Salvar'));
  await t.pumpAndSettle();
}

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(800, 4000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  group('domínio', () {
    test('parseCents', () {
      expect(parseCents('10'), 1000);
      expect(parseCents('10,5'), 1050);
      expect(parseCents('1.234,56'), 123456);
      expect(parseCents('0,01'), 1);
      expect(parseCents('0,005'), 1);
      expect(parseCents('0,1'), 10);
      expect(parseCents('19.99'), 1999);
      for (final bad in ['', 'abc', '0', '0,00', '-5', null, '1e5']) {
        expect(parseCents(bad), isNull, reason: '$bad');
      }
      expect(parseCents('99999999999'), isNull);
    });

    test('formatCents e centsToInput', () {
      expect(formatCents(123450).replaceAll(' ', ' '), 'R\$ 1.234,50');
      expect(centsToInput(1050), '10,50');
      expect(centsToInput(5), '0,05');
      expect(parseCents(centsToInput(123456)), 123456);
    });

    test('totais, saldo e mês', () {
      final out = MonthRef(2026, 10);
      final all = [
        e(
          EntryType.income,
          500000,
          DateTime(2026, 10, 1),
          ExpenseCategory.salary,
        ),
        e(
          EntryType.expense,
          10000,
          DateTime(2026, 10, 31),
          ExpenseCategory.food,
        ),
        e(EntryType.expense, 2550, DateTime(2026, 10, 5), ExpenseCategory.food),
        e(
          EntryType.expense,
          20000,
          DateTime(2026, 10, 6),
          ExpenseCategory.housing,
        ),
        e(EntryType.expense, 999, DateTime(2026, 9, 30), ExpenseCategory.food),
        e(EntryType.expense, 999, DateTime(2026, 11, 1), ExpenseCategory.food),
      ];
      final s = summarize(all, out);
      expect(s.income, 500000);
      expect(s.expense, 32550);
      expect(s.balance, 467450);
      expect(summarize(all, out.next).expense, 999);
      expect(summarize(all, MonthRef(2025, 1)).balance, 0);
      final cats = expensesByCategory(all, out);
      expect(cats.map((c) => c.key), [
        ExpenseCategory.housing,
        ExpenseCategory.food,
      ]);
      expect(cats.last.value, 12550);
      expect(entriesOfMonth(all, out).length, 4);
      final days = groupByDay(entriesOfMonth(all, out));
      expect(days.first.key, DateTime(2026, 10, 31));
      expect(days.length, 4);
    });

    test('navegação de mês', () {
      expect(MonthRef(2026, 12).next, MonthRef(2027, 1));
      expect(MonthRef(2026, 1).previous, MonthRef(2025, 12));
      expect(monthLabel(MonthRef(2026, 3)), 'Março de 2026');
    });

    test('round-trip JSON', () {
      final x = ExpenseEntry(
        id: 'a',
        type: EntryType.income,
        cents: 12345,
        description: 'Salário',
        category: ExpenseCategory.salary,
        date: DateTime(2026, 2, 3),
      );
      final y = ExpenseEntry.fromJson(x.toJson());
      expect(y.toJson(), x.toJson());
      expect(y.date, DateTime(2026, 2, 3));
      expect(y.cents, isA<int>());
    });

    test('JSON corrompido é descartado', () async {
      SharedPreferences.setMockInitialValues({
        'organization_expenses': '{[oops',
      });
      expect(
        expensesStore.load(await SharedPreferences.getInstance()),
        isEmpty,
      );
      SharedPreferences.setMockInitialValues({
        'organization_expenses':
            '[{"id":"1","type":"expense","cents":100,"description":"ok",'
            '"category":"food","date":"2026-10-05"},'
            '{"id":"2","type":"expense","cents":1.5,"date":"2026-10-05"},'
            '{"id":"3","type":"zzz","cents":5,"date":"2026-10-05"},'
            '{"id":"4","type":"income","cents":-5,"date":"2026-10-05"},'
            '{"id":"5","type":"income","cents":5,"date":"lixo"},"lixo"]',
      });
      final l = expensesStore.load(await SharedPreferences.getInstance());
      expect(l.map((x) => x.id), ['1']);
    });
  });

  group('widgets', () {
    testWidgets('adicionar, editar, excluir e persistir', (t) async {
      SharedPreferences.setMockInitialValues({});
      tall(t);
      await t.pumpWidget(await app());
      expect(find.textContaining('Nenhum lançamento'), findsOneWidget);

      await addEntry(t, '1.000,00', 'Pagamento', income: true);
      await addEntry(t, '25,90', 'Almoço');
      expect(find.text('Almoço'), findsOneWidget);
      expect(find.textContaining('25,90'), findsWidgets);
      final bal = t.widget<Text>(find.byKey(const Key('expenses_balance')));
      expect(bal.data!.replaceAll(' ', ' '), 'R\$ 974,10');

      await reopen(t);
      expect(find.text('Almoço'), findsOneWidget);
      expect(find.text('Pagamento'), findsOneWidget);

      await t.tap(find.text('Almoço'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, 'Valor'), '30');
      await t.enterText(find.widgetWithText(TextField, 'Descrição'), 'Jantar');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Almoço'), findsNothing);
      expect(find.text('Jantar'), findsOneWidget);
      final bal2 = t.widget<Text>(find.byKey(const Key('expenses_balance')));
      expect(bal2.data!.replaceAll(' ', ' '), 'R\$ 970,00');

      // valor inválido não salva
      await t.tap(find.byTooltip('Adicionar lançamento'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, 'Valor'), '0');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.textContaining('Informe um valor'), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();

      await t.tap(find.byTooltip('Excluir lançamento').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(find.text('Jantar'), findsOneWidget);
      await t.tap(find.byTooltip('Excluir lançamento').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();

      await reopen(t);
      expect(find.text('Jantar'), findsNothing);
      expect(find.text('Pagamento'), findsOneWidget);
    });

    testWidgets('navegar entre meses', (t) async {
      SharedPreferences.setMockInitialValues({});
      tall(t);
      await t.pumpWidget(await app());
      await addEntry(t, '10', 'Teste');
      expect(find.text('Teste'), findsOneWidget);
      await t.tap(find.byTooltip('Próximo mês'));
      await t.pumpAndSettle();
      expect(find.text('Teste'), findsNothing);
      expect(find.textContaining('Nenhum lançamento'), findsOneWidget);
      await t.tap(find.byTooltip('Mês anterior'));
      await t.pumpAndSettle();
      expect(find.text('Teste'), findsOneWidget);
    });

    testWidgets('formulário sem overflow em 320x568 com fonte 200%', (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const ExpensesScreen(),
          ),
        ),
      );
      await t.drag(find.byType(ListView), const Offset(0, -150));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Adicionar lançamento'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.enterText(find.widgetWithText(TextField, 'Valor'), '5');
      await t.ensureVisible(find.text('Salvar'));
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.dragUntilVisible(
        find.byTooltip('Excluir lançamento'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(t.takeException(), isNull);
    });
  });
}
