import 'package:flutter/material.dart';

import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/calc_support.dart';
import '../shared/calc_widgets.dart';
import 'bmi_calculator.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  HeightUnit _unit = HeightUnit.centimeters;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Widget _result() {
    try {
      final w = readField(_weight.text, 'Peso');
      final h = readField(_height.text, 'Altura');
      if (w == null || h == null) {
        return const EmptyHint('Informe peso e altura.');
      }
      final r = BmiCalculator.calculate(weightKg: w, height: h, unit: _unit);
      return ResultCard(
        label: 'Seu IMC',
        value: formatDecimal(r.bmi, maxFractionDigits: 1),
        detail: 'Faixa da OMS para adultos: ${r.category.label}',
      );
    } on CalcException catch (e) {
      return LiveError(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'IMC',
      children: [
        SectionCard(
          title: 'Seus dados',
          children: [
            NumberField(
              controller: _weight,
              label: 'Peso',
              suffix: 'kg',
              onChanged: (_) => setState(() {}),
            ),
            ChoiceChipGroup<HeightUnit>(
              semanticLabel: 'Unidade da altura',
              selected: _unit,
              onSelected: (u) => setState(() => _unit = u),
              options: const [
                (HeightUnit.centimeters, 'Centímetros'),
                (HeightUnit.meters, 'Metros'),
              ],
            ),
            NumberField(
              controller: _height,
              label: 'Altura',
              suffix: _unit == HeightUnit.meters ? 'm' : 'cm',
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        _result(),
        const InfoNote(
          'O IMC é apenas uma referência para adultos (18 anos ou mais). '
          'Não é um diagnóstico e não substitui a avaliação de um '
          'profissional de saúde.',
        ),
      ],
    );
  }
}
