import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import 'from_to_row.dart';
import 'unit_model.dart';

/// Converte [value] de [from] para [to].
typedef UnitConvert = Decimal Function(
  Decimal value,
  ConversionUnit from,
  ConversionUnit to,
);

/// Valida [value] na unidade [from]; retorna mensagem de erro ou null.
typedef UnitValidate = String? Function(Decimal value, ConversionUnit from);

/// Tela genérica de conversão: valor, unidade de origem/destino, inverter
/// e resultado. Por padrão faz conversão linear pelos fatores das unidades.
class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({
    required this.title,
    required this.units,
    required this.initialFromId,
    required this.initialToId,
    this.allowNegative = false,
    this.convert = convertLinear,
    this.validate,
    super.key,
  });

  final String title;
  final List<ConversionUnit> units;
  final String initialFromId;
  final String initialToId;
  final bool allowNegative;
  final UnitConvert convert;
  final UnitValidate? validate;

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final _controller = TextEditingController();
  late ConversionUnit _from = _byId(widget.initialFromId);
  late ConversionUnit _to = _byId(widget.initialToId);

  ConversionUnit _byId(String id) => widget.units.firstWhere((u) => u.id == id);

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
    var out = formatDecimal(v, maxFractionDigits: 6);
    if (v != Decimal.zero && (out == '0' || out == '-0')) {
      out = formatDecimal(v, maxFractionDigits: 12);
    }
    return out;
  }

  /// Retorna (mensagem neutra/erro, resultado).
  Widget _result() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            IconBadge(Icons.edit_outlined, size: 40),
            SizedBox(width: Spacing.md),
            Expanded(child: Text('Digite um valor para converter.')),
          ],
        ),
      );
    }
    final value = parseDecimal(text);
    if (value == null) {
      return const ErrorBanner('Valor inválido. Use apenas números, ex.: 12,5');
    }
    if (!widget.allowNegative && value < Decimal.zero) {
      return const ErrorBanner('Informe um valor igual ou maior que zero.');
    }
    final error = widget.validate?.call(value, _from);
    if (error != null) return ErrorBanner(error);
    final result = widget.convert(value, _from, _to);
    return ResultCard(
      label: 'Resultado',
      value: '${_format(result)} ${_to.symbol}',
      detail:
          '${_format(value)} ${_from.symbol} = '
          '${_format(result)} ${_to.symbol}',
    );
  }

  Widget _selector(
    Key key,
    String label,
    ConversionUnit value,
    ValueChanged<ConversionUnit> onChanged,
  ) {
    return DropdownButtonFormField<ConversionUnit>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final u in widget.units)
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
    return ToolScaffold(
      title: widget.title,
      children: [
        SectionCard(
          title: 'Valor',
          children: [
            NumberField(
              controller: _controller,
              label: 'Valor',
              suffix: _from.symbol,
              signed: widget.allowNegative,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        FromToRow(
          swapKey: const ValueKey('swap'),
          swapTooltip: 'Inverter unidades',
          onSwap: _swap,
          from: _selector(
            ValueKey('from-${_from.id}'),
            'De',
            _from,
            (u) => _from = u,
          ),
          to: _selector(ValueKey('to-${_to.id}'), 'Para', _to, (u) => _to = u),
        ),
        _result(),
      ],
    );
  }
}
