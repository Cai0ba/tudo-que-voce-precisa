import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/picker_tile.dart';
import 'date_difference.dart';

class DateDifferenceScreen extends StatefulWidget {
  const DateDifferenceScreen({super.key});

  @override
  State<DateDifferenceScreen> createState() => _DateDifferenceScreenState();
}

class _DateDifferenceScreenState extends State<DateDifferenceScreen> {
  DateTime? _start;
  DateTime? _end;

  Future<DateTime?> _pick(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime(2200),
  );

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static String _plural(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';

  @override
  Widget build(BuildContext context) {
    final s = _start, e = _end;
    final diff = (s != null && e != null) ? dateDifference(s, e) : null;
    return ToolScaffold(
      title: 'Diferença entre datas',
      children: [
        PickerTile(
          icon: Icons.event,
          label: 'Data de início',
          value: s == null ? null : _fmt(s),
          onTap: () async {
            final d = await _pick(s);
            if (d != null) setState(() => _start = d);
          },
        ),
        PickerTile(
          icon: Icons.event_available,
          label: 'Data de fim',
          value: e == null ? null : _fmt(e),
          onTap: () async {
            final d = await _pick(e);
            if (d != null) setState(() => _end = d);
          },
        ),
        if (diff == null)
          const Text('Escolha as duas datas para ver a diferença.')
        else ...[
          if (diff.inverted)
            const ErrorBanner(
              'O fim é anterior ao início. Mostrando a diferença absoluta '
              'entre as datas.',
            ),
          ResultCard(
            label: 'Período (${_fmt(diff.start)} a ${_fmt(diff.end)})',
            value:
                '${_plural(diff.years, 'ano', 'anos')}, '
                '${_plural(diff.months, 'mês', 'meses')} e '
                '${_plural(diff.days, 'dia', 'dias')}',
            detail: 'Total: ${_plural(diff.totalDays, 'dia', 'dias')}',
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _StatBlock(diff.years, 'anos', 'ano')),
                const SizedBox(width: Spacing.sm),
                Expanded(child: _StatBlock(diff.months, 'meses', 'mês')),
                const SizedBox(width: Spacing.sm),
                Expanded(child: _StatBlock(diff.days, 'dias', 'dia')),
              ],
            ),
          ),
          AppCard(
            child: Row(
              children: [
                const IconBadge(Icons.calendar_month),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Semantics(
                    container: true,
                    label: 'Total de dias: ${diff.totalDays}',
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total de dias',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            '${diff.totalDays}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bloco numérico (anos, meses ou dias).
class _StatBlock extends StatelessWidget {
  const _StatBlock(this.value, this.plural, this.singular);
  final int value;
  final String plural, singular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = value == 1 ? singular : plural;
    return Semantics(
      container: true,
      label: '$value $unit',
      child: ExcludeSemantics(
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.sm,
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(unit, style: theme.textTheme.labelMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
