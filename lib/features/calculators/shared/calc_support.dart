import 'package:decimal/decimal.dart';

import '../../../core/formatting/number_utils.dart';

/// Erro de validação com mensagem simples em pt-BR, pronta para exibição.
class CalcException implements Exception {
  const CalcException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Exige valor não negativo.
Decimal requireNonNegative(Decimal value, String name) {
  if (value < Decimal.zero) {
    throw CalcException('O valor de "$name" não pode ser negativo.');
  }
  return value;
}

/// Divisão exata com precisão de 12 casas (o chamador trata divisor zero).
Decimal divide(Decimal a, Decimal b) =>
    (a / b).toDecimal(scaleOnInfinitePrecision: 12);

/// Arredondamento padrão do app: meio para cima, afastando de zero.
Decimal roundTo(Decimal value, int scale) => value.round(scale: scale);

/// Lê o texto de um campo: null se vazio; lança [CalcException] se inválido.
Decimal? readField(String text, String name) {
  if (text.trim().isEmpty) return null;
  final v = parseDecimal(text);
  if (v == null) {
    throw CalcException('Digite um número válido em "$name".');
  }
  return v;
}
