# Fonte de câmbio do conversor de moedas

## Problema
O conversor precisa de taxas reais, sem chave de API (não pode haver segredo
no app), com cobertura de BRL e das moedas usuais (USD, EUR, GBP, ARS, JPY,
CAD, AUD, CHF, CNY), sem custo e com termos de uso compatíveis com um app
distribuído. Nunca se usam taxas inventadas ou embutidas.

## Alternativas avaliadas (consultadas em 2026-10-16)

| Fonte | Chave | Frequência | Limites | Cobertura | Observações |
|---|---|---|---|---|---|
| Frankfurter v2 (`api.frankfurter.dev/v2/rates?base=BRL`) | Não | Diária (dias úteis) | Sem cota; limite anti-abuso; resposta cacheável (`max-age` ~5,5 h, `stale-if-error`) | ~160 moedas, de bancos centrais/fontes oficiais; testado: BRL, USD, EUR, GBP, ARS, JPY, CAD, AUD, CHF, CNY presentes | Código aberto; cada taxa traz sua data. A v1 (só BCE) NÃO tem ARS. |
| open.er-api.com (`/v6/latest/BRL`) | Não | Diária, informa próxima atualização | HTTP 429 por 20 min se abusar; sugerem 1 req/dia | ~160 moedas | Exige atribuição ("Rates By Exchange Rate API") e proíbe redistribuição; termos mais restritivos. |
| AwesomeAPI (`economia.awesomeapi.com.br/json/last/...`) | Opcional (recomendada) | Quase tempo real (cache 1 min sem chave) | Sem chave, sujeito a limite; termos de uso não publicados na documentação | Muitas moedas, foco BR | Pares individuais; sem termos claros para uso em app; cotação "tempo real" de mercado não é necessária aqui. |

## Escolha
**Frankfurter v2**, uma única requisição `GET /v2/rates?base=BRL`, que devolve
todas as moedas em relação ao BRL. Conversões entre quaisquer duas moedas
usam taxa cruzada: `taxa(A→B) = rates[B] / rates[A]` (BRL = 1).
Motivos: sem chave, sem cota declarada, fontes oficiais, licença aberta,
cobre ARS e BRL, cada taxa traz a data de referência, uma requisição cobre
todas as moedas (fácil de colocar em cache offline).

O app guarda a última resposta válida em `shared_preferences` e a exibe
quando a rede falha, sempre com a data/hora e o aviso "desatualizada" se
passar de 24 h.

## Limitações
- Taxas de referência diárias, não de mercado em tempo real; não incluem
  spread de casas de câmbio, IOF ou tarifas. Não use para operações financeiras.
- Algumas moedas são atualizadas em dias diferentes (a data é por moeda); o
  app mostra a data da cotação mais antiga entre as duas moedas usadas.
- ARS e moedas de alta inflação/múltiplas cotações podem divergir da taxa
  praticada no mercado.
- Serviço mantido por terceiros, sem SLA; o endpoint pode mudar.

## Quando revisitar
- Se a API v2 mudar/for descontinuada ou passar a exigir chave ou cobrar.
- Se surgirem erros recorrentes de limite (HTTP 429) ou indisponibilidade.
- Se for necessária cotação intradiária (avaliar AwesomeAPI com chave, via
  proxy próprio para não expor segredos no app) ou histórico.
- Se os termos de uso/licença mudarem.
- Android: o `AndroidManifest.xml` principal precisa da permissão
  `android.permission.INTERNET` para builds de release.
