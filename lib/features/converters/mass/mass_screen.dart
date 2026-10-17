import 'package:flutter/material.dart';

import '../units/unit_converter_screen.dart';
import '../units/unit_model.dart';

/// Unidades de massa; fator = quilogramas por unidade (exato).
final massUnits = <ConversionUnit>[
  ConversionUnit(id: 'kg', name: 'Quilograma', symbol: 'kg', factor: dec('1')),
  ConversionUnit(id: 'g', name: 'Grama', symbol: 'g', factor: dec('0.001')),
  ConversionUnit(
    id: 'mg',
    name: 'Miligrama',
    symbol: 'mg',
    factor: dec('0.000001'),
  ),
  ConversionUnit(
    id: 'lb',
    name: 'Libra',
    symbol: 'lb',
    factor: dec('0.45359237'),
  ),
  ConversionUnit(
    id: 'oz',
    name: 'Onça',
    symbol: 'oz',
    factor: dec('0.028349523125'),
  ),
];

class MassScreen extends StatelessWidget {
  const MassScreen({super.key});

  @override
  Widget build(BuildContext context) => UnitConverterScreen(
    title: 'Massa',
    units: massUnits,
    initialFromId: 'kg',
    initialToId: 'lb',
  );
}
