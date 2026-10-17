import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/features/converters/cooking/cooking_converter.dart';
import 'package:tqvp/features/converters/cooking/cooking_data.dart';

Decimal d(String s) => Decimal.parse(s);
CookingUnit u(String id) => cookingUnits.firstWhere((x) => x.id == id);
Ingredient ing(String id) => ingredients.firstWhere((x) => x.id == id);

void main() {
  final water = ing('water');
  final flour = ing('wheat_flour');

  test('medidas de volume', () {
    expect(convertCooking(d('1'), u('cup'), u('ml'), water), d('240'));
    expect(convertCooking(d('1'), u('tbsp'), u('ml'), water), d('15'));
    expect(convertCooking(d('1'), u('tsp'), u('ml'), water), d('5'));
    expect(convertCooking(d('1'), u('cup'), u('tbsp'), water), d('16'));
    expect(convertCooking(d('1'), u('tbsp'), u('tsp'), water), d('3'));
    expect(convertCooking(d('1500'), u('ml'), u('l'), water), d('1.5'));
    expect(
      convertCooking(d('2'), u('l'), u('cup'), water).toString(),
      '8.33333333333333333333',
    );
  });

  test('volume independe do ingrediente', () {
    for (final i in ingredients) {
      expect(convertCooking(d('1'), u('cup'), u('ml'), i), d('240'));
    }
  });

  test('massa depende do ingrediente', () {
    expect(convertCooking(d('1'), u('cup'), u('g'), flour), d('120'));
    expect(convertCooking(d('120'), u('g'), u('cup'), flour), d('1'));
    expect(convertCooking(d('1'), u('cup'), u('g'), water), d('240'));
    expect(convertCooking(d('1'), u('tbsp'), u('g'), flour), d('7.5'));
    expect(convertCooking(d('240'), u('ml'), u('g'), ing('honey')), d('340'));
  });

  test('mesma unidade devolve o valor', () {
    expect(convertCooking(d('3.5'), u('g'), u('g'), flour), d('3.5'));
  });

  test('ida e volta g -> xícara -> g', () {
    for (final i in ingredients) {
      final cups = convertCooking(d('500'), u('g'), u('cup'), i);
      final back = convertCooking(cups, u('cup'), u('g'), i);
      expect((back - d('500')).abs() < d('0.000001'), isTrue, reason: i.id);
    }
  });

  test('dados: ids únicos e densidades plausíveis (0,3 a 1,5 g/mL)', () {
    expect(ingredients.map((i) => i.id).toSet().length, ingredients.length);
    expect(cookingUnits.map((x) => x.id).toSet().length, cookingUnits.length);
    for (final i in ingredients) {
      final density = i.gramsPerCup / cupMl;
      expect(density, inInclusiveRange(0.3, 1.5), reason: i.name);
    }
    expect(cookingDisclaimer, contains('variam com a marca'));
  });
}
