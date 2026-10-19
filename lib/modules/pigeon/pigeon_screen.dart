import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enxos/enx_module.dart';
import '../../core/enxos/enxos_shell.dart';
import '../../core/enxos/enxos_theme.dart';
import '../../core/enxos/module_state.dart';
import 'chat_detail_view.dart';
import 'dialogs/pigeon_add_contact_dialog.dart';
import 'models/pigeon_models.dart';
import 'profile/pigeon_contact_profile_sheet.dart';
import 'profile/pigeon_profile_screen.dart';
import 'services/pigeon_api.dart';
import 'services/pigeon_audio_platform.dart';
import 'services/pigeon_notification_sound.dart';
import 'tabs/contacts_tab.dart';
import 'tabs/feed_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/ptt_tab.dart';
import 'widgets/pigeon_avatar.dart';
import 'widgets/pigeon_fab.dart';
import 'widgets/pigeon_search_bar.dart';
import 'widgets/pigeon_tab_bar.dart';

/// Controlador das abas e das operações remotas do Pigeon.
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
  final List<PigeonConversation> _conversations = [];
  final List<PigeonProfile> _contacts = [];
  final List<PigeonFeedPost> _posts = [];

  PigeonApi? _api;
  PigeonProfile? _currentUser;
  PigeonConversation? _activeChat;
  Timer? _refreshTimer;
  int _tabIndex = 0;
  String _searchQuery = '';
  String? _loadError;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoadedData = false;
  bool _notificationSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
      _loadSoundPreference();
    });
  }

  Future<void> _initialize() async {
    _refreshTimer?.cancel();
    final moduleState = context.read<ModuleState>();
    final moduleId = moduleState.moduleIdFor(EnxModule.pigeon);
    if (moduleId == null || moduleId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError =
              'Entre novamente no módulo Pigeon para validar a sessão.';
        });
      }
      return;
    }

    final previousApi = _api;
    if (previousApi != null) await previousApi.dispose();
    final api = PigeonApi();
    _api = api;
    try {
      await api.initialize(
        moduleId,
        sessionCookie: moduleState.sessionCookieFor(EnxModule.pigeon),
      );
      await _loadRemoteData();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _loadRemoteData(),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSoundPreference() async {
    try {
      final enabled = await PigeonNotificationSound.isEnabled();
      if (mounted) setState(() => _notificationSoundEnabled = enabled);
    } catch (_) {
      // A preferência de som não impede o acesso aos dados do servidor.
    }
  }

  Future<void> _loadRemoteData() async {
    final api = _api;
    if (api == null || _isRefreshing) return;
    _isRefreshing = true;
    try {
      final results = await Future.wait<Object>([
        api.getInbox(),
        api.getContacts(),
        api.getFeed(),
        api.getOwnProfile(),
      ]);
      if (!mounted) return;
      final hadLoadedData = _hasLoadedData;
      final previousMessageIds = {
        for (final conversation in _conversations)
          conversation.profile.id: conversation.latestMessageId,
      };
      final refreshedConversations = results[0] as List<PigeonConversation>;
      final refreshedPosts = results[2] as List<PigeonFeedPost>;
      final hasNewIncoming =
          hadLoadedData &&
          refreshedConversations.any(
            (conversation) =>
                !conversation.latestMessageIsMine &&
                conversation.latestMessageId != null &&
                previousMessageIds[conversation.profile.id] !=
                    conversation.latestMessageId,
          );
      final previousTopPostId = _posts.isEmpty ? null : _posts.first.postId;
      final hasNewPost =
          hadLoadedData &&
          refreshedPosts.isNotEmpty &&
          previousTopPostId != null &&
          refreshedPosts.first.postId != previousTopPostId &&
          refreshedPosts.first.author.id != _currentUser?.id;
      setState(() {
        _conversations
          ..clear()
          ..addAll(refreshedConversations);
        _contacts
          ..clear()
          ..addAll(results[1] as List<PigeonProfile>);
        _posts
          ..clear()
          ..addAll(refreshedPosts);
        _currentUser = results[3] as PigeonProfile;
        _loadError = null;
        _isLoading = false;
        _hasLoadedData = true;
      });
      if ((hasNewIncoming || hasNewPost) && _notificationSoundEnabled) {
        try {
          await PigeonNotificationSound.playPreview();
        } catch (_) {
          // A falha no som não interrompe a sincronização das mensagens.
        }
      }
      final active = _activeChat;
      if (active != null) await _loadChatMessages(active);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!_hasLoadedData) _loadError = error.toString();
      });
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadChatMessages(PigeonConversation conversation) async {
    final api = _api;
    if (api == null) return;
    final messages = await api.getMessages(conversation.profile.id);
    if (!mounted) return;
    setState(() {
      conversation.messages
        ..clear()
        ..addAll(messages);
      conversation.unreadCount = 0;
      if (messages.isNotEmpty) {
        final latest = messages.last;
        conversation
          ..lastMessage = latest.isMine ? 'Você: ${latest.body}' : latest.body
          ..timeLabel = latest.timeLabel
          ..latestMessageId = latest.id
          ..latestMessageIsMine = latest.isMine;
      } else {
        conversation
          ..lastMessage = ''
          ..timeLabel = ''
          ..latestMessageId = null
          ..latestMessageIsMine = false;
      }
    });
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    await _initialize();
  }

  void _handleTabChange() {
    if (mounted && _tabIndex != _tabController.index) {
      setState(() => _tabIndex = _tabController.index);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    _searchController.dispose();
    final api = _api;
    if (api != null) unawaited(api.dispose());
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

  Future<void> _openConversation(PigeonConversation conversation) async {
    setState(() {
      _activeChat = conversation;
    });
    try {
      await _loadChatMessages(conversation);
    } catch (error) {
      _showMessage('Não foi possível carregar as mensagens: $error');
    }
  }

  void _openContact(PigeonProfile contact) {
    final existing = _conversations.where(
      (conversation) => conversation.profile.id == contact.id,
    );
    final conversation = existing.isNotEmpty
        ? existing.first
        : PigeonConversation(profile: contact, lastMessage: '', timeLabel: '');
    if (existing.isEmpty) _conversations.insert(0, conversation);
    _openConversation(conversation);
  }

  Future<void> _sendMessage(String body) async {
    final api = _api;
    final conversation = _activeChat;
    if (api == null || conversation == null) {
      throw const PigeonApiException('A conversa não está disponível.');
    }
    await api.sendMessage(to: conversation.profile.id, content: body);
    if (!mounted) return;
    final now = DateTime.now();
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      conversation.messages.add(
        PigeonChatMessage(body: body, isMine: true, timeLabel: timeLabel),
      );
      conversation
        ..lastMessage = 'Você: $body'
        ..timeLabel = timeLabel
        ..latestMessageId = null
        ..latestMessageIsMine = true;
      _conversations.remove(conversation);
      _conversations.insert(0, conversation);
    });
    unawaited(_refreshSentMessages(conversation));
  }

  Future<void> _refreshSentMessages(PigeonConversation conversation) async {
    try {
      await _loadChatMessages(conversation);
    } catch (_) {
      _showMessage(
        'Mensagem enviada; não foi possível atualizar o histórico agora.',
      );
    }
  }

  Future<void> _renameContact(String newName) async {
    final api = _api;
    final conversation = _activeChat;
    if (api == null || conversation == null) return;
    await api.renameContact(id: conversation.profile.id, name: newName);
    if (!mounted) return;
    final renamed = _copyProfile(conversation.profile, name: newName);
    final replacement = PigeonConversation(
      profile: renamed,
      lastMessage: conversation.lastMessage,
      timeLabel: conversation.timeLabel,
      unreadCount: conversation.unreadCount,
      latestMessageId: conversation.latestMessageId,
      latestMessageIsMine: conversation.latestMessageIsMine,
      messages: conversation.messages,
    );
    setState(() {
      final contactIndex = _contacts.indexWhere(
        (contact) => contact.id == renamed.id,
      );
      if (contactIndex >= 0) _contacts[contactIndex] = renamed;
      final index = _conversations.indexOf(conversation);
      if (index >= 0) _conversations[index] = replacement;
      _activeChat = replacement;
    });
  }

  Future<void> _deleteConversation() async {
    final api = _api;
    final conversation = _activeChat;
    if (api == null || conversation == null) return;
    await api.deleteConversation(conversation.profile.id);
    if (!mounted) return;
    setState(() => _activeChat = null);
    await _loadRemoteData();
  }

  Future<void> _showContactProfile(PigeonProfile profile) async {
    final api = _api;
    if (api == null) return;
    try {
      final remoteProfile = await api.getContactProfile(profile);
      if (!mounted) return;
      final palette = EnxosTheme.paletteOf(context);
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: palette.modal,
        showDragHandle: true,
        builder: (_) => PigeonContactProfileSheet(
          profile: remoteProfile,
          primary: _primary,
          palette: palette,
        ),
      );
    } catch (error) {
      _showMessage('Não foi possível carregar o perfil: $error');
    }
  }

  Future<void> _openProfile() async {
    final api = _api;
    final profile = _currentUser;
    if (api == null || profile == null) return;
    final updated = await Navigator.of(context).push<PigeonProfile>(
      MaterialPageRoute<PigeonProfile>(
        builder: (_) => PigeonProfileScreen(profile: profile, api: api),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _currentUser = updated);
    }
  }

  Future<void> _toggleNotificationSound() async {
    final enabled = !_notificationSoundEnabled;
    setState(() => _notificationSoundEnabled = enabled);
    try {
      await PigeonNotificationSound.setEnabled(enabled);
      if (enabled) await PigeonNotificationSound.playPreview();
    } catch (_) {
      if (!mounted) return;
      setState(() => _notificationSoundEnabled = !enabled);
      _showMessage('Não foi possível alterar o som de notificação.');
    }
  }

  Future<void> _addContact() async {
    final palette = EnxosTheme.paletteOf(context);
    final details = await showDialog<({String id, String name})>(
      context: context,
      builder: (_) => PigeonAddContactDialog(palette: palette),
    );
    if (details == null) return;
    try {
      await _api!.addContact(id: details.id, name: details.name);
      await _loadRemoteData();
      _showMessage('Contato adicionado.');
    } catch (error) {
      _showMessage('Não foi possível adicionar o contato: $error');
    }
  }

  Future<void> _createPost(String content) async {
    final api = _api;
    if (api == null) return;
    try {
      await api.createPost(content);
      final posts = await api.getFeed();
      if (mounted)
        setState(() {
          _posts
            ..clear()
            ..addAll(posts);
        });
    } catch (error) {
      _showMessage('Não foi possível publicar: $error');
    }
  }

  Future<void> _toggleLike(PigeonFeedPost post) async {
    final api = _api;
    final postId = post.postId;
    if (api == null || postId == null) return;
    try {
      await api.toggleLike(postId);
      final posts = await api.getFeed();
      if (mounted)
        setState(() {
          _posts
            ..clear()
            ..addAll(posts);
        });
    } catch (error) {
      _showMessage('Não foi possível atualizar a curtida: $error');
    }
  }

  Future<void> _editPost(PigeonFeedPost post, String content) async {
    final api = _api;
    final postId = post.postId;
    if (api == null || postId == null) {
      throw const PigeonApiException('A publicação não está disponível.');
    }
    await api.editPost(postId: postId, content: content);
    final posts = await api.getFeed();
    if (mounted)
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
      });
  }

  Future<void> _deletePost(PigeonFeedPost post) async {
    final api = _api;
    final postId = post.postId;
    if (api == null || postId == null) {
      throw const PigeonApiException('A publicação não está disponível.');
    }
    await api.deletePost(postId);
    final posts = await api.getFeed();
    if (mounted)
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
      });
  }

  Future<void> _reportPost(PigeonFeedPost post, String reason) async {
    final api = _api;
    final postId = post.postId;
    if (api == null || postId == null) {
      throw const PigeonApiException('A publicação não está disponível.');
    }
    await api.reportPost(postId: postId, reason: reason);
    _showMessage('Denúncia enviada.');
  }

  Future<void> _sendAudio(PigeonProfile contact, String path) async {
    final api = _api;
    if (api == null) throw const PigeonApiException('Sessão Pigeon encerrada.');
    await api.sendBeep(recipientId: contact.id, filePath: path);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  PigeonProfile _copyProfile(PigeonProfile profile, {String? name}) =>
      PigeonProfile(
        id: profile.id,
        name: name ?? profile.name,
        bio: profile.bio,
        isOnline: profile.isOnline,
        verification: profile.verification,
        avatarUrl: profile.avatarUrl,
        isBlocked: profile.isBlocked,
        lastSeen: profile.lastSeen,
      );

  Widget _loadingOrError(EnxosPalette palette) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primary));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: palette.textMuted, size: 34),
            const SizedBox(height: 12),
            Text(
              _loadError ?? 'Não foi possível carregar o Pigeon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _retryInitialization,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    final activeChat = _activeChat;
    final currentUser = _currentUser;

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
        if (currentUser != null)
          IconButton(
            tooltip: 'Editar perfil',
            visualDensity: VisualDensity.compact,
            onPressed: _openProfile,
            icon: PigeonAvatar(
              profile: currentUser,
              primary: _primary,
              palette: palette,
              radius: 16,
            ),
          ),
      ],
      child: !_hasLoadedData
          ? _loadingOrError(palette)
          : activeChat != null
          ? ChatDetailView(
              key: ValueKey(activeChat.profile.id),
              conversation: activeChat,
              primary: _primary,
              palette: palette,
              onBack: () => setState(() => _activeChat = null),
              onProfileTap: _showContactProfile,
              onSendMessage: _sendMessage,
              onRenameContact: _renameContact,
              onDeleteConversation: _deleteConversation,
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
                            currentUser: currentUser!,
                            primary: _primary,
                            palette: palette,
                            onCreatePost: _createPost,
                            onLikePost: _toggleLike,
                            onContactAuthor: _openContact,
                            onEditPost: _editPost,
                            onDeletePost: _deletePost,
                            onReportPost: _reportPost,
                          ),
                          PttTab(
                            contacts: _visibleContacts,
                            primary: _primary,
                            palette: palette,
                            active: _tabIndex == 3,
                            onSendAudio: _sendAudio,
                            onGetNextBeep: () => _api!.getNextBeep(),
                            onPlayBeep: PigeonAudioPlatform.play,
                            onDeleteBeep: (id) => _api!.deleteBeep(id),
                          ),
                        ],
                      ),
                      if (_tabIndex == 0 || _tabIndex == 1)
                        Positioned(
                          bottom: 12,
                          right: 4,
                          child: PigeonFab(
                            primary: _primary,
                            onPressed: _addContact,
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
