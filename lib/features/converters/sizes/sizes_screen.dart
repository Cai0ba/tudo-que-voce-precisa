import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/formatting/number_utils.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/tool_scaffold.dart';
import 'sizes_data.dart';
import 'sizes_logic.dart';

const sizesDisclaimer =
    'As tabelas variam por marca e por modelo. Use como referência e '
    'confira a tabela do fabricante antes de comprar.';

String _cm(double v) =>
    formatDecimal(Decimal.parse(v.toString()), maxFractionDigits: 1);

String _range(CmRange r) =>
    r.min == r.max ? _cm(r.min) : '${_cm(r.min)}–${_cm(r.max)}';

/// Tabelas de correspondência de tamanhos de calçados e roupas.
class SizesScreen extends StatefulWidget {
  const SizesScreen({super.key});

  @override
  State<SizesScreen> createState() => _SizesScreenState();
}

class _SizesScreenState extends State<SizesScreen> {
  bool _shoes = true;

  // Calçados
  ShoeCategory _shoeCategory = ShoeCategory.women;
  ShoeSystem _shoeSystem = ShoeSystem.br;
  String? _shoeValue;

  // Roupas
  ClothingGender _gender = ClothingGender.women;
  ClothingPart _part = ClothingPart.top;
  int? _clothingNumber;

  Widget _chips<T>({
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T) text,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(text(v)),
                selected: v == selected,
                onSelected: (_) => setState(() => onSelected(v)),
              ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------ Calçados

  List<Widget> _shoeChildren() {
    final options = shoeOptions(_shoeCategory, _shoeSystem);
    final value = options.contains(_shoeValue) ? _shoeValue! : options.first;
    final matches = shoeMatches(_shoeCategory, _shoeSystem, value);
    final others = ShoeSystem.values.where((s) => s != _shoeSystem).toList();

    return [
      SectionCard(
        title: 'Calçado',
        children: [
          _chips<ShoeCategory>(
            label: 'Público',
            values: ShoeCategory.values,
            selected: _shoeCategory,
            text: (c) => c.label,
            onSelected: (c) {
              _shoeCategory = c;
              _shoeValue = null;
            },
          ),
          _chips<ShoeSystem>(
            label: 'Meu número está em',
            values: ShoeSystem.values,
            selected: _shoeSystem,
            text: (s) => s.label,
            onSelected: (s) {
              _shoeSystem = s;
              _shoeValue = null;
            },
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('shoe-$_shoeCategory-$_shoeSystem-$value'),
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Número'),
            items: [
              for (final o in options)
                DropdownMenuItem(value: o, child: Text(o)),
            ],
            onChanged: (v) => setState(() => _shoeValue = v),
          ),
        ],
      ),
      for (final m in matches)
        ResultCard(
          label: 'Equivale a (${_shoeSystem.label} $value)',
          value: others.map((s) => '${s.label} ${m.valueOf(s)}').join(' · '),
          detail: [
            if (m.age != null) 'Idade: ${m.age}',
            if (m.footCm != null)
              'Comprimento do pé: ${_cm(m.footCm!)} cm'
            else if (_shoeCategory != ShoeCategory.baby)
              'Comprimento do pé: não informado pela fonte',
          ].join('\n'),
        ),
      _shoeTable(),
    ];
  }

  Widget _shoeTable() {
    final rows = shoeRows(_shoeCategory);
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Tabela completa (${_shoeCategory.label.toLowerCase()})',
      children: [
        for (final r in rows)
          Semantics(
            container: true,
            child: Text(
              '${r.age != null ? '${r.age}: ' : ''}'
              'BR ${r.br} · EUA ${r.us} · EU ${r.eu}'
              '${r.footCm != null ? ' · ${_cm(r.footCm!)} cm' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- Roupas

  List<Widget> _clothingChildren() {
    final rows = clothingRows(_gender);
    final selected = rows.firstWhere(
      (r) => r.number == _clothingNumber,
      orElse: () => rows.first,
    );
    final top = _part == ClothingPart.top;
    final upperName = _gender == ClothingGender.women ? 'Busto' : 'Tórax';
    final women = _gender == ClothingGender.women;

    final lines = <String>[
      if (top) ...[
        '$upperName: ${_range(selected.upper)} cm',
        if (selected.shoulders != null)
          'Ombros: ${_range(selected.shoulders!)} cm',
      ] else ...[
        'Cintura: ${_range(selected.waist)} cm',
        'Quadril: ${_range(selected.hip)} cm',
      ],
    ];

    final approx = <String>[];
    if (women) {
      approx.add('Europa ≈ ${euWomenApprox(selected, _part)}');
      final us = usWomenApprox(selected, _part);
      if (us != null) approx.add('EUA ≈ $us');
    }

    return [
      SectionCard(
        title: 'Roupa',
        children: [
          _chips<ClothingGender>(
            label: 'Público',
            values: ClothingGender.values,
            selected: _gender,
            text: (g) => g.label,
            onSelected: (g) {
              _gender = g;
              _clothingNumber = null;
            },
          ),
          _chips<ClothingPart>(
            label: 'Peça',
            values: ClothingPart.values,
            selected: _part,
            text: (p) => p.label,
            onSelected: (p) => _part = p,
          ),
          DropdownButtonFormField<int>(
            key: ValueKey('cl-$_gender-${selected.number}'),
            initialValue: selected.number,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Numeração brasileira (manequim)',
            ),
            items: [
              for (final r in rows)
                DropdownMenuItem(
                  value: r.number,
                  child: Text('${r.number} (${r.letter})'),
                ),
            ],
            onChanged: (v) => setState(() => _clothingNumber = v),
          ),
        ],
      ),
      ResultCard(
        label: 'Manequim ${selected.number}',
        value: '${selected.letter} · ${selected.english} (inglês)',
        detail: [
          ...lines,
          if (approx.isNotEmpty) 'Aproximado por medida: ${approx.join(' · ')}',
        ].join('\n'),
      ),
      _clothingTable(rows, upperName),
      if (!women)
        const AppCard(
          child: Text(
            'Não encontramos fonte confiável para numeração masculina '
            'europeia/americana, por isso só mostramos a equivalência em '
            'letras (PP/XS, P/S, M, G/L, GG/XL).',
          ),
        ),
    ];
  }

  Widget _clothingTable(List<ClothingSize> rows, String upperName) {
    final theme = Theme.of(context);
    final top = _part == ClothingPart.top;
    return SectionCard(
      title: 'Tabela completa (${_gender.label.toLowerCase()})',
      children: [
        for (final r in rows)
          Semantics(
            container: true,
            child: Text(
              '${r.number} · ${r.letter}/${r.english} · '
              '${top ? '$upperName ${_range(r.upper)} cm' : 'cintura '
                        '${_range(r.waist)} cm · quadril ${_range(r.hip)} cm'}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      title: 'Tamanhos',
      children: [
        SectionCard(
          children: [
            _chips<bool>(
              label: 'Tabela',
              values: const [true, false],
              selected: _shoes,
              text: (v) => v ? 'Calçados' : 'Roupas',
              onSelected: (v) => _shoes = v,
            ),
          ],
        ),
        ..._shoes ? _shoeChildren() : _clothingChildren(),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(
                child: IconBadge(Icons.info_outline, size: 40),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(sizesDisclaimer, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
