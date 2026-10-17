import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/components.dart';

/// Linha "De / Para": dois cartões lado a lado (telas largas) ou empilhados
/// (telas estreitas / fonte grande), com botão circular de inverter ao centro.
class FromToRow extends StatelessWidget {
  const FromToRow({
    required this.from,
    required this.to,
    required this.onSwap,
    required this.swapTooltip,
    this.swapKey,
    super.key,
  });

  final Widget from;
  final Widget to;
  final VoidCallback onSwap;
  final String swapTooltip;
  final Key? swapKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide =
        MediaQuery.sizeOf(context).width >= 520 &&
        MediaQuery.textScalerOf(context).scale(16) <= 20;

    Widget swap(IconData icon) => IconButton.filled(
      key: swapKey,
      tooltip: swapTooltip,
      icon: Icon(icon),
      onPressed: onSwap,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: AppCard(child: from)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: swap(Icons.swap_horiz),
          ),
          Expanded(child: AppCard(child: to)),
        ],
      );
    }
    return Column(
      children: [
        AppCard(child: from),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: swap(Icons.swap_vert),
        ),
        AppCard(child: to),
      ],
    );
  }
}
