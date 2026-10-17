/// Tabelas de correspondência de tamanhos. Todos os valores vêm das fontes
/// listadas em docs/size-sources.md; nada aqui foi estimado ou extrapolado.
/// As tabelas variam por marca: use sempre como referência aproximada.
library;

// ---------------------------------------------------------------- Calçados

enum ShoeCategory {
  men('Masculino'),
  women('Feminino'),
  baby('Bebê');

  const ShoeCategory(this.label);
  final String label;
}

enum ShoeSystem {
  br('Brasil'),
  us('EUA'),
  eu('Europa');

  const ShoeSystem(this.label);
  final String label;
}

/// Uma linha da tabela de calçados. Os números ficam em texto porque a fonte
/// traz valores combinados (ex.: "41/42") e meios-números ("8.5").
class ShoeSize {
  const ShoeSize({
    required this.br,
    required this.us,
    required this.eu,
    this.footCm,
    this.age,
  });

  final String br;
  final String us;
  final String eu;

  /// Comprimento do pé em cm correspondente ao número brasileiro, quando a
  /// fonte o informa.
  final double? footCm;

  /// Faixa de idade (apenas bebês).
  final String? age;

  String valueOf(ShoeSystem s) => switch (s) {
    ShoeSystem.br => br,
    ShoeSystem.us => us,
    ShoeSystem.eu => eu,
  };
}

const menShoes = <ShoeSize>[
  ShoeSize(us: '6', eu: '39', br: '37', footCm: 24.5),
  ShoeSize(us: '6.5', eu: '39', br: '37', footCm: 24.5),
  ShoeSize(us: '7', eu: '40', br: '38', footCm: 25.5),
  ShoeSize(us: '7.5', eu: '40', br: '38', footCm: 25.5),
  ShoeSize(us: '8', eu: '41', br: '39', footCm: 26),
  ShoeSize(us: '8.5', eu: '41/42', br: '39/40'),
  ShoeSize(us: '9', eu: '42', br: '40', footCm: 27),
  ShoeSize(us: '9.5', eu: '43', br: '41', footCm: 27.5),
  ShoeSize(us: '10', eu: '43/44', br: '41/42'),
  ShoeSize(us: '10.5', eu: '44', br: '42', footCm: 28.5),
  ShoeSize(us: '11', eu: '44', br: '42', footCm: 28.5),
  ShoeSize(us: '11.5', eu: '45', br: '43', footCm: 29.5),
  ShoeSize(us: '12', eu: '46', br: '44', footCm: 30),
  ShoeSize(us: '13', eu: '47', br: '45', footCm: 30.5),
  ShoeSize(us: '14', eu: '48', br: '46', footCm: 31),
  ShoeSize(us: '15', eu: '49', br: '47', footCm: 32),
  ShoeSize(us: '16', eu: '50', br: '48', footCm: 33),
];

const womenShoes = <ShoeSize>[
  ShoeSize(us: '4', eu: '35', br: '33'),
  ShoeSize(us: '4.5', eu: '35', br: '33'),
  ShoeSize(us: '5', eu: '36', br: '34', footCm: 22.5),
  ShoeSize(us: '5.5', eu: '36', br: '34', footCm: 22.5),
  ShoeSize(us: '6', eu: '37', br: '35', footCm: 23),
  ShoeSize(us: '6.5', eu: '37', br: '35', footCm: 23),
  ShoeSize(us: '7', eu: '38', br: '36', footCm: 23.5),
  ShoeSize(us: '7.5', eu: '39', br: '37', footCm: 24),
  ShoeSize(us: '8', eu: '39', br: '37', footCm: 24),
  ShoeSize(us: '8.5', eu: '40', br: '38', footCm: 25),
  ShoeSize(us: '9', eu: '40', br: '38', footCm: 25),
  ShoeSize(us: '9.5', eu: '41', br: '39', footCm: 26),
  ShoeSize(us: '10', eu: '41/42', br: '39/40'),
  ShoeSize(us: '10.5', eu: '42', br: '40', footCm: 27),
  ShoeSize(us: '11', eu: '43', br: '41', footCm: 27.5),
  ShoeSize(us: '11.5', eu: '43', br: '41', footCm: 27.5),
  ShoeSize(us: '12', eu: '44', br: '42'),
];

