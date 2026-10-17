import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../units/from_to_row.dart';
import 'cooking_converter.dart';
import 'cooking_data.dart';

/// Conversor de medidas culinárias (xícara, colheres, mL, L e gramas) com
/// seletor de ingrediente.
class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key});

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  final _controller = TextEditingController();
  CookingUnit _from = cookingUnits.first;
  CookingUnit _to = cookingUnits.last;
  Ingredient _ingredient = ingredients.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _swap() => setState(() {
    final t = _from;
    _from = _to;
    _to = t;
  });

  static String _format(Decimal v) {
    var out = formatDecimal(v, maxFractionDigits: 3);
    if (v != Decimal.zero && (out == '0' || out == '-0')) {
      out = formatDecimal(v, maxFractionDigits: 8);
    }
    return out;
  }

  Widget _result() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            IconBadge(Icons.edit_outlined, size: 40),
            SizedBox(width: Spacing.md),
            Expanded(child: Text('Digite uma quantidade para converter.')),
          ],
        ),
      );
    }
    final value = parseDecimal(text);
    if (value == null) {
      return const ErrorBanner('Valor inválido. Use apenas números, ex.: 1,5');
    }
    if (value < Decimal.zero) {
      return const ErrorBanner('Informe um valor igual ou maior que zero.');
    }
    final result = convertCooking(value, _from, _to, _ingredient);
    final involvesMass = _from.isMass || _to.isMass;
    return ResultCard(
      label: 'Resultado',
      value: '${_format(result)} ${_to.symbol}',
      detail:
          '${_format(value)} ${_from.symbol} = '
          '${_format(result)} ${_to.symbol}'
          '${involvesMass ? ' (${_ingredient.name.toLowerCase()})' : ''}',
    );
  }

  Widget _unitSelector(
    Key key,
    String label,
    CookingUnit value,
    ValueChanged<CookingUnit> onChanged,
  ) {
    return DropdownButtonFormField<CookingUnit>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final u in cookingUnits)
          DropdownMenuItem(
            value: u,
            child: Text(u.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (u) {
        if (u != null) setState(() => onChanged(u));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      title: 'Culinária',
      children: [
        SectionCard(
          title: 'Quantidade',
          children: [
            NumberField(
              controller: _controller,
              label: 'Quantidade',
              suffix: _from.symbol,
              onChanged: (_) => setState(() {}),
            ),
            DropdownButtonFormField<Ingredient>(
              key: ValueKey('ingredient-${_ingredient.id}'),
              initialValue: _ingredient,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ingrediente'),
              items: [
                for (final i in ingredients)
                  DropdownMenuItem(
                    value: i,
                    child: Text(i.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (i) {
                if (i != null) setState(() => _ingredient = i);
              },
            ),
          ],
        ),
        FromToRow(
          swapKey: const ValueKey('swap'),
          swapTooltip: 'Inverter unidades',
          onSwap: _swap,
          from: _unitSelector(
            ValueKey('from-${_from.id}'),
            'De',
            _from,
            (u) => _from = u,
          ),
          to: _unitSelector(
            ValueKey('to-${_to.id}'),
            'Para',
            _to,
            (u) => _to = u,
          ),
        ),
        _result(),
        AppCard(
          child: Semantics(
            container: true,
            label: 'Aviso: $cookingDisclaimer',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBadge(Icons.info_outline, size: 40),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      '$cookingDisclaimer\n\nReferência: xícara de chá = '
                      '240 mL; colher de sopa = 15 mL; colher de chá = 5 mL.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
