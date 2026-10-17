import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import 'qr_validation.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final _controller = TextEditingController();
  final _boundaryKey = GlobalKey();
  String? _data;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate() {
    final err = validateQrText(_controller.text);
    setState(() {
      _error = err;
      _data = err == null ? _controller.text.trim() : null;
    });
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('QR não renderizado');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Falha ao gerar imagem');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qrcode.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível compartilhar o QR Code.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return ToolScaffold(
      title: 'QR Code',
      children: [
        SectionCard(
          title: 'Conteúdo do QR Code',
          children: [
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Texto ou link'),
              onSubmitted: (_) => _generate(),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_2),
              onPressed: _generate,
              label: const Text('Gerar QR Code'),
            ),
          ],
        ),
        if (_error != null) ErrorBanner(_error!),
        if (data != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Semantics(
                    image: true,
                    label: 'QR Code de: $data',
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Radii.field),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        padding: const EdgeInsets.all(Spacing.md),
                        child: QrImageView(
                          data: data,
                          size: 240,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (_, _) =>
                              const Text('Não foi possível gerar o QR Code.'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar'),
                  onPressed: _share,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
