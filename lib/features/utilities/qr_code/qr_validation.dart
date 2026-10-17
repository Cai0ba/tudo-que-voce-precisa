/// Domínio puro: valida o texto do QR Code. Retorna mensagem de erro ou null.
const qrMaxLength = 2000;

String? validateQrText(String? input) {
  final t = input?.trim() ?? '';
  if (t.isEmpty) return 'Digite um texto ou link para gerar o QR Code.';
  if (t.length > qrMaxLength) {
    return 'O texto é grande demais (máximo $qrMaxLength caracteres).';
  }
  return null;
}
