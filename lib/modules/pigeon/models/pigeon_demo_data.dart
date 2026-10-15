import 'pigeon_models.dart';

/// Conteúdo de demonstração usado enquanto o serviço remoto do Pigeon
/// não estiver ligado ao aplicativo.
abstract final class PigeonDemoData {
  static const currentUser = PigeonProfile(
    name: 'Você',
    id: 'pru_local',
    bio: 'Perfil do enxOS',
    isOnline: true,
  );

  static List<PigeonConversation> conversations() => [
    PigeonConversation(
      profile: const PigeonProfile(
        name: 'Alice',
        id: 'pru_882910',
        bio: 'Desenvolvedora Fullstack & EnX Contributor',
        isOnline: true,
        verification: PigeonVerification.blue,
      ),
      lastMessage: 'Oi, tudo bem?',
      timeLabel: '10:32',
      unreadCount: 2,
      messages: [
        const PigeonChatMessage(
          body: 'Olá! Como vão as coisas por aí?',
          isMine: false,
          timeLabel: '10:30',
        ),
        const PigeonChatMessage(
          body: 'Tudo ótimo por aqui, estruturando o ecossistema.',
          isMine: true,
          timeLabel: '10:32',
        ),
      ],
    ),
    PigeonConversation(
      profile: const PigeonProfile(
        name: 'Bob',
        id: 'pru_441029',
        bio: 'Moderador Oficial do Sistema • EnX OS',
        isOnline: true,
        verification: PigeonVerification.system,
      ),
      lastMessage: 'Viu o feed?',
      timeLabel: '09:15',
    ),
    PigeonConversation(
      profile: const PigeonProfile(
        name: 'Carol',
        id: 'pru_992104',
        bio: 'Exploradora de dados e redes descentralizadas',
      ),
      lastMessage: 'Pode falar agora?',
      timeLabel: 'Ontem',
      unreadCount: 1,
    ),
  ];

  static List<PigeonProfile> contacts() => const [
    PigeonProfile(
      name: 'Alice',
      id: 'pru_882910',
      bio: 'Desenvolvedora Fullstack & EnX Contributor',
      isOnline: true,
      verification: PigeonVerification.blue,
    ),
    PigeonProfile(
      name: 'Bob',
      id: 'pru_441029',
      bio: 'Moderador Oficial do Sistema • EnX OS',
      isOnline: true,
      verification: PigeonVerification.system,
    ),
    PigeonProfile(
      name: 'Carol',
      id: 'pru_992104',
      bio: 'Exploradora de dados e redes descentralizadas',
    ),
    PigeonProfile(
      name: 'Dave',
      id: 'pru_112344',
      bio: 'Trader de ativos digitais',
      isOnline: true,
      verification: PigeonVerification.blue,
    ),
  ];

  static List<PigeonFeedPost> posts() => [
    PigeonFeedPost(
      author: const PigeonProfile(
        name: 'Alice',
        id: 'pru_882910',
        isOnline: true,
        verification: PigeonVerification.blue,
      ),
      timeLabel: 'Há 45 min',
      content:
          'Arquitetura limpa e desacoplada é a chave para a longevidade de qualquer ecossistema modular. Focado no novo build de hoje! 🚀',
      likes: 14,
      comments: 3,
    ),
    PigeonFeedPost(
      author: const PigeonProfile(
        name: 'Bob',
        id: 'pru_441029',
        isOnline: true,
        verification: PigeonVerification.system,
      ),
      timeLabel: 'Há 3 horas',
      content:
          'Canal global de PTT estabilizado. Testes de latência abaixo de 20ms na rede interna.',
      likes: 28,
      comments: 7,
    ),
  ];
}
