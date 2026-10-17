# TQVP — Plano do projeto

## Diagnóstico (Fase 0)
- Repositório vazio (sem git). Flutter 3.47.7 stable, Dart 3.13.5.
- `flutter doctor`: Android SDK OK, Chrome e Linux OK. Sem macOS/Xcode → **builds iOS não podem ser executados neste ambiente**.
- Limitação: `flutter analyze` quebra com caminhos não-ASCII ("Área de trabalho"). Use `tool/analyze.sh` (analisa uma cópia em `/tmp`).

## Fases e estado
| Fase | Conteúdo | Estado |
|---|---|---|
| 0 | Diagnóstico e docs | Implementado |
| 1 | Fundação: tema M3 claro/escuro, go_router, catálogo tipado, home, busca, favoritos | Implementado e testado (3 testes) |
| 2 | Calculadoras (5) | Implementado e testado |
| 3 | Conversores + moedas | Implementado e testado |
| 4 | Tarefas, checklists, notas | Implementado e testado |
| 5 | Datas, contagem, QR (busca/favoritos já na Fase 1) | Implementado e testado |
| 6 | Polimento, release, checklist manual | Parcial: a11y/layout testado automaticamente; AAB/APK release gerados; falta keystore, iOS e teste em dispositivo |

## Riscos
- iOS não verificável aqui (sem macOS).
- Fonte de câmbio gratuita sem SLA; ver `docs/currency-source.md`.
- Persistência em JSON/shared_preferences não escala para grandes volumes (ver DECISIONS).

## Pós-MVP
- Visual redesenhado (azul/branco, cards) e grade na home.
- Adicionadas: combustível, culinária, tamanhos, fuso horário, controle de gastos e widget Android de favoritos (21 ferramentas).
