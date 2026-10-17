import 'package:flutter/material.dart';

import '../units/unit_converter_screen.dart';
import '../units/unit_model.dart';

/// Unidades de volume; fator = litros por unidade (exato).
/// Xícara, colher de sopa e onça fluida são as medidas americanas
/// (1 gal = 16 xícaras = 256 colheres de sopa = 128 fl oz).
final volumeUnits = <ConversionUnit>[
  ConversionUnit(id: 'l', name: 'Litro', symbol: 'L', factor: dec('1')),
  ConversionUnit(
    id: 'ml',
    name: 'Mililitro',
    symbol: 'mL',
    factor: dec('0.001'),
  ),
  ConversionUnit(
    id: 'm3',
    name: 'Metro cúbico',
    symbol: 'm³',
    factor: dec('1000'),
  ),
  ConversionUnit(
    id: 'gal',
    name: 'Galão americano',
    symbol: 'gal',
    factor: dec('3.785411784'),
  ),
  ConversionUnit(
    id: 'cup',
    name: 'Xícara americana',
    symbol: 'xíc',
    factor: dec('0.2365882365'),
  ),
  ConversionUnit(
    id: 'tbsp',
    name: 'Colher de sopa americana',
    symbol: 'colher',
    factor: dec('0.01478676478125'),
  ),
  ConversionUnit(
    id: 'floz',
    name: 'Onça fluida americana',
    symbol: 'fl oz',
    factor: dec('0.0295735295625'),
  ),
];

class VolumeScreen extends StatelessWidget {
  const VolumeScreen({super.key});

  @override
  Widget build(BuildContext context) => UnitConverterScreen(
    title: 'Volume',
    units: volumeUnits,
    initialFromId: 'l',
    initialToId: 'ml',
  );
}
