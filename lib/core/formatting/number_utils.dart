import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:intl/intl.dart';

/// Converte texto digitado (pt-BR: "1.234,56" ou "1234,56" ou "12.5") em
/// [Decimal]. Retorna null se vazio ou inválido.
Decimal? parseDecimal(String? input) {
  if (input == null) return null;
  var s = input.trim().replaceAll(' ', '');
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    // "1.234.567" é separador de milhar em pt-BR.
    s = s.replaceAll('.', '');
  }
  if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(s)) return null;
  return Decimal.tryParse(s);
}

/// Formata com no máximo [maxFractionDigits] casas, no padrão pt-BR,
/// sem zeros à direita desnecessários.
String formatDecimal(
  Decimal value, {
  int maxFractionDigits = 2,
  int minFractionDigits = 0,
}) {
  final rounded = value.round(scale: maxFractionDigits);
  final f = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: maxFractionDigits,
  );
  final text = DecimalFormatter(f).format(rounded);
  if (minFractionDigits >= maxFractionDigits) return text;
  final sep = f.symbols.DECIMAL_SEP;
  if (!text.contains(sep)) return text;
  var out = text;
  var digits = out.length - out.indexOf(sep) - 1;
  while (digits > minFractionDigits && out.endsWith('0')) {
    out = out.substring(0, out.length - 1);
    digits--;
  }
  if (out.endsWith(sep)) out = out.substring(0, out.length - 1);
  return out;
}

/// Valor monetário em reais, ex.: "R$ 1.234,50".
String formatBrl(Decimal value) =>
    DecimalFormatter(NumberFormat.currency(locale: 'pt_BR', symbol: r'R$'))
        .format(value.round(scale: 2));
