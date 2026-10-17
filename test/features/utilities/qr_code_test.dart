import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tqvp/features/utilities/qr_code/qr_code_screen.dart';
import 'package:tqvp/features/utilities/qr_code/qr_validation.dart';

void main() {
  test('validação', () {
    expect(validateQrText(null), isNotNull);
    expect(validateQrText('   '), isNotNull);
    expect(validateQrText('a' * (qrMaxLength + 1)), isNotNull);
    expect(validateQrText('https://exemplo.com'), isNull);
  });

  testWidgets('vazio mostra erro; texto gera QR e botão compartilhar', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QrCodeScreen()));
    await tester.tap(find.text('Gerar QR Code'));
    await tester.pump();
    expect(find.textContaining('Digite um texto'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    await tester.enterText(find.byType(TextField), 'https://exemplo.com');
    await tester.tap(find.text('Gerar QR Code'));
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
    expect(find.textContaining('Digite um texto'), findsNothing);
  });
}
