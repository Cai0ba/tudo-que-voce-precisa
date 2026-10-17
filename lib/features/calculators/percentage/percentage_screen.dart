import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/calc_support.dart';
import '../shared/calc_widgets.dart';
import 'percentage_calculator.dart';

enum _Mode { percentOf, whatPercent, increase, decrease }

class PercentageScreen extends StatefulWidget {
  const PercentageScreen({super.key});

  @override
  State<PercentageScreen> createState() => _PercentageScreenState();
}

class _PercentageScreenState extends State<PercentageScreen> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  _Mode _mode = _Mode.percentOf;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  (String, String) get _labels => switch (_mode) {
    _Mode.percentOf => ('Porcentagem (X)', 'Valor (Y)'),
    _Mode.whatPercent => ('Valor X', 'Valor Y'),
    _Mode.increase => ('Valor inicial', 'Aumento'),
    _Mode.decrease => ('Valor inicial', 'Redução'),
  };

  String? get _suffixA => _mode == _Mode.percentOf ? '%' : null;
  String? get _suffixB =>
      (_mode == _Mode.increase || _mode == _Mode.decrease) ? '%' : null;

  Widget _result() {
    try {
      final a = readField(_a.text, _labels.$1);
      final b = readField(_b.text, _labels.$2);
      if (a == null || b == null) {
        return const EmptyHint('Preencha os dois campos para ver o resultado.');
      }
      String fmt(Decimal v) => formatDecimal(v);
      switch (_mode) {
        case _Mode.percentOf:
          final r = PercentageCalculator.percentOf(a, b);
          return ResultCard(
            label: '${fmt(a)}% de ${fmt(b)}',
            value: fmt(r),
            detail: '${fmt(b)} × ${fmt(a)} ÷ 100',
          );
        case _Mode.whatPercent:
          final r = PercentageCalculator.whatPercent(a, b);
          return ResultCard(
            label: '${fmt(a)} é quanto % de ${fmt(b)}',
            value: '${fmt(r)}%',
            detail: '${fmt(a)} ÷ ${fmt(b)} × 100',
          );
        case _Mode.increase:
          final r = PercentageCalculator.increase(a, b);
          return ResultCard(
            label: '${fmt(a)} com aumento de ${fmt(b)}%',
            value: fmt(r),
            detail: 'Diferença: ${fmt(r - a)}',
          );
        case _Mode.decrease:
          final r = PercentageCalculator.decrease(a, b);
          return ResultCard(
            label: '${fmt(a)} com redução de ${fmt(b)}%',
            value: fmt(r),
            detail: 'Diferença: ${fmt(a - r)}',
          );
      }
    } on CalcException catch (e) {
      return LiveError(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    return ToolScaffold(
      title: 'Porcentagem',
      children: [
        SectionCard(
          title: 'Tipo de cálculo',
          children: [
            ChoiceChipGroup<_Mode>(
              semanticLabel: 'Tipo de cálculo de porcentagem',
              selected: _mode,
              onSelected: (m) => setState(() => _mode = m),
              options: const [
                (_Mode.percentOf, 'X% de Y'),
                (_Mode.whatPercent, 'Quanto %'),
                (_Mode.increase, 'Aumento'),
                (_Mode.decrease, 'Redução'),
              ],
            ),
          ],
        ),
        SectionCard(
          title: 'Valores',
          children: [
            NumberField(
              controller: _a,
              label: labels.$1,
              suffix: _suffixA,
              onChanged: (_) => setState(() {}),
            ),
            NumberField(
              controller: _b,
              label: labels.$2,
              suffix: _suffixB,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        _result(),
      ],
    );
  }
}
