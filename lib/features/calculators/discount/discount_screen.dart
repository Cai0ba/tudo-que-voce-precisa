import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/calc_support.dart';
import '../shared/calc_widgets.dart';
import 'discount_calculator.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final _price = TextEditingController();
  final _percent = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    _percent.dispose();
    super.dispose();
  }

  Widget _result() {
    try {
      final price = readField(_price.text, 'Preço');
      final percent = readField(_percent.text, 'Desconto');
      if (price == null || percent == null) {
        return const EmptyHint('Informe o preço e o desconto.');
      }
      final r = DiscountCalculator.apply(price, percent);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.md,
        children: [
          ResultCard(label: 'Preço final', value: formatBrl(r.finalPrice)),
          ResultCard(label: 'Você economiza', value: formatBrl(r.saved)),
        ],
      );
    } on CalcException catch (e) {
      return LiveError(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Descontos',
      children: [
        SectionCard(
          title: 'Dados da compra',
          children: [
            NumberField(
              controller: _price,
              label: 'Preço',
              suffix: r'R$',
              onChanged: (_) => setState(() {}),
            ),
            NumberField(
              controller: _percent,
              label: 'Desconto',
              suffix: '%',
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        _result(),
      ],
    );
  }
}
