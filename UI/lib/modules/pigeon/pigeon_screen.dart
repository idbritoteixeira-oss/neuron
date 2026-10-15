import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enxos/auth_state.dart';
import '../../core/enxos/enx_module.dart';
import '../../core/enxos/enxos_shell.dart';
import '../../core/enxos/enxos_theme.dart';
import 'chat_detail_view.dart';
import 'models/pigeon_demo_data.dart';
import 'models/pigeon_models.dart';
import 'profile/pigeon_contact_profile_sheet.dart';
import 'profile/pigeon_profile_screen.dart';
import 'services/pigeon_notification_sound.dart';
import 'services/pigeon_profile_store.dart';
import 'tabs/contacts_tab.dart';
import 'tabs/feed_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/ptt_tab.dart';
import 'widgets/pigeon_avatar.dart';
import 'widgets/pigeon_fab.dart';
import 'widgets/pigeon_search_bar.dart';
import 'widgets/pigeon_tab_bar.dart';

/// Controlador das abas do Pigeon e da abertura do detalhe de conversa.
class PigeonScreen extends StatefulWidget {
  const PigeonScreen({required this.onLauncherTap, super.key});

  final EnxosLauncherCallback onLauncherTap;

  @override
  State<PigeonScreen> createState() => _PigeonScreenState();
}

