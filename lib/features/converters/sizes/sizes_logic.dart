import 'sizes_data.dart';

List<ShoeSize> shoeRows(ShoeCategory c) => switch (c) {
  ShoeCategory.men => menShoes,
  ShoeCategory.women => womenShoes,
  ShoeCategory.baby => babyShoes,
};

List<String> _tokens(String v) => v.split('/');

/// Valores selecionáveis de [system] na categoria [c], sem repetição e na
/// ordem da tabela. Valores combinados ("41/42") são separados.
List<String> shoeOptions(ShoeCategory c, ShoeSystem system) {
  final out = <String>[];
  for (final r in shoeRows(c)) {
    for (final t in _tokens(r.valueOf(system))) {
      if (!out.contains(t)) out.add(t);
    }
  }
  return out;
}

/// Linhas da tabela cujo valor em [system] contém [value].
List<ShoeSize> shoeMatches(ShoeCategory c, ShoeSystem system, String value) => [
  for (final r in shoeRows(c))
    if (_tokens(r.valueOf(system)).contains(value)) r,
];

List<ClothingSize> clothingRows(ClothingGender g) =>
    g == ClothingGender.women ? womenClothing : menClothing;

/// Medida de referência da peça: busto/tórax em cima, quadril embaixo.
CmRange _reference(ClothingSize s, ClothingPart part) =>
    part == ClothingPart.top ? s.upper : s.hip;

/// Tamanho europeu feminino cuja faixa contém o ponto médio da medida
/// (ou o mais próximo). Aproximação por medida, não equivalência oficial.
int euWomenApprox(ClothingSize s, ClothingPart part) {
  final m = _reference(s, part).mid;
  CmRange range(EuWomenSize e) => part == ClothingPart.top ? e.bust : e.hip;
  for (final e in euWomenSizes) {
    final r = range(e);
    if (m >= r.min && m <= r.max) return e.code;
  }
  EuWomenSize best = euWomenSizes.first;
  for (final e in euWomenSizes) {
    if ((range(e).mid - m).abs() < (range(best).mid - m).abs()) best = e;
  }
  return best.code;
}

/// Tamanho feminino dos EUA mais próximo da medida, até [toleranceCm] de
/// diferença; nulo se nenhum estiver perto o bastante.
int? usWomenApprox(
  ClothingSize s,
  ClothingPart part, {
  double toleranceCm = 3,
}) {
  final m = _reference(s, part).mid;
  double value(UsWomenSize u) => part == ClothingPart.top ? u.bust : u.hip;
  UsWomenSize best = usWomenSizes.first;
  for (final u in usWomenSizes) {
    if ((value(u) - m).abs() < (value(best) - m).abs()) best = u;
  }
  return (value(best) - m).abs() <= toleranceCm ? best.size : null;
}
