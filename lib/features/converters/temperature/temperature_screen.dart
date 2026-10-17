import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../units/unit_converter_screen.dart';
import '../units/unit_model.dart';

// Fator é ignorado aqui: a conversão usa fórmulas próprias via Kelvin.
final temperatureUnits = <ConversionUnit>[
  ConversionUnit(id: 'c', name: 'Celsius', symbol: '°C', factor: dec('1')),
  ConversionUnit(id: 'f', name: 'Fahrenheit', symbol: '°F', factor: dec('1')),
  ConversionUnit(id: 'k', name: 'Kelvin', symbol: 'K', factor: dec('1')),
];

final _k0 = dec('273.15');
final _nine = dec('9');
final _five = dec('5');
final _f0 = dec('459.67');

/// Converte para Kelvin (exato).
Decimal toKelvin(Decimal v, String unitId) => switch (unitId) {
  'c' => v + _k0,
  'f' => ((v + _f0) * _five / _nine).toDecimal(scaleOnInfinitePrecision: 20),
  _ => v,
};

Decimal fromKelvin(Decimal k, String unitId) => switch (unitId) {
  'c' => k - _k0,
  'f' => (k * _nine / _five).toDecimal(scaleOnInfinitePrecision: 20) - _f0,
  _ => k,
};

Decimal convertTemperature(
  Decimal value,
  ConversionUnit from,
  ConversionUnit to,
) {
  if (from.id == to.id) return value;
  return fromKelvin(toKelvin(value, from.id), to.id);
}

/// Mensagem de erro se [value] estiver abaixo do zero absoluto.
String? validateTemperature(Decimal value, ConversionUnit from) {
  if (toKelvin(value, from.id) >= Decimal.zero) return null;
  const limite = {'c': '−273,15 °C', 'f': '−459,67 °F', 'k': '0 K'};
  return 'Temperatura abaixo do zero absoluto (${limite[from.id]}). '
      'Informe um valor maior ou igual a ele.';
}

class TemperatureScreen extends StatelessWidget {
  const TemperatureScreen({super.key});

  @override
  Widget build(BuildContext context) => UnitConverterScreen(
    title: 'Temperatura',
    units: temperatureUnits,
    initialFromId: 'c',
    initialToId: 'f',
    allowNegative: true,
    convert: convertTemperature,
    validate: validateTemperature,
  );
}
