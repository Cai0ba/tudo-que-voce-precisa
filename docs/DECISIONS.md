# Decisões

Formato: problema · alternativas · escolha · custos · quando revisitar.

1. **Estado: Riverpod 3** (`flutter_riverpod`). Alt.: Provider, Bloc. Simples, testável, overrides fáceis. Revisar se o grafo de estado crescer muito.
2. **Navegação: go_router** com rota única `/tool/:id`. Alt.: Navigator 1.0. Rotas declarativas e deep links futuros.
3. **Persistência: shared_preferences (JSON)** para favoritos, tarefas, checklists e notas no MVP. Alt.: SQLite (drift/sqflite). Menos dependências nativas e testes simples; custo: sem consultas, regrava a lista inteira. Revisar com milhares de itens, busca em notas ou anexos.
4. **Precisão: `decimal`** em cálculos monetários/percentuais para evitar erros de ponto flutuante.
5. **Busca**: substring sem acentos sobre nome/descrição/categoria/palavras-chave; sem IA. Revisar se o catálogo passar de ~50 ferramentas.
6. **Moedas**: fonte e política em `docs/currency-source.md`.
7. **Análise estática**: `tool/analyze.sh` por causa do caminho com acento.
8. **Sem web no MVP**: apenas Android e iOS foram gerados.