/// Bebês: a fonte traz idade, EUA, Europa e Brasil (sem comprimento em cm).
const babyShoes = <ShoeSize>[
  ShoeSize(age: '0 a 3 meses', us: '1½', eu: '16', br: 'RN'),
  ShoeSize(age: '3 a 6 meses', us: '3', eu: '18', br: '16'),
  ShoeSize(age: '6 a 9 meses', us: '4', eu: '19', br: '17'),
  ShoeSize(age: '9 a 12 meses', us: '5', eu: '20', br: '18'),
  ShoeSize(age: '12 a 15 meses', us: '6', eu: '21', br: '19'),
  ShoeSize(age: '15 a 18 meses', us: '6½', eu: '22', br: '20'),
  ShoeSize(age: '18 a 21 meses', us: '7', eu: '23', br: '21'),
  ShoeSize(age: '21 a 24 meses', us: '8', eu: '24', br: '22'),
];

// ------------------------------------------------------------------ Roupas

enum ClothingGender {
  women('Feminino'),
  men('Masculino');

  const ClothingGender(this.label);
  final String label;
}

enum ClothingPart {
  top('Parte de cima'),
  bottom('Parte de baixo');

  const ClothingPart(this.label);
  final String label;
}

/// Faixa de medida corporal em cm (inclusive).
class CmRange {
  const CmRange(this.min, this.max);
  final double min;
  final double max;
  double get mid => (min + max) / 2;
}

class ClothingSize {
  const ClothingSize({
    required this.number,
    required this.letter,
    required this.english,
    required this.upper,
    required this.waist,
    required this.hip,
    this.shoulders,
  });

  /// Numeração (manequim) brasileira.
  final int number;

  /// Tamanho em letras no Brasil (PP, P, M, G, GG).
  final String letter;

  /// Letra equivalente em inglês (XS, S, M, L, XL).
  final String english;

  /// Busto (feminino) ou tórax (masculino).
  final CmRange upper;
  final CmRange waist;
  final CmRange hip;

  /// Ombros (apenas tabela masculina).
  final CmRange? shoulders;
}

const womenClothing = <ClothingSize>[
  ClothingSize(
    number: 34,
    letter: 'PP',
    english: 'XS',
    upper: CmRange(76, 80),
    waist: CmRange(57, 61),
    hip: CmRange(85, 89),
  ),
  ClothingSize(
    number: 36,
    letter: 'PP',
    english: 'XS',
    upper: CmRange(81, 85),
    waist: CmRange(62, 66),
    hip: CmRange(90, 94),
  ),
  ClothingSize(
    number: 38,
    letter: 'P',
    english: 'S',
    upper: CmRange(86, 89),
    waist: CmRange(67, 70),
    hip: CmRange(95, 98),
  ),
  ClothingSize(
    number: 40,
    letter: 'P',
    english: 'S',
    upper: CmRange(90, 93),
    waist: CmRange(71, 74),
    hip: CmRange(99, 102),
  ),
  ClothingSize(
    number: 42,
    letter: 'M',
    english: 'M',
    upper: CmRange(94, 97),
    waist: CmRange(75, 78),
    hip: CmRange(103, 106),
  ),
  ClothingSize(
    number: 44,
    letter: 'M',
    english: 'M',
    upper: CmRange(98, 101),
    waist: CmRange(79, 82),
    hip: CmRange(107, 110),
  ),
  ClothingSize(
    number: 46,
    letter: 'G',
    english: 'L',
    upper: CmRange(102, 105),
    waist: CmRange(83, 86),
    hip: CmRange(111, 114),
  ),
  ClothingSize(
    number: 48,
    letter: 'G',
    english: 'L',
    upper: CmRange(106, 110),
    waist: CmRange(87, 91),
    hip: CmRange(115, 119),
  ),
  ClothingSize(
    number: 50,
    letter: 'GG',
    english: 'XL',
    upper: CmRange(111, 115),
    waist: CmRange(92, 96),
    hip: CmRange(120, 124),
  ),
];

