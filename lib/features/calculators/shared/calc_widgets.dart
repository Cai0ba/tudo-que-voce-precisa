import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';

/// Erro anunciado por leitores de tela assim que aparece.
class LiveError extends StatelessWidget {
  const LiveError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) =>
      Semantics(liveRegion: true, child: ErrorBanner(message));
}

/// Dica neutra, em card suave, mostrada enquanto faltam dados.
class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.touch_app_outlined, color: scheme.primary),
            ),
            const SizedBox(width: Spacing.sm + Spacing.xs),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso informativo em card com ícone.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: IconBadge(Icons.info_outline, size: 40),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Semantics(
              container: true,
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seleção única por chips (modos/unidades), com alvo de toque >= 48.
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    required this.semanticLabel,
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String semanticLabel;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: [
          for (final (value, label) in options)
            ChoiceChip(
              label: Text(label),
              selected: value == selected,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onSelected(value),
            ),
        ],
      ),
    );
  }
}
