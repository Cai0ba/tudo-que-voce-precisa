import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/features/calculators/age/age_calculator.dart';
import 'package:tqvp/features/calculators/bmi/bmi_calculator.dart';
import 'package:tqvp/features/calculators/discount/discount_calculator.dart';
import 'package:tqvp/features/calculators/percentage/percentage_calculator.dart';
import 'package:tqvp/features/calculators/rule_of_three/rule_of_three_calculator.dart';
import 'package:tqvp/features/calculators/shared/calc_support.dart';

Decimal d(String s) => Decimal.parse(s);
Matcher get throwsCalc => throwsA(isA<CalcException>());

void main() {
  group('porcentagem', () {
    test('X% de Y', () {
      expect(PercentageCalculator.percentOf(d('15'), d('200')), d('30'));
      expect(PercentageCalculator.percentOf(d('0'), d('200')), d('0'));
      expect(PercentageCalculator.percentOf(d('33.333'), d('100')), d('33.33'));
      expect(PercentageCalculator.percentOf(d('0.005'), d('100')), d('0.01'));
    });
    test('quanto % X é de Y', () {
      expect(PercentageCalculator.whatPercent(d('50'), d('200')), d('25'));
      expect(PercentageCalculator.whatPercent(d('1'), d('3')), d('33.33'));
      expect(PercentageCalculator.whatPercent(d('300'), d('100')), d('300'));
      expect(
        () => PercentageCalculator.whatPercent(d('1'), d('0')),
        throwsCalc,
      );
    });
    test('aumento e redução', () {
      expect(PercentageCalculator.increase(d('100'), d('10')), d('110'));
      expect(PercentageCalculator.decrease(d('100'), d('10')), d('90'));
      expect(PercentageCalculator.decrease(d('100'), d('100')), d('0'));
      expect(
        () => PercentageCalculator.decrease(d('100'), d('101')),
        throwsCalc,
      );
    });
    test('rejeita negativos', () {
      expect(
        () => PercentageCalculator.percentOf(d('-1'), d('10')),
        throwsCalc,
      );
      expect(() => PercentageCalculator.increase(d('-5'), d('10')), throwsCalc);
    });
  });

  group('desconto', () {
    test('cálculo e soma consistente', () {
      final r = DiscountCalculator.apply(d('199.90'), d('15'));
      expect(r.saved, d('29.99')); // 29.985 -> meio para cima
      expect(r.finalPrice, d('169.91'));
      expect(r.saved + r.finalPrice, d('199.90'));
    });
    test('extremos', () {
      expect(DiscountCalculator.apply(d('50'), d('0')).finalPrice, d('50'));
      expect(DiscountCalculator.apply(d('50'), d('100')).finalPrice, d('0'));
      expect(DiscountCalculator.apply(d('0'), d('30')).saved, d('0'));
    });
    test('rejeições', () {
      expect(() => DiscountCalculator.apply(d('-1'), d('10')), throwsCalc);
      expect(() => DiscountCalculator.apply(d('10'), d('-1')), throwsCalc);
      expect(() => DiscountCalculator.apply(d('10'), d('100.01')), throwsCalc);
    });
  });

  group('regra de três', () {
    test('resolve', () {
      expect(RuleOfThreeCalculator.solve(d('2'), d('10'), d('6')), d('30'));
      expect(RuleOfThreeCalculator.solve(d('3'), d('1'), d('1')), d('0.3333'));
      expect(RuleOfThreeCalculator.solve(d('5'), d('0'), d('6')), d('0'));
    });
    test('A zero e negativos', () {
      expect(
        () => RuleOfThreeCalculator.solve(d('0'), d('1'), d('1')),
        throwsCalc,
      );
      expect(
        () => RuleOfThreeCalculator.solve(d('1'), d('-1'), d('1')),
        throwsCalc,
      );
    });
  });

  group('IMC', () {
    BmiResult calc(String w, String h, HeightUnit u) =>
        BmiCalculator.calculate(weightKg: d(w), height: d(h), unit: u);
    test('metros e centímetros dão o mesmo', () {
      final a = calc('70', '1.75', HeightUnit.meters);
      final b = calc('70', '175', HeightUnit.centimeters);
      expect(a.bmi, d('22.9'));
      expect(b.bmi, a.bmi);
      expect(a.category, BmiCategory.normal);
    });
    test('faixas nos limites', () {
      expect(BmiCalculator.classify(d('18.4')), BmiCategory.underweight);
      expect(BmiCalculator.classify(d('18.5')), BmiCategory.normal);
      expect(BmiCalculator.classify(d('24.9')), BmiCategory.normal);
      expect(BmiCalculator.classify(d('25')), BmiCategory.overweight);
      expect(BmiCalculator.classify(d('30')), BmiCategory.obesity1);
      expect(BmiCalculator.classify(d('35')), BmiCategory.obesity2);
      expect(BmiCalculator.classify(d('40')), BmiCategory.obesity3);
    });
    test('entradas inválidas', () {
      expect(() => calc('0', '1.75', HeightUnit.meters), throwsCalc);
      expect(() => calc('-5', '1.75', HeightUnit.meters), throwsCalc);
      expect(() => calc('70', '0', HeightUnit.meters), throwsCalc);
      expect(() => calc('70', '175', HeightUnit.meters), throwsCalc);
      expect(() => calc('70', '1.75', HeightUnit.centimeters), throwsCalc);
      expect(() => calc('900', '1.75', HeightUnit.meters), throwsCalc);
    });
  });

  group('idade', () {
    AgeResult age(DateTime b, DateTime t) =>
        AgeCalculator.calculate(birth: b, today: t);
    void expectYmd(AgeResult r, int y, int m, int dd) {
      expect([r.years, r.months, r.days], [y, m, dd]);
    }

    test('caso simples e aniversário hoje', () {
      expectYmd(age(DateTime(1990, 5, 10), DateTime(2024, 5, 10)), 34, 0, 0);
      expectYmd(age(DateTime(1990, 5, 10), DateTime(2024, 5, 9)), 33, 11, 29);
      expectYmd(age(DateTime(2024, 5, 10), DateTime(2024, 5, 10)), 0, 0, 0);
    });
    test('ignora hora e fuso', () {
      final r = age(
        DateTime(1990, 5, 10, 23, 59),
        DateTime.utc(2024, 5, 10, 1),
      );
      expectYmd(r, 34, 0, 0);
    });
    test('29 de fevereiro', () {
      final b = DateTime(2000, 2, 29);
      expectYmd(age(b, DateTime(2001, 2, 28)), 0, 11, 30);
      expectYmd(age(b, DateTime(2001, 3, 1)), 1, 0, 0);
      expectYmd(age(b, DateTime(2004, 2, 29)), 4, 0, 0);
      expectYmd(age(b, DateTime(2004, 2, 28)), 3, 11, 27);
    });
    test('fim de mês', () {
      expectYmd(age(DateTime(2001, 1, 31), DateTime(2001, 2, 28)), 0, 1, 0);
      expectYmd(age(DateTime(2001, 1, 31), DateTime(2001, 3, 1)), 0, 1, 1);
    });
    test('total de dias e data futura', () {
      expect(age(DateTime(2024, 1, 1), DateTime(2024, 3, 1)).totalDays, 60);
      expect(() => age(DateTime(2025, 1, 2), DateTime(2025, 1, 1)), throwsCalc);
    });
  });
}
