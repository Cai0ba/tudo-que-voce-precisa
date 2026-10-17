import 'package:flutter/material.dart';

import '../units/unit_converter_screen.dart';
import '../units/unit_model.dart';

/// Unidades de comprimento; fator = metros por unidade (exato).
final lengthUnits = <ConversionUnit>[
  ConversionUnit(id: 'm', name: 'Metro', symbol: 'm', factor: dec('1')),
  ConversionUnit(
    id: 'km',
    name: 'Quilômetro',
    symbol: 'km',
    factor: dec('1000'),
  ),
  ConversionUnit(
    id: 'cm',
    name: 'Centímetro',
    symbol: 'cm',
    factor: dec('0.01'),
  ),
  ConversionUnit(
    id: 'mm',
    name: 'Milímetro',
    symbol: 'mm',
    factor: dec('0.001'),
  ),
  ConversionUnit(
    id: 'in',
    name: 'Polegada',
    symbol: 'in',
    factor: dec('0.0254'),
  ),
  ConversionUnit(id: 'ft', name: 'Pé', symbol: 'ft', factor: dec('0.3048')),
  ConversionUnit(id: 'yd', name: 'Jarda', symbol: 'yd', factor: dec('0.9144')),
  ConversionUnit(
    id: 'mi',
    name: 'Milha',
    symbol: 'mi',
    factor: dec('1609.344'),
  ),
];

class LengthScreen extends StatelessWidget {
  const LengthScreen({super.key});

  @override
  Widget build(BuildContext context) => UnitConverterScreen(
    title: 'Comprimento',
    units: lengthUnits,
    initialFromId: 'm',
    initialToId: 'ft',
  );
}
