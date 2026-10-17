import 'package:flutter_test/flutter_test.dart';
import 'package:tqvp/features/converters/sizes/sizes_data.dart';
import 'package:tqvp/features/converters/sizes/sizes_logic.dart';

void main() {
  group('calçados', () {
    test('BR = EU - 2 em todas as linhas numéricas', () {
      for (final c in [ShoeCategory.men, ShoeCategory.women]) {
        for (final r in shoeRows(c)) {
          final br = r.br.split('/').map(int.parse).toList();
          final eu = r.eu.split('/').map(int.parse).toList();
          expect(br.length, eu.length);
          for (var i = 0; i < br.length; i++) {
            expect(eu[i] - br[i], 2, reason: '${c.name} ${r.br}');
          }
        }
      }
    });

    test('cm crescente com o número brasileiro', () {
      for (final c in [ShoeCategory.men, ShoeCategory.women]) {
        double last = 0;
        for (final r in shoeRows(c)) {
          if (r.footCm == null) continue;
          expect(r.footCm! >= last, isTrue, reason: '${c.name} ${r.br}');
          last = r.footCm!;
        }
      }
    });

    test('opções e correspondências', () {
      final opts = shoeOptions(ShoeCategory.men, ShoeSystem.br);
      expect(opts.first, '37');
      expect(opts, containsAll(['39', '40', '41', '42']));
      expect(opts.toSet().length, opts.length);
      final m = shoeMatches(ShoeCategory.women, ShoeSystem.br, '37');
      expect(m.map((e) => e.us), ['7.5', '8']);
      expect(m.every((e) => e.eu == '39' && e.footCm == 24), isTrue);
      // Valor combinado casa pelas duas pontas.
      expect(
        shoeMatches(ShoeCategory.men, ShoeSystem.eu, '42').map((e) => e.us),
        ['8.5', '9'],
      );
      expect(shoeMatches(ShoeCategory.men, ShoeSystem.br, '99'), isEmpty);
    });

    test('bebê tem idade e sem cm', () {
      for (final r in babyShoes) {
        expect(r.age, isNotNull);
        expect(r.footCm, isNull);
      }
      expect(
        shoeMatches(ShoeCategory.baby, ShoeSystem.eu, '19').single.br,
        '17',
      );
    });
  });

  group('roupas', () {
    test('tabelas ordenadas e faixas válidas', () {
      for (final g in ClothingGender.values) {
        int last = 0;
        for (final r in clothingRows(g)) {
          expect(r.number > last, isTrue);
          last = r.number;
          for (final c in [r.upper, r.waist, r.hip]) {
            expect(c.min <= c.max, isTrue, reason: '${g.name} ${r.number}');
          }
        }
      }
      expect(womenClothing.first.number, 34);
      expect(menClothing.last.letter, 'GG');
    });

    test('letras inglesas coerentes', () {
      const map = {'PP': 'XS', 'P': 'S', 'M': 'M', 'G': 'L', 'GG': 'XL'};
      for (final r in [...womenClothing, ...menClothing]) {
        expect(map[r.letter], r.english);
      }
    });

    test('aproximação europeia e americana feminina por medida', () {
      ClothingSize w(int n) => womenClothing.firstWhere((r) => r.number == n);
      expect(euWomenApprox(w(36), ClothingPart.top), 36);
      expect(euWomenApprox(w(38), ClothingPart.top), 38);
      expect(euWomenApprox(w(44), ClothingPart.bottom), 44);
      expect(usWomenApprox(w(36), ClothingPart.top), 4);
      expect(usWomenApprox(w(38), ClothingPart.top), 6);
      expect(usWomenApprox(w(48), ClothingPart.top), isNull);
    });
  });
}
