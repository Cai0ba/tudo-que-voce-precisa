import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tqvp/app/router/tool_screens.dart';
import 'package:tqvp/app/theme/app_theme.dart';
import 'package:tqvp/core/storage/preferences.dart';
import 'package:tqvp/features/tools/catalog.dart';

/// Renderiza cada ferramenta em tela pequena com fonte 200%, nos dois temas,
/// e confere ausência de overflow e áreas de toque/rótulos conforme as
/// diretrizes do Flutter.
void main() {
  for (final dark in [false, true]) {
    for (final tool in toolCatalog) {
      testWidgets('${tool.id} ${dark ? 'escuro' : 'claro'} 320x568 fonte 2x', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        await initializeDateFormatting('pt_BR');
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              locale: const Locale('pt', 'BR'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Builder(builder: toolScreens[tool.id]!),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
