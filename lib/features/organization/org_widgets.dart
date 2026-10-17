import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../core/widgets/components.dart';

/// Cartão de destaque no topo das listas, com ação principal de adicionar.
class AddCard extends StatelessWidget {
  const AddCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [
          BoxShadow(
            color: Brand.blue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Tooltip(
            message: tooltip,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Brand.blueDark,
                minimumSize: const Size(48, 48),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vazio ilustrado: ícone grande, texto e botão.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onPressed,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Semantics(
        container: true,
        child: Column(
          children: [
            IconBadge(icon, size: 80),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: Spacing.md),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Checkbox arredondado (círculo) com alvo de toque de 48 dp.
class RoundCheck extends StatelessWidget {
  const RoundCheck({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      shape: const CircleBorder(),
      semanticLabel: label,
      onChanged: (v) => onChanged(v ?? false),
    );
  }
}

/// Texto de item: riscado e atenuado quando concluído.
TextStyle? doneStyle(BuildContext context, TextStyle? base, bool done) {
  if (!done) return base;
  return base?.copyWith(
    decoration: TextDecoration.lineThrough,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// Barra de progresso com rótulo.
class ProgressBar extends StatelessWidget {
  const ProgressBar({required this.done, required this.total, super.key});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: total == 0 ? 0 : done / total,
        minHeight: 8,
        semanticsLabel: 'Progresso: $done de $total',
        semanticsValue: '${total == 0 ? 0 : (done * 100 / total).round()}%',
      ),
    );
  }
}
