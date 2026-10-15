enum PigeonVerification { none, blue, system }

class PigeonProfile {
  const PigeonProfile({
    required this.name,
    required this.id,
    this.bio = '',
    this.isOnline = false,
    this.verification = PigeonVerification.none,
    this.avatarUrl,
    this.isBlocked = false,
  });

  final String name;
  final String id;
  final String bio;
  final bool isOnline;
  final PigeonVerification verification;
  final String? avatarUrl;
  final bool isBlocked;

  String get initial {
    final value = name.trim();
    return value.isEmpty ? '?' : value.substring(0, 1).toUpperCase();
  }
}

class PigeonChatMessage {
  const PigeonChatMessage({
    required this.body,
    required this.isMine,
    required this.timeLabel,
  });

  final String body;
  final bool isMine;
  final String timeLabel;
}

class PigeonConversation {
  PigeonConversation({
    required this.profile,
    required this.lastMessage,
    required this.timeLabel,
    this.unreadCount = 0,
    List<PigeonChatMessage>? messages,
  }) : messages = messages ?? <PigeonChatMessage>[];

  final PigeonProfile profile;
  String lastMessage;
  String timeLabel;
  int unreadCount;
  final List<PigeonChatMessage> messages;
}

class PigeonFeedPost {
  PigeonFeedPost({
    required this.author,
    required this.timeLabel,
    required this.content,
    required this.likes,
    required this.comments,
    this.imageUrl,
    this.isLiked = false,
  });

  final PigeonProfile author;
  final String timeLabel;
  final String content;
  final int comments;
  final String? imageUrl;
  int likes;
  bool isLiked;
}
