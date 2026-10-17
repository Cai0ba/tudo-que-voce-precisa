import 'package:flutter/material.dart';

import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/calc_support.dart';
import '../shared/calc_widgets.dart';
import 'age_calculator.dart';

class AgeScreen extends StatefulWidget {
  /// [today] permite fixar a data de referência (testes); padrão: agora.
  const AgeScreen({this.today, super.key});
  final DateTime? today;

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  DateTime? _birth;

  DateTime get _today {
    final t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _plural(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';

  Future<void> _pick() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(today.year - 30, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Data de nascimento',
    );
    if (picked != null && mounted) setState(() => _birth = picked);
  }

  Widget _result() {
    final birth = _birth;
    if (birth == null) {
      return const EmptyHint('Escolha a data de nascimento.');
    }
    try {
      final r = AgeCalculator.calculate(birth: birth, today: _today);
      final years = _plural(r.years, 'ano', 'anos');
      return ResultCard(
        label: 'Sua idade',
        value: years,
        detail:
            '$years, ${_plural(r.months, 'mês', 'meses')} e '
            '${_plural(r.days, 'dia', 'dias')}\n'
            'Total: ${_plural(r.totalDays, 'dia', 'dias')} de vida',
      );
    } on CalcException catch (e) {
      return LiveError(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birth = _birth;
    return ToolScaffold(
      title: 'Idade',
      children: [
        SectionCard(
          title: 'Data de nascimento',
          children: [
            Semantics(
              button: true,
              label: birth == null
                  ? 'Escolher data de nascimento'
                  : 'Data de nascimento: ${_fmt(birth)}. Toque para alterar',
              excludeSemantics: true,
              child: OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  birth == null ? 'Escolher data de nascimento' : _fmt(birth),
                ),
              ),
            ),
          ],
        ),
        _result(),
      ],
    );
  }
}
