import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/picker_tile.dart';
import 'countdown.dart';

/// Relógio injetável (sobrescreva em testes).
final countdownClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

const _prefsKey = 'countdown.saved';

class CountdownScreen extends ConsumerStatefulWidget {
  const CountdownScreen({super.key});

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen>
    with WidgetsBindingObserver {
  final _title = TextEditingController();
  DateTime? _target;
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = ref.read(countdownClockProvider)();
    final saved = SavedCountdown.decode(
      ref.read(sharedPreferencesProvider).getString(_prefsKey),
    );
    if (saved != null) {
      _title.text = saved.title;
      _target = saved.target;
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = ref.read(countdownClockProvider)());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _now = ref.read(countdownClockProvider)());
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = ref.read(countdownClockProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: _target ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_target ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _target = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _now = ref.read(countdownClockProvider)();
    });
    _save();
  }

  void _save() {
    final t = _target;
    if (t == null) return;
    ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, SavedCountdown(_title.text, t).encode());
  }

  @override
  Widget build(BuildContext context) {
    final t = _target;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return ToolScaffold(
      title: 'Contagem regressiva',
      children: [
        SectionCard(
          title: 'Evento',
          children: [
            TextField(
              controller: _title,
              onChanged: (_) => setState(_save),
              decoration: const InputDecoration(labelText: 'Título (opcional)'),
            ),
            PickerTile(
              icon: Icons.event,
              label: 'Data e hora do alvo',
              value: t == null ? null : fmt.format(t),
              onTap: _pick,
            ),
          ],
        ),
        if (t == null)
          const Text('Escolha uma data e hora para iniciar a contagem.')
        else
          _CountdownBlocks(
            label: _title.text.isEmpty ? 'Tempo restante' : _title.text,
            remaining: computeRemaining(t, _now),
            target: fmt.format(t),
          ),
      ],
    );
  }
}

class _CountdownBlocks extends StatelessWidget {
  const _CountdownBlocks({
    required this.label,
    required this.remaining,
    required this.target,
  });

  final String label;
  final CountdownRemaining remaining;
  final String target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = formatRemaining(remaining);
    final r = remaining;
    return Semantics(
      container: true,
      label: '$label: $summary',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _TimeBlock(r.days, 'dias')),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: _TimeBlock(r.hours, 'horas')),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: _TimeBlock(r.minutes, 'min')),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: _TimeBlock(r.seconds, 'seg')),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              summary,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              target,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock(this.value, this.unit);
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const fg = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.md,
        horizontal: Spacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [
          BoxShadow(
            color: Brand.blue.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              unit,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
