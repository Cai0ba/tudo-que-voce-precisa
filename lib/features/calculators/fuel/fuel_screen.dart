import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/calc_support.dart';
import '../shared/calc_widgets.dart';
import 'fuel_calculator.dart';

enum _Mode { compare, consumption, trip }

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  _Mode _mode = _Mode.compare;
  bool _advanced = false;
  bool _roundTrip = false;

  final _ethanol = TextEditingController();
  final _gasoline = TextEditingController();
  final _limit = TextEditingController(text: '70');
  final _ethanolKm = TextEditingController();
  final _gasolineKm = TextEditingController();
  final _distance = TextEditingController();
  final _liters = TextEditingController();
  final _tripDistance = TextEditingController();
  final _tripKm = TextEditingController();
  final _tripPrice = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _ethanol,
      _gasoline,
      _limit,
      _ethanolKm,
      _gasolineKm,
      _distance,
      _liters,
      _tripDistance,
      _tripKm,
      _tripPrice,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh([String? _]) => setState(() {});

  NumberField _field(TextEditingController c, String label, String suffix) =>
      NumberField(
        controller: c,
        label: label,
        suffix: suffix,
        onChanged: _refresh,
      );

  String _brl3(Decimal v) => 'R\$ ${formatDecimal(v, maxFractionDigits: 3)}';

  Widget _compareResult() {
    final e = readField(_ethanol.text, 'Preço do etanol');
    final g = readField(_gasoline.text, 'Preço da gasolina');
    if (e == null || g == null) {
      return const EmptyHint('Informe o preço do etanol e o da gasolina.');
    }
    Decimal? limit;
    Decimal? ek;
    Decimal? gk;
    if (_advanced) {
      limit = readField(_limit.text, 'Limite');
      ek = readField(_ethanolKm.text, 'Consumo com etanol');
      gk = readField(_gasolineKm.text, 'Consumo com gasolina');
    }
    final r = FuelCalculator.compare(
      ethanolPrice: e,
      gasolinePrice: g,
      limitPercent: limit,
      ethanolKmPerL: ek,
      gasolineKmPerL: gk,
    );
    final limitText = formatDecimal(
      limit ?? FuelCalculator.defaultLimitPercent,
    );
    final detail = r.byCostPerKm
        ? 'Etanol: ${_brl3(r.ethanolCostPerKm!)} por km. '
              'Gasolina: ${_brl3(r.gasolineCostPerKm!)} por km.'
        : 'O etanol compensa quando custa até $limitText% do preço da gasolina.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.md,
      children: [
        Semantics(
          liveRegion: true,
          child: ResultCard(
            label: 'Melhor opção',
            value: r.ethanolWins
                ? 'Abasteça com etanol'
                : 'Abasteça com gasolina',
            detail: detail,
          ),
        ),
        ResultCard(
          label: 'Etanol / gasolina',
          value: '${formatDecimal(r.ratioPercent, maxFractionDigits: 1)}%',
        ),
        const InfoNote(
          'É uma aproximação: o consumo real varia de carro para carro. '
          'Para um resultado mais fiel, informe o consumo de cada combustível.',
        ),
      ],
    );
  }

  Widget _consumptionResult() {
    final d = readField(_distance.text, 'Distância');
    final l = readField(_liters.text, 'Litros');
    if (d == null || l == null) {
      return const EmptyHint('Informe a distância e os litros abastecidos.');
    }
    final r = FuelCalculator.consumption(d, l);
    return ResultCard(label: 'Consumo', value: '${formatDecimal(r)} km/l');
  }

  Widget _tripResult() {
    final d = readField(_tripDistance.text, 'Distância');
    final k = readField(_tripKm.text, 'Consumo');
    final p = readField(_tripPrice.text, 'Preço do litro');
    if (d == null || k == null || p == null) {
      return const EmptyHint(
        'Informe a distância, o consumo e o preço do litro.',
      );
    }
    final r = FuelCalculator.trip(
      distanceKm: d,
      kmPerL: k,
      pricePerLiter: p,
      roundTrip: _roundTrip,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.md,
      children: [
        ResultCard(label: 'Custo total', value: formatBrl(r.cost)),
        ResultCard(
          label: 'Litros necessários',
          value: '${formatDecimal(r.liters)} l',
          detail: 'Distância considerada: ${formatDecimal(r.distance)} km',
        ),
      ],
    );
  }

  Widget _result() {
    try {
      return switch (_mode) {
        _Mode.compare => _compareResult(),
        _Mode.consumption => _consumptionResult(),
        _Mode.trip => _tripResult(),
      };
    } on CalcException catch (e) {
      return LiveError(e.message);
    }
  }

  List<Widget> _inputs() {
    switch (_mode) {
      case _Mode.compare:
        return [
          _field(_ethanol, 'Preço do etanol', r'R$/l'),
          _field(_gasoline, 'Preço da gasolina', r'R$/l'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ajustes avançados'),
            subtitle: const Text('Limite e consumo de cada combustível'),
            value: _advanced,
            onChanged: (v) => setState(() => _advanced = v),
          ),
          if (_advanced) ...[
            _field(_limit, 'Limite', '%'),
            _field(_ethanolKm, 'Consumo com etanol (opcional)', 'km/l'),
            _field(_gasolineKm, 'Consumo com gasolina (opcional)', 'km/l'),
          ],
        ];
      case _Mode.consumption:
        return [
          _field(_distance, 'Distância', 'km'),
          _field(_liters, 'Litros', 'l'),
        ];
      case _Mode.trip:
        return [
          _field(_tripDistance, 'Distância', 'km'),
          _field(_tripKm, 'Consumo', 'km/l'),
          _field(_tripPrice, 'Preço do litro', r'R$'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ida e volta'),
            value: _roundTrip,
            onChanged: (v) => setState(() => _roundTrip = v),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Combustível',
      children: [
        SectionCard(
          title: 'O que calcular',
          children: [
            ChoiceChipGroup<_Mode>(
              semanticLabel: 'Modo de cálculo',
              selected: _mode,
              onSelected: (m) => setState(() => _mode = m),
              options: const [
                (_Mode.compare, 'Álcool × gasolina'),
                (_Mode.consumption, 'Consumo'),
                (_Mode.trip, 'Custo de viagem'),
              ],
            ),
          ],
        ),
        SectionCard(title: 'Dados', children: _inputs()),
        _result(),
      ],
    );
  }
}