class _PigeonScreenState extends State<PigeonScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF5AB31E);

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<PigeonConversation> _conversations =
      PigeonDemoData.conversations();
  final List<PigeonProfile> _contacts = PigeonDemoData.contacts();
  final List<PigeonFeedPost> _posts = PigeonDemoData.posts();
  PigeonProfile _currentUser = PigeonDemoData.currentUser;

  int _tabIndex = 0;
  String _searchQuery = '';
  PigeonConversation? _activeChat;
  bool _notificationSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocalPreferences();
    });
  }

  Future<void> _loadLocalPreferences() async {
    final id = context.read<AuthState>().publicId?.trim();
    final userId = id == null || id.isEmpty
        ? PigeonDemoData.currentUser.id
        : id;
    final fallback = PigeonProfile(name: userId, id: userId, isOnline: true);

    try {
      final results = await Future.wait<Object>([
        PigeonProfileStore.load(fallback),
        PigeonNotificationSound.isEnabled(),
      ]);
      if (!mounted) return;
      setState(() {
        _currentUser = results[0] as PigeonProfile;
        _notificationSoundEnabled = results[1] as bool;
      });
    } catch (_) {
      // Mantém o perfil de demonstração e o som ativado se o armazenamento
      // local ainda não estiver disponível.
    }
  }

  void _handleTabChange() {
    if (mounted && _tabIndex != _tabController.index) {
      setState(() => _tabIndex = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String value) =>
      value.toLowerCase().contains(_searchQuery.trim().toLowerCase());

  List<PigeonConversation> get _visibleConversations => _conversations
      .where(
        (conversation) => _matches(
          '${conversation.profile.name} ${conversation.profile.id} '
          '${conversation.lastMessage}',
        ),
      )
      .toList(growable: false);

  List<PigeonProfile> get _visibleContacts => _contacts
      .where(
        (contact) => _matches('${contact.name} ${contact.id} ${contact.bio}'),
      )
      .toList(growable: false);

  List<PigeonFeedPost> get _visiblePosts => _posts
      .where((post) => _matches('${post.author.name} ${post.content}'))
      .toList(growable: false);

  void _openConversation(PigeonConversation conversation) {
    conversation.unreadCount = 0;
    setState(() => _activeChat = conversation);
  }

  void _openContact(PigeonProfile contact) {
    final existing = _conversations.where(
      (conversation) => conversation.profile.id == contact.id,
    );
    final conversation = existing.isNotEmpty
        ? existing.first
        : PigeonConversation(
            profile: contact,
            lastMessage: contact.bio,
            timeLabel: 'Agora',
          );

    if (existing.isEmpty) _conversations.insert(0, conversation);
    _openConversation(conversation);
  }

  void _handleMessageSent(
    PigeonConversation conversation,
    PigeonChatMessage message,
  ) {
    setState(() {
      conversation
        ..lastMessage = message.body
        ..timeLabel = message.timeLabel
        ..unreadCount = 0;
      _conversations.remove(conversation);
      _conversations.insert(0, conversation);
    });
  }

  void _addPost(String content) {
    setState(() {
      _posts.insert(
        0,
        PigeonFeedPost(
          author: _currentUser,
          timeLabel: 'Agora',
          content: content,
          likes: 0,
          comments: 0,
        ),
      );
    });
  }

  Future<void> _openProfile() async {
    final profile = await Navigator.of(context).push<PigeonProfile>(
      MaterialPageRoute<PigeonProfile>(
        builder: (_) => PigeonProfileScreen(profile: _currentUser),
      ),
    );
    if (profile != null && mounted) {
      setState(() => _currentUser = profile);
    }
  }

  void _showContactProfile(PigeonProfile profile) {
    final palette = EnxosTheme.paletteOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.modal,
      showDragHandle: true,
      builder: (_) => PigeonContactProfileSheet(
        profile: profile,
        primary: _primary,
        palette: palette,
      ),
    );
  }

  Future<void> _toggleNotificationSound() async {
    final enabled = !_notificationSoundEnabled;
    setState(() => _notificationSoundEnabled = enabled);
    try {
      await PigeonNotificationSound.setEnabled(enabled);
      if (enabled) await PigeonNotificationSound.playPreview();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível tocar o som agora.')),
        );
      }
    }
  }

  void _onFabTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A inclusão de contatos depende da conexão com o serviço Pigeon.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    final activeChat = _activeChat;

    return EnxosShell(
      module: EnxModule.pigeon,
      onLauncherTap: widget.onLauncherTap,
      extraActionLabel: activeChat == null
          ? 'Bloquear módulo'
          : 'Voltar às mensagens',
      extraActionIcon: activeChat == null
          ? Icons.lock_outline
          : Icons.arrow_back,
      onExtraAction: activeChat == null
          ? () => Navigator.of(context).pop()
          : () => setState(() => _activeChat = null),
      headerActions: [
        IconButton(
          tooltip: _notificationSoundEnabled
              ? 'Som de notificação ativado'
              : 'Som de notificação desativado',
          visualDensity: VisualDensity.compact,
          onPressed: _toggleNotificationSound,
          icon: Icon(
            _notificationSoundEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: palette.textPrimary,
          ),
        ),
        IconButton(
          tooltip: 'Editar perfil',
          visualDensity: VisualDensity.compact,
          onPressed: _openProfile,
          icon: PigeonAvatar(
            profile: _currentUser,
            primary: _primary,
            palette: palette,
            radius: 16,
          ),
        ),
      ],
      child: activeChat != null
          ? ChatDetailView(
              key: ValueKey(activeChat.profile.id),
              conversation: activeChat,
              primary: _primary,
              palette: palette,
              onBack: () => setState(() => _activeChat = null),
              onProfileTap: _showContactProfile,
              onMessageSent: (message) =>
                  _handleMessageSent(activeChat, message),
            )
          : Column(
              children: [
                PigeonTabBar(
                  controller: _tabController,
                  primary: _primary,
                  palette: palette,
                ),
                const SizedBox(height: 8),
                PigeonSearchBar(
                  controller: _searchController,
                  primary: _primary,
                  palette: palette,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    children: [
                      TabBarView(
                        controller: _tabController,
                        children: [
                          MessagesTab(
                            conversations: _visibleConversations,
                            primary: _primary,
                            palette: palette,
                            onConversationTap: _openConversation,
                            onProfileTap: _showContactProfile,
                          ),
                          ContactsTab(
                            contacts: _visibleContacts,
                            primary: _primary,
                            palette: palette,
                            onContactTap: _openContact,
                            onProfileTap: _showContactProfile,
                          ),
                          FeedTab(
                            posts: _visiblePosts,
                            currentUser: _currentUser,
                            primary: _primary,
                            palette: palette,
                            onCreatePost: _addPost,
                          ),
                          PttTab(
                            contacts: _visibleContacts,
                            primary: _primary,
                            palette: palette,
                          ),
                        ],
                      ),
                      if (_tabIndex == 0 || _tabIndex == 1)
                        Positioned(
                          bottom: 12,
                          right: 4,
                          child: PigeonFab(
                            primary: _primary,
                            onPressed: _onFabTap,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
