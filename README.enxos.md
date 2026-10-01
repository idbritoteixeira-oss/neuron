# enxOS — Flutter/Dart

Aplicativo modular Flutter com sessão global enxOS, sessões isoladas para Inasx,
Pigeon e FreeMarket, e uma ação opcional de serviço Android em primeiro plano.

## Estrutura

- `lib/core/enxos/` — estado global, autenticação, dashboard e serviço.
- `lib/modules/inasx/`, `lib/modules/pigeon/`, `lib/modules/freemarket/` — telas-base independentes.
- `android/` — aplicação Android, permissões e integração com `flutter_foreground_task`.
- `web/` — shell web padrão do Flutter.
- `.github/workflows/android_build.yml` — build do APK de release ao enviar para `main` ou manualmente.

## Executar e compilar

Com Flutter stable instalado:

```sh
flutter pub get
flutter run
flutter build apk --release
```

O workflow publica o APK como artefato `enxos-release-apk`. O APK de release
usa a assinatura de depuração até que uma chave de assinatura de produção seja
configurada.

## Autenticação: demonstração, não produção

Não foi fornecido um serviço de identidade nem uma regra para confirmar quais
IDs privados são válidos. Para permitir demonstrar o fluxo sem inventar
credenciais, a implementação atual aceita campos não vazios e marca a tela como
modo de demonstração. **Isso não autentica identidade e não deve ser usado com
credenciais reais ou publicado como proteção de acesso.**

Conecte uma implementação de `EnxosAuthRepository` ao serviço de identidade
enxOS e substitua a verificação de demonstração de `ModuleState` por validação
no serviço de cada módulo. Não coloque IDs privados ou hashes de credenciais no
aplicativo cliente. Os campos privados não são guardados em estado persistente.

## Serviço em primeiro plano

O usuário pode ativar/desativar o serviço no dashboard; o Android solicita
permissão de notificações quando necessário. A notificação é persistente
enquanto o serviço está ativo. O serviço só reinicia após reiniciar o aparelho
se isso for implementado explicitamente; o início automático está desligado.

O serviço usa o tipo `dataSync`; Android 15+ limita a execução de serviços desse
tipo a seis horas por janela de 24 horas. Antes de publicar, confirme que esse
tipo e a finalidade do serviço atendem às políticas e ao caso de uso do app.