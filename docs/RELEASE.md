# Build, release e testes manuais

## Comandos
```
dart format --output=none --set-exit-if-changed .
tool/analyze.sh          # em vez de flutter analyze (caminho com acento)
flutter test
flutter build apk --debug      # verificado
flutter build appbundle --release   # verificado (assinado com chave de debug sem key.properties)
flutter build ipa              # requer macOS/Xcode (não verificado)
```

## Pendências de release
- Assinatura: crie o keystore e `android/key.properties` (modelo em `android/key.properties.example`; ambos ignorados pelo git). Sem ele o release usa a chave de debug — **não publicar assim**. Falta também ícone e nome finais; `applicationId` (hoje `br.com.tqvp.tqvp`).
- iOS: nunca compilado (sem macOS). Revisar Info.plist (sem permissões extras previstas).
- Política de privacidade: dados ficam no aparelho; só moedas usa rede (Frankfurter, sem dados do usuário).

## Checklist manual em dispositivo
- [ ] Tema claro/escuro; fonte ampliada (200%); telas pequenas e tablet.
- [ ] TalkBack/VoiceOver nas telas de calculadora e moedas.
- [ ] Moedas: online, modo avião com cache, sem cache (tentar novamente).
- [ ] Tarefas/checklists/notas persistem após fechar o app.
- [ ] Contagem regressiva ao ir para segundo plano e voltar.
- [ ] QR Code: compartilhar PNG.
- [ ] Favoritos e busca ("dólar", "desconto", "peso", "quantos anos").

## Acessibilidade/layout
`test/a11y/layout_a11y_test.dart` renderiza as 16 ferramentas em 320x568, fonte 200%, tema claro/escuro, verificando overflow, alvos de toque, rótulos e contraste (passa). Não substitui o teste com TalkBack/VoiceOver.
