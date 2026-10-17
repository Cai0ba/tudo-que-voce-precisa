import 'package:decimal/decimal.dart';

import '../../../core/formatting/number_utils.dart';

/// Tipo do lançamento.
enum EntryType {
  income('Entrada'),
  expense('Saída');

  const EntryType(this.label);
  final String label;
}

/// Categorias fixas.
enum ExpenseCategory {
  food('Alimentação'),
  transport('Transporte'),
  housing('Moradia'),
  health('Saúde'),
  leisure('Lazer'),
  education('Educação'),
  salary('Salário'),
  other('Outros');

  const ExpenseCategory(this.label);
  final String label;

  static ExpenseCategory fromName(String? name) {
    for (final c in values) {
      if (c.name == name) return c;
    }
    return other;
  }
}

/// Valor máximo aceito (em centavos): R$ 999.999.999,99.
const int maxCents = 99999999999;

/// Converte texto pt-BR em centavos inteiros. Retorna null se vazio,
/// inválido, zero, negativo ou acima de [maxCents]. Mais de duas casas
/// decimais são arredondadas.
int? parseCents(String? text) {
  final d = parseDecimal(text);
  if (d == null || d <= Decimal.zero) return null;
  final cents = (d * Decimal.fromInt(100)).round().toBigInt();
  if (cents <= BigInt.zero || cents > BigInt.from(maxCents)) return null;
  return cents.toInt();
}

/// Texto editável (sem símbolo) a partir de centavos, ex.: 1050 -> "10,50".
String centsToInput(int cents) {
  final abs = cents.abs();
  final r = (abs % 100).toString().padLeft(2, '0');
  return '${abs ~/ 100},$r';
}

/// "R$ 1.234,50" a partir de centavos (negativos com sinal).
String formatCents(int cents) =>
    formatBrl(Decimal.fromBigInt(BigInt.from(cents)).shift(-2));

/// Lançamento. Valor sempre em centavos (inteiro, positivo).
class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.type,
    required this.cents,
    required this.description,
    required this.category,
    required this.date,
  });

  final String id;
  final EntryType type;
  final int cents;
  final String description;
  final ExpenseCategory category;

  /// Apenas a data (sem hora).
  final DateTime date;

  ExpenseEntry copyWith({
    EntryType? type,
    int? cents,
    String? description,
    ExpenseCategory? category,
    DateTime? date,
  }) => ExpenseEntry(
    id: id,
    type: type ?? this.type,
    cents: cents ?? this.cents,
    description: description ?? this.description,
    category: category ?? this.category,
    date: date ?? this.date,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'cents': cents,
    'description': description,
    'category': category.name,
    'date': dateKey(date),
  };

  /// Lança exceção se inválido (o store descarta o item).
  factory ExpenseEntry.fromJson(Map<String, dynamic> j) {
    final cents = j['cents'];
    if (cents is! int || cents <= 0 || cents > maxCents) {
      throw const FormatException('cents');
    }
    final type = EntryType.values.firstWhere((e) => e.name == j['type']);
    final parts = (j['date'] as String).split('-');
    if (parts.length != 3) throw const FormatException('date');
    return ExpenseEntry(
      id: j['id'] as String,
      type: type,
      cents: cents,
      description: (j['description'] as String?) ?? '',
      category: ExpenseCategory.fromName(j['category'] as String?),
      date: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
    );
  }
}

/// "2026-10-05".
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Mês de referência (ano + mês 1..12).
class MonthRef implements Comparable<MonthRef> {
  const MonthRef(this.year, this.month);
  factory MonthRef.of(DateTime d) => MonthRef(d.year, d.month);

  final int year;
  final int month;

  MonthRef get next =>
      month == 12 ? MonthRef(year + 1, 1) : MonthRef(year, month + 1);
  MonthRef get previous =>
      month == 1 ? MonthRef(year - 1, 12) : MonthRef(year, month - 1);

  bool contains(DateTime d) => d.year == year && d.month == month;

  @override
  int compareTo(MonthRef other) =>
      (year * 12 + month) - (other.year * 12 + other.month);

  @override
  bool operator ==(Object other) =>
      other is MonthRef && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

const monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

const weekdayNames = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

String monthLabel(MonthRef m) => '${monthNames[m.month - 1]} de ${m.year}';

/// "Segunda, 05/10/2026".
String dayLabel(DateTime d) =>
    '${weekdayNames[d.weekday - 1]}, ${formatDate(d)}';

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Totais de um mês, em centavos.
class MonthSummary {
  const MonthSummary({required this.income, required this.expense});
  final int income;
  final int expense;
  int get balance => income - expense;
}

List<ExpenseEntry> entriesOfMonth(List<ExpenseEntry> all, MonthRef m) =>
    all.where((e) => m.contains(e.date)).toList();

MonthSummary summarize(List<ExpenseEntry> all, MonthRef m) {
  var income = 0;
  var expense = 0;
  for (final e in all) {
    if (!m.contains(e.date)) continue;
    if (e.type == EntryType.income) {
      income += e.cents;
    } else {
      expense += e.cents;
    }
  }
  return MonthSummary(income: income, expense: expense);
}

/// Saídas do mês somadas por categoria, da maior para a menor
/// (empate: ordem do enum). Categorias sem saída ficam de fora.
List<MapEntry<ExpenseCategory, int>> expensesByCategory(
  List<ExpenseEntry> all,
  MonthRef m,
) {
  final totals = <ExpenseCategory, int>{};
  for (final e in all) {
    if (e.type != EntryType.expense || !m.contains(e.date)) continue;
    totals[e.category] = (totals[e.category] ?? 0) + e.cents;
  }
  final list = totals.entries.toList();
  list.sort((a, b) {
    final c = b.value.compareTo(a.value);
    return c != 0 ? c : a.key.index.compareTo(b.key.index);
  });
  return list;
}

/// Agrupa por dia (mais recente primeiro), mantendo a ordem original
/// dentro de cada dia.
List<MapEntry<DateTime, List<ExpenseEntry>>> groupByDay(
  List<ExpenseEntry> entries,
) {
  final map = <DateTime, List<ExpenseEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(dateOnly(e.date), () => []).add(e);
  }
  final out = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
  return out;
}
