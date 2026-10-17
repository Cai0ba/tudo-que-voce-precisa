import 'package:decimal/decimal.dart';

import '../shared/calc_support.dart';

enum HeightUnit { meters, centimeters }

/// Faixas adultas da OMS.
enum BmiCategory {
  underweight('Abaixo do peso'),
  normal('Peso normal'),
  overweight('Sobrepeso'),
  obesity1('Obesidade grau I'),
  obesity2('Obesidade grau II'),
  obesity3('Obesidade grau III');

  const BmiCategory(this.label);
  final String label;
}

class BmiResult {
  const BmiResult({required this.bmi, required this.category});

  /// IMC arredondado a 1 casa (meio para cima); a classificação usa este valor.
  final Decimal bmi;
  final BmiCategory category;
}

/// Domínio puro do IMC (kg / m²), apenas para adultos.
abstract final class BmiCalculator {
  static BmiResult calculate({
    required Decimal weightKg,
    required Decimal height,
    required HeightUnit unit,
  }) {
    if (weightKg <= Decimal.zero) {
      throw const CalcException('O peso precisa ser maior que zero.');
    }
    if (weightKg > Decimal.fromInt(500)) {
      throw const CalcException(
        'Peso fora do intervalo possível (até 500 kg).',
      );
    }
    if (height <= Decimal.zero) {
      throw const CalcException('A altura precisa ser maior que zero.');
    }
    final meters = unit == HeightUnit.centimeters
        ? divide(height, Decimal.fromInt(100))
        : height;
    if (meters < Decimal.parse('0.5') || meters > Decimal.parse('2.5')) {
      throw CalcException(
        unit == HeightUnit.centimeters
            ? 'Altura fora do intervalo possível (50 a 250 cm).'
            : 'Altura fora do intervalo possível (0,50 a 2,50 m).',
      );
    }
    final bmi = roundTo(divide(weightKg, meters * meters), 1);
    return BmiResult(bmi: bmi, category: classify(bmi));
  }

  static BmiCategory classify(Decimal bmi) {
    if (bmi < Decimal.parse('18.5')) return BmiCategory.underweight;
    if (bmi < Decimal.fromInt(25)) return BmiCategory.normal;
    if (bmi < Decimal.fromInt(30)) return BmiCategory.overweight;
    if (bmi < Decimal.fromInt(35)) return BmiCategory.obesity1;
    if (bmi < Decimal.fromInt(40)) return BmiCategory.obesity2;
    return BmiCategory.obesity3;
  }
}
