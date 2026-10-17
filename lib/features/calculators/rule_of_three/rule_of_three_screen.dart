import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/calc_support.dart';
import '../shared/calc_widgets.dart';
import 'rule_of_three_calculator.dart';

class RuleOfThreeScreen extends StatefulWidget {
  const RuleOfThreeScreen({super.key});

  @override
  State<RuleOfThreeScreen> createState() => _RuleOfThreeScreenState();
}

class _RuleOfThreeScreenState extends State<RuleOfThreeScreen> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  final _c = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    _c.dispose();
    super.dispose();
  }

  Widget _result() {
    try {
      final a = readField(_a.text, 'A');
      final b = readField(_b.text, 'B');
      final c = readField(_c.text, 'C');
      if (a == null || b == null || c == null) {
        return const EmptyHint('Preencha A, B e C para ver o resultado.');
      }
      final x = RuleOfThreeCalculator.solve(a, b, c);
      String f(Decimal v) => formatDecimal(v, maxFractionDigits: 4);
      return ResultCard(
        label: '${f(a)} está para ${f(b)} assim como ${f(c)} está para ?',
        value: f(x),
        detail:
            'Conta: (${f(b)} × ${f(c)}) ÷ ${f(a)} = ${f(x)}. '
            'Se A vira C, B vira X na mesma proporção.',
      );
    } on CalcException catch (e) {
      return LiveError(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Regra de três',
      children: [
        SectionCard(
          title: 'A está para B assim como C está para ?',
          children: [
            NumberField(
              controller: _a,
              label: 'A',
              onChanged: (_) => setState(() {}),
            ),
            NumberField(
              controller: _b,
              label: 'B',
              onChanged: (_) => setState(() {}),
            ),
            NumberField(
              controller: _c,
              label: 'C',
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        _result(),
      ],
    );
  }
}
