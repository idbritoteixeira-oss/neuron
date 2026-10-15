import 'package:flutter/material.dart';

import '../../core/enxos/enx_module.dart';
import '../../core/enxos/enxos_shell.dart';
import '../../core/enxos/enxos_theme.dart';
import 'chat_detail_view.dart';
import 'models/pigeon_demo_data.dart';
import 'models/pigeon_models.dart';
import 'tabs/contacts_tab.dart';
import 'tabs/feed_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/ptt_tab.dart';
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

  int _tabIndex = 0;
  String _searchQuery = '';
  PigeonConversation? _activeChat;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(_handleTabChange);
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
          author: PigeonDemoData.currentUser,
          timeLabel: 'Agora',
          content: content,
          likes: 0,
          comments: 0,
        ),
      );
    });
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
      child: activeChat != null
          ? ChatDetailView(
              key: ValueKey(activeChat.profile.id),
              conversation: activeChat,
              primary: _primary,
              palette: palette,
              onBack: () => setState(() => _activeChat = null),
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
                          ),
                          ContactsTab(
                            contacts: _visibleContacts,
                            primary: _primary,
                            palette: palette,
                            onContactTap: _openContact,
                          ),
                          FeedTab(
                            posts: _visiblePosts,
                            currentUser: PigeonDemoData.currentUser,
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
