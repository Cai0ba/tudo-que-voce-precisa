import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../shared/picker_tile.dart';
import 'timezone_logic.dart';

/// Relógio injetável (sobrescreva em testes).
final timezoneClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Carrega a base de fusos de forma assíncrona (uma única vez).
final timezoneReadyProvider = FutureProvider<void>((ref) => ensureTimeZones());

const _citiesKey = 'timezone.cities';
const _originKey = 'timezone.origin';

class TimezoneScreen extends ConsumerStatefulWidget {
  const TimezoneScreen({super.key});

  @override
  ConsumerState<TimezoneScreen> createState() => _TimezoneScreenState();
}

class _TimezoneScreenState extends ConsumerState<TimezoneScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;
  late String _originId;
  late List<String> _cityIds;

  /// Instante fixado pelo usuário; nulo = acompanha o relógio.
  DateTime? _fixed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = ref.read(timezoneClockProvider)();
    final prefs = ref.read(sharedPreferencesProvider);
    final origin = prefs.getString(_originKey);
    _originId = origin != null && cityById(origin) != null
        ? origin
        : defaultOriginId;
    final saved = prefs.getStringList(_citiesKey);
    _cityIds = [
      for (final id in saved ?? defaultCityIds)
        if (cityById(id) != null) id,
    ];
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  void _refresh() {
    if (mounted) setState(() => _now = ref.read(timezoneClockProvider)());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
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
    super.dispose();
  }

  void _save() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setStringList(_citiesKey, _cityIds);
    prefs.setString(_originKey, _originId);
  }

  Future<String?> _chooseCity({Iterable<String> exclude = const []}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CitySheet(exclude: exclude),
    );
  }

  Future<void> _pickOrigin() async {
    final id = await _chooseCity();
    if (id == null || !mounted) return;
    setState(() {
      // Mantém o mesmo instante ao trocar a origem.
      _originId = id;
    });
    _save();
  }

  Future<void> _addCity() async {
    final id = await _chooseCity(exclude: _cityIds);
    if (id == null || !mounted) return;
    setState(() => _cityIds = [..._cityIds, id]);
    _save();
  }

  void _remove(String id) {
    setState(() => _cityIds = [..._cityIds]..remove(id));
    _save();
  }

  Future<void> _pickDateTime() async {
    final instant = _fixed ?? _now;
    final wall = wallClockOf(instant, _originId);
    final date = await showDatePicker(
      context: context,
      initialDate: wall,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(wall),
    );
    if (time == null || !mounted) return;
    setState(() {
      _fixed = instantFromWallClock(
        _originId,
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(timezoneReadyProvider);
    return ToolScaffold(
      title: 'Fuso horário',
      children: [
        if (ready.isLoading)
          const _Loading()
        else if (ready.hasError)
          const ErrorBanner('Não foi possível carregar os fusos horários.')
        else
          ..._content(),
      ],
    );
  }

  List<Widget> _content() {
    final instant = _fixed ?? _now;
    final origin = cityById(_originId)!;
    final wall = wallClockOf(instant, _originId);
    return [
      SectionCard(
        title: 'Cidade de origem',
        children: [
          PickerTile(
            icon: Icons.place_outlined,
            label: 'Cidade de origem',
            value: '${origin.name} (${origin.country})',
            onTap: _pickOrigin,
          ),
          PickerTile(
            icon: Icons.schedule,
            label: 'Data e hora em ${origin.name}',
            value:
                '${formatDate(wall)} ${formatClock(wall)}'
                '${_fixed == null ? ' (agora)' : ''}',
            onTap: _pickDateTime,
          ),
          if (_fixed != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => setState(() => _fixed = null),
                icon: const Icon(Icons.update),
                label: const Text('Usar data e hora atuais'),
              ),
            ),
        ],
      ),
      SectionHeader(
        'Outras cidades',
        trailing: TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _addCity,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
      ),
      if (_cityIds.isEmpty)
        const Text('Adicione cidades para comparar os horários.')
      else
        for (final id in _cityIds)
          _CityCard(
            key: ValueKey(id),
            city: cityById(id)!,
            time: convertInstant(instant, id, _originId),
            onRemove: () => _remove(id),
          ),
    ];
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Carregando fusos horários',
      child: const ExcludeSemantics(
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: Spacing.md),
            Expanded(child: Text('Carregando fusos horários…')),
          ],
        ),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.city,
    required this.time,
    required this.onRemove,
    super.key,
  });

  final City city;
  final ZonedTime time;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clock = formatClock(time.local);
    final day = dayLabel(time.dayDelta);
    final diff = formatDiff(time.diff);
    final diffText = time.diff == Duration.zero
        ? diff
        : '$diff em relação à origem';
    final dst = time.isDst ? 'horário de verão' : null;
    final utc = formatUtcOffset(time.offset);
    final label =
        '${city.name}, ${city.country}: $clock, $day, $diffText, '
        '$utc${dst == null ? '' : ', $dst'}';
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              container: true,
              label: label,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      city.country,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        clock,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Brand.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '$day · $diff · $utc',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (dst != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.xs),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wb_sunny_outlined,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Flexible(
                              child: Text(
                                'Horário de verão',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remover ${city.name}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _CitySheet extends StatefulWidget {
  const _CitySheet({required this.exclude});
  final Iterable<String> exclude;

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = searchCities(_query, exclude: widget.exclude);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                labelText: 'Buscar cidade',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(Spacing.md),
                    child: Text('Nenhuma cidade encontrada.'),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final c = results[i];
                      return ListTile(
                        minTileHeight: 48,
                        title: Text(c.name),
                        subtitle: Text(c.country),
                        onTap: () => Navigator.of(context).pop(c.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
