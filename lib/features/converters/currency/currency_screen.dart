import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../units/from_to_row.dart';
import 'currency_converter.dart';
import 'currency_models.dart';
import 'currency_repository.dart';

const _priority = [
  'BRL', 'USD', 'EUR', 'GBP', 'ARS', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', //
];

String _two(int n) => n.toString().padLeft(2, '0');

String _formatDateTime(DateTime d) {
  final l = d.toLocal();
  return '${_two(l.day)}/${_two(l.month)}/${l.year} ${_two(l.hour)}:${_two(l.minute)}';
}

String _formatIsoDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}

class CurrencyScreen extends ConsumerStatefulWidget {
  const CurrencyScreen({super.key});

  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  final _amount = TextEditingController(text: '1');
  String _from = 'USD';
  String _to = 'BRL';
  bool _loading = true;
  CurrencyLoad? _load;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final result = await ref.read(currencyRepositoryProvider).load();
    if (!mounted) return;
    setState(() {
      _load = result;
      _loading = false;
    });
  }

  List<String> _codes(ExchangeRates r) {
    final others = r.rates.keys.where((c) => !_priority.contains(c)).toList()
      ..sort();
    return [..._priority.where(r.rates.containsKey), ...others];
  }

  void _swap() => setState(() {
    final t = _from;
    _from = _to;
    _to = t;
  });

  @override
  Widget build(BuildContext context) {
    final load = _load;
    final rates = load?.rates;
    return ToolScaffold(
      title: 'Conversor de moedas',
      actions: [
        IconButton(
          tooltip: 'Atualizar cotações',
          icon: const Icon(Icons.refresh),
          onPressed: _loading ? null : _fetch,
        ),
      ],
      children: [
        if (_loading && rates == null)
          const AppCard(
            child: Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Carregando cotações',
                ),
              ),
            ),
          )
        else if (rates == null) ...[
          ErrorBanner(
            '${load?.error ?? 'Não foi possível obter as cotações.'} '
            'Sem conexão e sem cotações salvas no aparelho.',
          ),
          _RetryButton(onPressed: _loading ? null : _fetch),
        ] else
          ..._content(rates, load!),
      ],
    );
  }

  List<Widget> _content(ExchangeRates rates, CurrencyLoad load) {
    final codes = _codes(rates);
    if (!codes.contains(_from)) _from = 'BRL';
    if (!codes.contains(_to)) _to = 'USD';
    final amount = parseDecimal(_amount.text);
    final result = amount == null
        ? null
        : convertCurrency(amount, _from, _to, rates.rates);
    final stale = isStale(rates, DateTime.now());
    final refDate = referenceDate(rates, _from, _to);
    final theme = Theme.of(context);

    Widget dropdown(
      String label,
      String value,
      ValueChanged<String> onChanged,
    ) => Row(
      children: [
        _CodeBadge(value),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('$label-$value'),
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: label),
            items: [
              for (final c in codes) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );

    return [
      if (load.fromCache) ...[
        ErrorBanner(
          '${load.error} Mostrando a última cotação salva, de '
          '${_formatDateTime(rates.fetchedAt)}'
          '${stale ? ' (desatualizada: tem mais de 24 horas)' : ''}.',
        ),
        _RetryButton(onPressed: _loading ? null : _fetch, outlined: true),
      ],
      SectionCard(
        title: 'Valor',
        children: [
          NumberField(
            controller: _amount,
            label: 'Valor',
            suffix: _from,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      FromToRow(
        swapTooltip: 'Inverter moedas',
        onSwap: _swap,
        from: dropdown('De', _from, (v) => setState(() => _from = v)),
        to: dropdown('Para', _to, (v) => setState(() => _to = v)),
      ),
      if (amount == null)
        const ErrorBanner('Digite um valor válido para converter.')
      else if (result != null)
        ResultCard(
          label: '${formatDecimal(amount, maxFractionDigits: 2)} $_from =',
          value:
              '${formatDecimal(result.amount, maxFractionDigits: 2, minFractionDigits: 2)} $_to',
          detail:
              'Taxa aplicada: 1 $_from = '
              '${formatDecimal(result.rate, maxFractionDigits: 6)} $_to',
        ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBadge(Icons.account_balance_outlined, size: 40),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fonte: ${rates.source}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Atualizado em ${_formatDateTime(rates.fetchedAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (refDate != null)
                        Text(
                          'Cotação de ${_formatIsoDate(refDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (stale && !load.fromCache) ...[
              const SizedBox(height: Spacing.sm),
              const Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip('Desatualizada'),
              ),
            ],
            const SizedBox(height: Spacing.md),
            Text(
              'Taxas de referência diárias; não incluem tarifas, spread ou IOF.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ];
  }
}

/// Código da moeda em destaque num selo azul.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge(this.code);
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        child: Text(
          code,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.brightness == Brightness.light
                ? Brand.blueDark
                : scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Selo colorido de estado (aviso).
class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF4A3A10) : const Color(0xFFFFF3CD);
    final fg = dark ? const Color(0xFFFFE08A) : const Color(0xFF7A4F00);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm + 2,
        vertical: Spacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 16, color: fg),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onPressed, this.outlined = false});
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.refresh);
    const label = Text('Tentar novamente');
    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(48, 48)),
    );
    return outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: style,
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: style,
          );
  }
}
