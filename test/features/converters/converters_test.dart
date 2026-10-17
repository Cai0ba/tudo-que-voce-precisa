import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tqvp/core/widgets/tool_scaffold.dart';
import 'package:tqvp/features/converters/length/length_screen.dart';
import 'package:tqvp/features/converters/mass/mass_screen.dart';
import 'package:tqvp/features/converters/temperature/temperature_screen.dart';
import 'package:tqvp/features/converters/units/unit_model.dart';
import 'package:tqvp/features/converters/volume/volume_screen.dart';

Decimal d(String s) => Decimal.parse(s);

ConversionUnit u(List<ConversionUnit> l, String id) =>
    l.firstWhere((x) => x.id == id);

ConversionUnit t(String id) => u(temperatureUnits, id);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('conversão linear exata', () {
    test('comprimento', () {
      expect(
        convertLinear(d('1'), u(lengthUnits, 'in'), u(lengthUnits, 'm')),
        d('0.0254'),
      );
      expect(
        convertLinear(d('1'), u(lengthUnits, 'mi'), u(lengthUnits, 'km')),
        d('1.609344'),
      );
      expect(
        convertLinear(d('12'), u(lengthUnits, 'in'), u(lengthUnits, 'ft')),
        d('1'),
      );
      expect(
        convertLinear(d('3'), u(lengthUnits, 'ft'), u(lengthUnits, 'yd')),
        d('1'),
      );
    });

    test('massa', () {
      expect(
        convertLinear(d('1'), u(massUnits, 'lb'), u(massUnits, 'kg')),
        d('0.45359237'),
      );
      expect(
        convertLinear(d('16'), u(massUnits, 'oz'), u(massUnits, 'lb')),
        d('1'),
      );
      expect(
        convertLinear(d('1'), u(massUnits, 'kg'), u(massUnits, 'mg')),
        d('1000000'),
      );
    });

    test('volume', () {
      expect(
        convertLinear(d('1'), u(volumeUnits, 'gal'), u(volumeUnits, 'l')),
        d('3.785411784'),
      );
      expect(
        convertLinear(d('1'), u(volumeUnits, 'gal'), u(volumeUnits, 'cup')),
        d('16'),
      );
      expect(
        convertLinear(d('1'), u(volumeUnits, 'gal'), u(volumeUnits, 'tbsp')),
        d('256'),
      );
      expect(
        convertLinear(d('1'), u(volumeUnits, 'gal'), u(volumeUnits, 'floz')),
        d('128'),
      );
      expect(
        convertLinear(d('1'), u(volumeUnits, 'm3'), u(volumeUnits, 'ml')),
        d('1000000'),
      );
    });

    test('ida e volta preserva o valor (todas as unidades)', () {
      for (final units in [lengthUnits, massUnits, volumeUnits]) {
        for (final a in units) {
          for (final b in units) {
            final v = d('123.456789');
            final back = convertLinear(convertLinear(v, a, b), b, a);
            final diff = (back - v).abs();
            expect(diff < d('0.000000001'), isTrue, reason: '${a.id}->${b.id}');
          }
        }
      }
    });

    test('zero e valores grandes', () {
      expect(
        convertLinear(Decimal.zero, u(lengthUnits, 'mi'), u(lengthUnits, 'mm')),
        Decimal.zero,
      );
      expect(
        convertLinear(
          d('1000000000000000000000'),
          u(lengthUnits, 'km'),
          u(lengthUnits, 'm'),
        ),
        d('1000000000000000000000000'),
      );
    });
  });

  group('temperatura', () {
    test('pontos conhecidos', () {
      expect(convertTemperature(d('0'), t('c'), t('f')), d('32'));
      expect(convertTemperature(d('100'), t('c'), t('f')), d('212'));
      expect(convertTemperature(d('0'), t('c'), t('k')), d('273.15'));
      expect(convertTemperature(d('32'), t('f'), t('c')), d('0'));
      expect(convertTemperature(d('-40'), t('c'), t('f')), d('-40'));
      expect(convertTemperature(d('0'), t('k'), t('c')), d('-273.15'));
      expect(convertTemperature(d('-459.67'), t('f'), t('k')), d('0'));
    });

    test('ida e volta', () {
      for (final a in temperatureUnits) {
        for (final b in temperatureUnits) {
          final v = d('36.6');
          final back = convertTemperature(convertTemperature(v, a, b), b, a);
          expect((back - v).abs() < d('0.0000000001'), isTrue);
        }
      }
    });

    test('zero absoluto', () {
      expect(validateTemperature(d('-273.15'), t('c')), isNull);
      expect(validateTemperature(d('-273.16'), t('c')), isNotNull);
      expect(validateTemperature(d('-459.68'), t('f')), isNotNull);
      expect(validateTemperature(d('-459.67'), t('f')), isNull);
      expect(validateTemperature(d('-1'), t('k')), contains('zero absoluto'));
      expect(validateTemperature(d('0'), t('k')), isNull);
    });
  });

  group('telas', () {
    Future<void> open(WidgetTester tester, Widget screen) async {
      await tester.pumpWidget(MaterialApp(home: screen));
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }

    String resultValue(WidgetTester tester) =>
        tester.widget<ResultCard>(find.byType(ResultCard)).value;

    testWidgets('comprimento converte com vírgula e inverte', (tester) async {
      await open(tester, const LengthScreen());
      expect(find.text('Digite um valor para converter.'), findsOneWidget);
      await type(tester, '10');
      expect(resultValue(tester), '32,808399 ft');
      await tester.tap(find.byKey(const ValueKey('swap')));
      await tester.pump();
      expect(resultValue(tester), '3,048 m');
      await type(tester, '1,5');
      expect(resultValue(tester), '0,4572 m');
    });

    testWidgets('invalido, vazio e negativo', (tester) async {
      await open(tester, const MassScreen());
      await type(tester, 'abc');
      expect(find.byType(ErrorBanner), findsOneWidget);
      await type(tester, '-5');
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.byType(ResultCard), findsNothing);
      await type(tester, '');
      expect(find.byType(ErrorBanner), findsNothing);
      await type(tester, '1');
      expect(resultValue(tester), '2,204623 lb');
    });

    testWidgets('volume escolhe unidade pelo seletor', (tester) async {
      await open(tester, const VolumeScreen());
      await type(tester, '1');
      expect(resultValue(tester), '1.000 mL');
      await tester.tap(find.byKey(const ValueKey('to-ml')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Galão americano (gal)').last);
      await tester.pumpAndSettle();
      expect(resultValue(tester), '0,264172 gal');
    });

    testWidgets('temperatura aceita negativo e rejeita zero absoluto', (
      tester,
    ) async {
      await open(tester, const TemperatureScreen());
      await type(tester, '-40');
      expect(resultValue(tester), '-40 °F');
      await type(tester, '-300');
      expect(find.byType(ResultCard), findsNothing);
      expect(find.textContaining('zero absoluto'), findsOneWidget);
    });
  });
}
