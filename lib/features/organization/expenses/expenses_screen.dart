import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../json_list_store.dart';
import '../org_widgets.dart';
import 'expenses_domain.dart';
import 'expenses_store.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  late MonthRef _month = MonthRef.of(DateTime.now());

  Future<void> _run(Future<bool> f) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await f) showSaveError(messenger);
  }

  Future<void> _openForm([ExpenseEntry? entry]) async {
    final draft = await showModalBottomSheet<_Draft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card)),
      ),
      builder: (_) => _EntryForm(entry: entry, month: _month),
    );
    if (draft == null || !mounted) return;
    final n = ref.read(expensesProvider.notifier);
    if (entry == null) {
      await _run(
        n.add(
          type: draft.type,
          cents: draft.cents,
          description: draft.description,
          category: draft.category,
          date: draft.date,
        ),
      );
    } else {
      await _run(
        n.update(
          entry.copyWith(
            type: draft.type,
            cents: draft.cents,
            description: draft.description.trim(),
            category: draft.category,
            date: draft.date,
          ),
        ),
      );
    }
    // Mostra o mês do lançamento salvo.
    if (mounted && !_month.contains(draft.date)) {
      setState(() => _month = MonthRef.of(draft.date));
    }
  }

  Future<void> _delete(ExpenseEntry e) async {
    final ok = await confirmDelete(
      context,
      title: 'Excluir lançamento?',
      message: 'Esta ação não pode ser desfeita.',
    );
    if (!ok || !mounted) return;
    await _run(ref.read(expensesProvider.notifier).remove(e.id));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(expensesProvider);
    final monthEntries = entriesOfMonth(all, _month);
    final summary = summarize(all, _month);
    final byCat = expensesByCategory(all, _month);
    final days = groupByDay(monthEntries);

    return ToolScaffold(
      title: 'Controle de gastos',
      children: [
        AddCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Seus lançamentos',
          subtitle: 'Registre entradas e saídas do mês.',
          buttonLabel: 'Novo lançamento',
          tooltip: 'Adicionar lançamento',
          onPressed: () => _openForm(),
        ),
        _MonthNavigator(
          month: _month,
          onPrevious: () => setState(() => _month = _month.previous),
          onNext: () => setState(() => _month = _month.next),
        ),
        _SummaryCard(summary: summary),
        if (monthEntries.isEmpty)
          EmptyStateCard(
            icon: Icons.receipt_long_outlined,
            message: 'Nenhum lançamento em ${monthLabel(_month)}.',
            buttonLabel: 'Adicionar lançamento',
            onPressed: () => _openForm(),
          )
        else ...[
          if (byCat.isNotEmpty)
            _CategoryBars(data: byCat, total: summary.expense),
          for (final d in days)
            _DaySection(
              day: d.key,
              entries: d.value,
              onEdit: _openForm,
              onDelete: _delete,
            ),
        ],
      ],
    );
  }
}

class _Draft {
  const _Draft(
    this.type,
    this.cents,
    this.description,
    this.category,
    this.date,
  );
  final EntryType type;
  final int cents;
  final String description;
  final ExpenseCategory category;
  final DateTime date;
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });
  final MonthRef month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                monthLabel(month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final negative = summary.balance < 0;
    final bg = negative
        ? (dark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
        : (dark ? Brand.blueDeep : Brand.blueSoft);
    final fg = negative
        ? (dark ? const Color(0xFFFEE2E2) : const Color(0xFF991B1B))
        : (dark ? Colors.white : Brand.blueDeep);
    final balanceText = formatCents(summary.balance);

    Widget stat(String label, String value, IconData icon) => Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: Spacing.sm),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: 'Saldo do mês: $balanceText',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(Radii.field),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo do mês',
                    style: theme.textTheme.labelLarge?.copyWith(color: fg),
                  ),
                  Text(
                    balanceText,
                    key: const Key('expenses_balance'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          stat('Entradas', formatCents(summary.income), Icons.south_west),
          const SizedBox(height: Spacing.sm),
          stat('Saídas', formatCents(summary.expense), Icons.north_east),
        ],
      ),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.data, required this.total});
  final List<MapEntry<ExpenseCategory, int>> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Saídas por categoria',
      children: [
        for (final e in data)
          Builder(
            builder: (_) {
              final frac = total == 0 ? 0.0 : e.value / total;
              final pct = (frac * 100).round();
              final value = formatCents(e.value);
              return Semantics(
                container: true,
                label: '${e.key.label}: $value, $pct% das saídas',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.key.label,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            color: theme.colorScheme.primaryContainer,
                          ),
                          FractionallySizedBox(
                            widthFactor: frac.clamp(0.0, 1.0),
                            child: Container(height: 10, color: Brand.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });
  final DateTime day;
  final List<ExpenseEntry> entries;
  final ValueChanged<ExpenseEntry> onEdit;
  final ValueChanged<ExpenseEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(dayLabel(day)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          _EntryTile(
            entry: entries[i],
            onEdit: () => onEdit(entries[i]),
            onDelete: () => onDelete(entries[i]),
          ),
        ],
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final ExpenseEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final income = entry.type == EntryType.income;
    final amount = '${income ? '+' : '-'} ${formatCents(entry.cents)}';
    final color = income
        ? (dark ? const Color(0xFF93C5FD) : Brand.blueDark)
        : (dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C));
    final title = entry.description.isEmpty
        ? entry.category.label
        : entry.description;
    return AppCard(
      padding: const EdgeInsets.only(
        left: Spacing.md,
        top: Spacing.xs,
        bottom: Spacing.xs,
        right: Spacing.xs,
      ),
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Semantics(
                label:
                    '${entry.type.label}, ${formatCents(entry.cents)}, '
                    '$title, ${entry.category.label}. Toque para editar.',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    Text(
                      entry.category.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      amount,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Excluir lançamento',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({required this.entry, required this.month});
  final ExpenseEntry? entry;
  final MonthRef month;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late EntryType _type = widget.entry?.type ?? EntryType.expense;
  late ExpenseCategory _category =
      widget.entry?.category ?? ExpenseCategory.other;
  late DateTime _date = widget.entry?.date ?? _defaultDate();
  late final TextEditingController _value = TextEditingController(
    text: widget.entry == null ? '' : centsToInput(widget.entry!.cents),
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.entry?.description ?? '',
  );
  String? _error;

  DateTime _defaultDate() {
    final now = DateTime.now();
    return widget.month.contains(now)
        ? dateOnly(now)
        : DateTime(widget.month.year, widget.month.month);
  }

  @override
  void dispose() {
    _value.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = dateOnly(d));
  }

  void _submit() {
    final cents = parseCents(_value.text);
    if (cents == null) {
      setState(() => _error = 'Informe um valor maior que zero, ex.: 25,90');
      return;
    }
    Navigator.pop(
      context,
      _Draft(_type, cents, _desc.text.trim(), _category, _date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        0,
        Spacing.md,
        Spacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              editing ? 'Editar lançamento' : 'Novo lançamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: Spacing.md),
          SegmentedButton<EntryType>(
            showSelectedIcon: false,
            segments: [
              for (final t in EntryType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _value,
            autofocus: !editing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Valor',
              prefixText: r'R$ ',
              errorText: _error,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _desc,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: [
              for (final c in ExpenseCategory.values)
                DropdownMenuItem(value: c, child: Text(c.label)),
            ],
            onChanged: (c) => setState(() => _category = c ?? _category),
          ),
          const SizedBox(height: Spacing.md),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Data: ${formatDate(_date)}'),
          ),
          const SizedBox(height: Spacing.lg),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _submit,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
