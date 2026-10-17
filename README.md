# Tudo Que Você Precisa (TQVP)

Aplicativo Flutter (Android e iOS) que reúne ferramentas práticas do dia a dia em um só lugar: calculadoras, conversores, organização pessoal e utilidades. Em português do Brasil, sem cadastro, gratuito e com foco em funcionar offline.

## Ferramentas (21)

| Categoria | Ferramentas |
|---|---|
| Calculadoras | Porcentagem, Descontos, Regra de três, IMC, Idade, Combustível (álcool × gasolina, consumo, custo de viagem) |
| Conversores | Moedas, Comprimento, Massa, Temperatura, Volume, Culinária, Tamanhos (roupas e calçados) |
| Organização | Tarefas, Checklists, Notas rápidas, Controle de gastos |
| Utilidades | Diferença entre datas, Contagem regressiva, QR Code, Fuso horário |

Também: busca por nome, categoria e termos comuns ("dólar", "quantos anos"), favoritos, tema claro/escuro e widget de favoritos na tela inicial do Android.

## Privacidade e dados

- Sem conta, sem backend próprio, sem anúncios e sem rastreamento.
- Tarefas, checklists, notas, gastos, favoritos e preferências ficam **somente no aparelho** (`shared_preferences`, em JSON).
- A única chamada de rede é a cotação de moedas ([Frankfurter](https://frankfurter.dev), sem chave de API e sem enviar dados do usuário). Sem rede, o app usa a última cotação salva e informa a data. Detalhes em [docs/currency-source.md](docs/currency-source.md).

## Stack

Flutter 3.47 / Dart 3.13, Material 3 com identidade azul própria, Riverpod (estado), go_router (navegação), `decimal` (precisão em cálculos e dinheiro), `timezone` (fusos offline), `qr_flutter` + `share_plus` (QR Code) e `home_widget` (widget Android).

## Como rodar

Requisitos: Flutter estável instalado (`flutter doctor` sem erros) e um emulador ou aparelho Android.

```bash
flutter pub get
flutter emulators --launch <id-do-emulador>   # veja os ids com: flutter emulators
flutter run
```

## Qualidade

```bash
dart format --output=none --set-exit-if-changed .
tool/analyze.sh      # use no lugar de `flutter analyze`
flutter test
```

- `tool/analyze.sh` existe porque o `flutter analyze` falha em caminhos com acento (ex.: "Área de trabalho"); o script analisa uma cópia em caminho ASCII.
- Os testes cobrem domínio (cálculos, conversões, datas), telas e persistência. `test/a11y/` renderiza todas as ferramentas em 320×568, fonte 200%, nos temas claro e escuro, checando overflow, alvos de toque, rótulos e contraste.

## Estrutura

```
lib/
  app/        tema (tokens, Material 3), rotas
  core/       formatação pt-BR, armazenamento, componentes (AppCard, ResultCard…)
  features/   uma pasta por ferramenta + tools/ (catálogo), home, search, favorites, widgets
```

Cada ferramenta separa **domínio puro em Dart** (sem Flutter, testado) da **tela**. O catálogo em `lib/features/tools/catalog.dart` é a fonte única para home, busca, favoritos e rotas.

### Adicionar uma nova ferramenta

1. Crie `lib/features/<categoria>/<id>/<id>_screen.dart` (domínio em arquivo separado).
2. Registre em `lib/features/tools/catalog.dart` (id estável, nome, descrição, categoria, ícone, palavras-chave).
3. Mapeie o id em `lib/app/router/tool_screens.dart`.
4. Adicione testes. O teste de catálogo e o de acessibilidade passam a cobrir a nova ferramenta automaticamente.

## Release

Build e publicação: [docs/RELEASE.md](docs/RELEASE.md). Resumo do estado:

- Android: APK/AAB de release gerados, mas assinados com chave de debug até existir `android/key.properties` (modelo em `android/key.properties.example`). **Não publique assim.**
- iOS: projeto gerado, mas nunca compilado (exige macOS e Xcode).
- Falta ainda: ícone final, política de privacidade e teste manual em aparelhos (checklist em `docs/RELEASE.md`).

## Documentação

- [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md): fases e estado
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): arquitetura e widget Android
- [docs/DECISIONS.md](docs/DECISIONS.md): decisões técnicas e quando revisitá-las
- Fontes de dados: [moedas](docs/currency-source.md), [culinária](docs/cooking-sources.md), [tamanhos](docs/size-sources.md)

## Limitações conhecidas

- Culinária e Tamanhos usam valores aproximados que variam por marca e fonte.
- Cotações são de referência diária, sem spread, tarifas ou IOF.
- O IMC é só um indicador para adultos e não é diagnóstico.
- O widget Android foi verificado apenas por compilação e testes unitários.
