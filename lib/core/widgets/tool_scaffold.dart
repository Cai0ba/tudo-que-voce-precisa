import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Casca padrão das telas de ferramenta: AppBar + conteúdo rolável com
/// largura máxima, adequada a telas grandes e fontes ampliadas.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    required this.title,
    required this.children,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Brand.maxContentWidth),
            child: ListView.separated(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
              itemBuilder: (_, i) => children[i],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão de resultado em destaque: gradiente azul, valor grande em branco.
class ResultCard extends StatelessWidget {
  const ResultCard({
    required this.label,
    required this.value,
    this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const fg = Colors.white;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.circular(Radii.card),
          boxShadow: [
            BoxShadow(
              color: Brand.blue.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                detail!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mensagem de erro de validação/estado, em linguagem simples.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo numérico pt-BR (aceita vírgula).
class NumberField extends StatelessWidget {
  const NumberField({
    required this.controller,
    required this.label,
    this.suffix,
    this.onChanged,
    this.signed = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}
