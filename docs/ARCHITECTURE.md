# Arquitetura

```
lib/
  app/        app.dart, router/, theme/ (tokens, tema M3)
  core/       formatting/ (pt-BR, Decimal), storage/, widgets/ (ToolScaffold, ResultCard…)
  features/
    tools/    modelo Tool + catálogo estático tipado (ids estáveis)
    home, search, favorites
    calculators/, converters/, organization/, utilities/   (uma pasta por ferramenta)
```

- **Catálogo** (`features/tools/catalog.dart`) é a fonte única: home, busca, favoritos e rotas (`/tool/:id`) derivam dele. `app/router/tool_screens.dart` mapeia id → tela; um teste garante que todo id tem tela.
- **Domínio** (cálculos, conversões) é Dart puro, sem Flutter, testado isoladamente; telas só apresentam.
- **Estado**: Riverpod (`Notifier`). `SharedPreferences` entra por `sharedPreferencesProvider`, sobrescrito em `main()` e nos testes.
- **Dinheiro/precisão**: pacote `decimal`; `parseDecimal` aceita vírgula pt-BR.
- **Dados locais**: só no aparelho; ver DECISIONS.

- **Widget Android de favoritos** (`features/widgets/`): `WidgetSyncService` grava via `home_widget` (`fav_count`, `fav_<i>_id/_name/_cat`, até 4) e chama `updateWidget` ao favoritar (`favoritesProvider`) e na inicialização (`main`); a porta `WidgetGateway` é injetável e vira no-op fora do Android/em testes, e falhas nunca propagam. O lado nativo (`FavoritesWidgetProvider.kt`, layout/XML em `android/app/src/main/res`) usa um ícone vetorial por **categoria** (`ic_widget_<categoria>`; `IconData` do Flutter não existe no nativo) e abre deep links `tqvp://tool/<id>` (ou `tqvp://home` sem favoritos), convertidos em rota por `routeForWidgetUri` e tratados em `app.dart` (`initiallyLaunchedFromHomeWidget` + `widgetClicked`).