const menClothing = <ClothingSize>[
  ClothingSize(
    number: 38,
    letter: 'P',
    english: 'S',
    shoulders: CmRange(38, 39.5),
    upper: CmRange(88, 92),
    waist: CmRange(74, 78),
    hip: CmRange(92, 96),
  ),
  ClothingSize(
    number: 40,
    letter: 'M',
    english: 'M',
    shoulders: CmRange(40, 41.5),
    upper: CmRange(92, 96),
    waist: CmRange(78, 82),
    hip: CmRange(96, 100),
  ),
  ClothingSize(
    number: 42,
    letter: 'M',
    english: 'M',
    shoulders: CmRange(42, 43.5),
    upper: CmRange(96, 100),
    waist: CmRange(82, 86),
    hip: CmRange(100, 104),
  ),
  ClothingSize(
    number: 44,
    letter: 'G',
    english: 'L',
    shoulders: CmRange(44, 45.5),
    upper: CmRange(100, 104),
    waist: CmRange(86, 90),
    hip: CmRange(104, 108),
  ),
  ClothingSize(
    number: 46,
    letter: 'G',
    english: 'L',
    shoulders: CmRange(46, 47.5),
    upper: CmRange(104, 108),
    waist: CmRange(90, 94),
    hip: CmRange(108, 112),
  ),
  ClothingSize(
    number: 48,
    letter: 'GG',
    english: 'XL',
    shoulders: CmRange(48, 49.5),
    upper: CmRange(108, 112),
    waist: CmRange(94, 98),
    hip: CmRange(112, 116),
  ),
];

/// Tamanho europeu feminino (código numérico) com medidas em cm.
class EuWomenSize {
  const EuWomenSize(this.code, this.bust, this.waist, this.hip);
  final int code;
  final CmRange bust;
  final CmRange waist;
  final CmRange hip;
}

const euWomenSizes = <EuWomenSize>[
  EuWomenSize(32, CmRange(74, 77), CmRange(58, 61), CmRange(80, 84)),
  EuWomenSize(34, CmRange(78, 81), CmRange(62, 64), CmRange(85, 89)),
  EuWomenSize(36, CmRange(82, 85), CmRange(65, 68), CmRange(90, 94)),
  EuWomenSize(38, CmRange(86, 89), CmRange(69, 72), CmRange(95, 97)),
  EuWomenSize(40, CmRange(90, 93), CmRange(73, 77), CmRange(98, 101)),
  EuWomenSize(42, CmRange(94, 97), CmRange(78, 81), CmRange(102, 104)),
  EuWomenSize(44, CmRange(98, 102), CmRange(82, 85), CmRange(105, 108)),
  EuWomenSize(46, CmRange(103, 107), CmRange(86, 90), CmRange(109, 112)),
  EuWomenSize(48, CmRange(108, 113), CmRange(91, 95), CmRange(113, 116)),
  EuWomenSize(50, CmRange(114, 119), CmRange(96, 102), CmRange(117, 122)),
  EuWomenSize(52, CmRange(120, 125), CmRange(103, 108), CmRange(123, 128)),
  EuWomenSize(54, CmRange(126, 131), CmRange(109, 114), CmRange(129, 134)),
];

/// Tamanho feminino dos EUA (vestidos) com medidas em cm.
class UsWomenSize {
  const UsWomenSize(this.size, this.bust, this.waist, this.hip);
  final int size;
  final double bust;
  final double waist;
  final double hip;
}

const usWomenSizes = <UsWomenSize>[
  UsWomenSize(4, 81, 61, 89),
  UsWomenSize(6, 86, 67, 94),
  UsWomenSize(8, 91, 74, 99),
  UsWomenSize(10, 97, 79, 104),
  UsWomenSize(12, 102, 84, 109),
];
