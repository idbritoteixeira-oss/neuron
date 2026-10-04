# enxOS — Flutter/Dart

Aplicativo modular Flutter com sessão global enxOS, sessões isoladas para Inasx,
Pigeon e FreeMarket, e uma ação opcional de serviço Android em primeiro plano.

## Estrutura

- `lib/core/enxos/` — estado global, autenticação, dashboard e serviço.
- `lib/modules/inasx/`, `lib/modules/pigeon/`, `lib/modules/freemarket/` — telas-base independentes.
- `android/` — aplicação Android, permissões e integração com `flutter_foreground_task`.
- `web/` — shell web padrão do Flutter.
- `.github/workflows/android_build.yml` — build do APK de release ao enviar para `main` ou manualmente.

## Interface compartilhada

Login, dashboard e telas dos módulos usam o mesmo `EnxosShell`: cartão central
responsivo, marca enxOS, menu de tema/configurações, corpo rolável e rodapé.
As cores claras/escuras vêm da referência em `UI/`; a preferência fica salva no
dispositivo. O fundo em grade sincroniza sua cor a cada 12 segundos com
`https://tts.enxos.online/s/r2021.php`. Se a rede não responder, a interface
continua com a cor-base do tema e mantém a última cor sincronizada.

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

## Inventário dos arquivos do APK

O APK é um pacote compilado; os fontes não ficam organizados dentro dele como
no repositório. Este inventário descreve os arquivos-fonte e as configurações
que formam o aplicativo Android enxOS.

### Aplicativo Flutter

- `lib/main.dart` — ponto de entrada. Inicializa o Flutter e o canal do serviço
  Android, restaura a preferência de tema e registra os estados compartilhados.
- `lib/core/enxos/enxos_app.dart` — cria o `MaterialApp` e direciona para o login
  ou para o dashboard conforme a sessão enxOS.
- `lib/core/enxos/enx_module.dart` — cadastro dos módulos: título, abreviação,
  cor de marca, identificador e descrição. As cores atuais são Inasx `#6F7175`,
  Pigeon `#5AB31E` e FreeMarket `#B3611E`.
- `lib/core/enxos/enxos_shell.dart` — estrutura visual compartilhada, cabeçalho,
  menu de ações, conteúdo e rodapé.
- `lib/core/enxos/enxos_theme.dart` — paletas e temas claro/escuro.
- `lib/core/enxos/enxos_grid_painter.dart` — desenho da grade do fundo.
- `lib/core/enxos/enxos_ui_state.dart` — alternância e persistência local do
  tema usando `shared_preferences`.
- `lib/core/enxos/enxos_watercolor_state.dart` — consulta a cor remota do fundo,
  atualizada periodicamente, e mantém o estado de conexão.
- `lib/core/enxos/auth_repository.dart` — contrato e implementação de demonstração
  para autenticação global.
- `lib/core/enxos/auth_state.dart` — estado de login, carregamento, erro e saída
  da sessão global.
- `lib/core/enxos/login_screen.dart` — formulário e avisos do login enxOS.
- `lib/core/enxos/dashboard_screen.dart` — dashboard, cartões dos módulos e
  tela-base aberta depois do desbloqueio de cada módulo.
- `lib/core/enxos/module_state.dart` — autenticação de demonstração e sessões
  independentes dos módulos.
- `lib/core/enxos/module_unlock_dialog.dart` — diálogo de credenciais para abrir
  um módulo.
- `lib/core/enxos/foreground_service.dart` — controle do serviço Android e da
  notificação persistente opcional.
- `lib/modules/inasx/inasx_screen.dart` — tela inicial do módulo Inasx.
- `lib/modules/pigeon/pigeon_screen.dart` — tela inicial do módulo Pigeon.
- `lib/modules/freemarket/freemarket_screen.dart` — tela inicial do módulo
  FreeMarket.

### Integração Android

- `android/app/src/main/AndroidManifest.xml` — nome do app, permissões, atividade
  inicial e registro do serviço em primeiro plano.
- `android/app/src/main/kotlin/com/enxos/app/MainActivity.kt` — atividade Android
  que hospeda o Flutter.
- `android/app/src/main/res/drawable/ic_launcher.xml` — ícone vetorial do app.
- `android/app/src/main/res/values/styles.xml` e
  `android/app/src/main/res/values-night/styles.xml` — estilos Android usados
  durante a inicialização e pela janela do app.
- `android/app/build.gradle` — identificador `com.enxos.app`, SDK mínimo 21,
  opções de compilação e configuração de release.
- `android/settings.gradle` e `android/build.gradle` — carregamento do SDK
  Flutter e configuração dos plugins Gradle/Android.
- `android/gradle.properties` — parâmetros do Gradle e suporte ao AndroidX.
- `android/gradle/wrapper/` e `android/gradlew*` — versão e scripts do Gradle
  usados para compilar a parte Android.
- `pubspec.yaml` — metadados e dependências Flutter/Dart: `provider`,
  `shared_preferences`, `http` e `flutter_foreground_task`.

### Geração e limites do pacote

- `flutter build apk --release` gera
  `build/app/outputs/flutter-apk/app-release.apk`.
- `.github/workflows/android_build.yml` executa o build em pushes para `main` ou
  manualmente e publica o arquivo como artefato `enxos-release-apk`.
- A configuração atual de release usa assinatura de depuração. Configure uma
  chave de assinatura de produção antes de distribuir o APK publicamente.
- Os repositórios de autenticação atuais são apenas demonstrações: não validam
  identidade real. Não use credenciais reais nem trate essa autenticação como
  proteção de acesso.
- O shell Flutter web em `web/`, o preview `artifacts/enxos-webview` e os pacotes
  TypeScript/Node do workspace não são incluídos neste APK Android.