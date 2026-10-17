import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/tokens.dart';

int _idCounter = 0;

/// Id único local (timestamp + contador), sem dependências externas.
String generateId() {
  _idCounter++;
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '-${_idCounter.toRadixString(36)}';
}

/// Persiste uma lista de modelos como JSON em uma única chave do
/// SharedPreferences. JSON corrompido é descartado sem lançar exceção
/// (e sem registrar conteúdo em log).
class JsonListStore<T> {
  const JsonListStore({
    required this.key,
    required this.fromJson,
    required this.toJson,
  });

  final String key;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;

  List<T> load(SharedPreferences prefs) {
    try {
      final raw = prefs.get(key);
      if (raw is! String) return <T>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <T>[];
      final out = <T>[];
      for (final e in decoded) {
        try {
          if (e is Map) out.add(fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {
          // item inválido descartado
        }
      }
      return out;
    } catch (_) {
      return <T>[];
    }
  }

  /// Retorna false se a escrita falhar.
  Future<bool> save(SharedPreferences prefs, List<T> items) async {
    try {
      final ok = await prefs.setString(
        key,
        jsonEncode(items.map(toJson).toList()),
      );
      return ok;
    } catch (_) {
      return false;
    }
  }
}

/// Forma arredondada comum dos diálogos.
final dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(Radii.card),
);

/// Mostra SnackBar de erro de gravação.
void showSaveError(ScaffoldMessengerState messenger) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Não foi possível salvar. Tente de novo.')),
    );
}

/// Diálogo de confirmação de exclusão. Retorna true se confirmado.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: dialogShape,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Diálogo com um campo de texto. Retorna o texto aparado ou null.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) =>
        _PromptDialog(title: title, label: label, initial: initial),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.initial,
  });
  final String title;
  final String label;
  final String initial;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _c.text.trim();
    if (t.isNotEmpty) Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: dialogShape,
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
