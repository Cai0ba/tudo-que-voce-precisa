import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/features/calculators/fuel/fuel_calculator.dart';
import 'package:tqvp/features/calculators/shared/calc_support.dart';

Decimal d(String s) => Decimal.parse(s);
Matcher get throwsCalc => throwsA(isA<CalcException>());

FuelComparison cmp(String e, String g, {String? l, String? ek, String? gk}) =>
    FuelCalculator.compare(
      ethanolPrice: d(e),
      gasolinePrice: d(g),
      limitPercent: l == null ? null : d(l),
      ethanolKmPerL: ek == null ? null : d(ek),
      gasolineKmPerL: gk == null ? null : d(gk),
    );

void main() {
  group('álcool × gasolina', () {
    test('regra dos 70%', () {
      expect(cmp('4.00', '6.00').ethanolWins, isTrue);
      expect(cmp('4.00', '6.00').ratioPercent, d('66.7'));
      expect(cmp('4.90', '7.00').ethanolWins, isTrue); // exatamente 70%
      expect(cmp('5.00', '6.00').ethanolWins, isFalse);
    });
    test('limite ajustável', () {
      expect(cmp('5.00', '6.00', l: '85').ethanolWins, isTrue);
      expect(cmp('4.00', '6.00', l: '60').ethanolWins, isFalse);
    });
    test('custo por km', () {
      final r = cmp('4.00', '6.00', ek: '7', gk: '10');
      expect(r.byCostPerKm, isTrue);
      expect(r.ethanolWins, isTrue); // 0,571 < 0,600
      expect(r.ethanolCostPerKm, d('0.571'));
      expect(r.gasolineCostPerKm, d('0.6'));
      expect(cmp('4.50', '6.00', ek: '7', gk: '10').ethanolWins, isFalse);
      expect(
        cmp('4.00', '8.00', ek: '5', gk: '10').ethanolWins,
        isTrue,
      ); // empate
    });
    test('validações', () {
      expect(() => cmp('0', '6'), throwsCalc);
      expect(() => cmp('4', '0'), throwsCalc);
      expect(() => cmp('-4', '6'), throwsCalc);
      expect(() => cmp('4', '6', l: '0'), throwsCalc);
      expect(() => cmp('4', '6', l: '101'), throwsCalc);
      expect(() => cmp('4', '6', ek: '7'), throwsCalc);
      expect(() => cmp('4', '6', ek: '0', gk: '10'), throwsCalc);
      expect(() => cmp('4', '6', ek: '7', gk: '-1'), throwsCalc);
    });
  });

  group('consumo', () {
    test('km/l', () {
      expect(FuelCalculator.consumption(d('300'), d('25')), d('12'));
      expect(FuelCalculator.consumption(d('100'), d('3')), d('33.33'));
    });
    test('validações', () {
      expect(() => FuelCalculator.consumption(d('100'), d('0')), throwsCalc);
      expect(() => FuelCalculator.consumption(d('0'), d('10')), throwsCalc);
      expect(() => FuelCalculator.consumption(d('-1'), d('10')), throwsCalc);
    });
  });

  group('viagem', () {
    test('litros e custo', () {
      final r = FuelCalculator.trip(
        distanceKm: d('300'),
        kmPerL: d('12'),
        pricePerLiter: d('6'),
      );
      expect(r.liters, d('25'));
      expect(r.cost, d('150'));
    });
    test('ida e volta', () {
      final r = FuelCalculator.trip(
        distanceKm: d('300'),
        kmPerL: d('12'),
        pricePerLiter: d('6'),
        roundTrip: true,
      );
      expect(r.distance, d('600'));
      expect(r.liters, d('50'));
      expect(r.cost, d('300'));
    });
    test('validações', () {
      for (final args in [
        ['0', '12', '6'],
        ['100', '0', '6'],
        ['100', '12', '0'],
        ['-5', '12', '6'],
      ]) {
        expect(
          () => FuelCalculator.trip(
            distanceKm: d(args[0]),
            kmPerL: d(args[1]),
            pricePerLiter: d(args[2]),
          ),
          throwsCalc,
        );
      }
    });
  });
}
