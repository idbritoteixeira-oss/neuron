import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pigeon_models.dart';

/// Cliente do contrato PHP já utilizado pelo Pigeon Web.
class PigeonApi {
  PigeonApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _ttsUri = Uri.parse(
    'https://tts.enxos.online/s/sdu1730.php',
  );
  static final Uri _apiUri = Uri.parse(
    'https://pigeon.enxos.online/src/orp0141.php',
  );

  final http.Client _client;
  String? _userId;
  String? _dtts;
  String? _sessionCookie;
  bool _disposed = false;

  String? get userId => _userId;

  Future<void> initialize(String pigeonId, {String? sessionCookie}) async {
    final cleanId = pigeonId.trim();
    if (cleanId.isEmpty) {
      throw const PigeonApiException(
        'O ID do módulo Pigeon não foi encontrado.',
      );
    }
    _userId = cleanId;
    _sessionCookie = sessionCookie;
    await _refreshToken();
  }

  Future<void> dispose() async {
    _disposed = true;
    _client.close();
  }

  Future<List<PigeonConversation>> getInbox() async {
    final response = await _get('get_mails');
    final rows = _rows(response);
    final byContact = <String, PigeonConversation>{};
    final unreadByContact = <String, int>{};
    final userId = _requireUserId();

    for (final row in rows) {
      final sender = _string(row['id_pru_from']);
      final recipient = _string(row['id_pru_to']);
      if (sender.isEmpty || recipient.isEmpty) continue;
      final contactId = sender == userId ? recipient : sender;
      if (recipient == userId &&
          (row['viewed_to'] == null ||
              _string(row['viewed_to']).isEmpty ||
              _string(row['viewed_to']) == '0000-00-00 00:00:00')) {
        unreadByContact.update(
          contactId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      if (byContact.containsKey(contactId)) continue;

      final profile = _profileFromRow(
        row,
        id: contactId,
        name: _string(row['name_friend']).isEmpty
            ? contactId
            : _string(row['name_friend']),
      );
      final fromMe = sender == userId;
      final content = _string(row['content']);
      byContact[contactId] =
          PigeonConversation(
              profile: profile,
              lastMessage: fromMe && content.isNotEmpty
                  ? 'Você: $content'
                  : content,
              timeLabel: _timeLabel(row['created_at']),
            )
            ..latestMessageId = _string(row['id_mail'])
            ..latestMessageIsMine = fromMe;
    }

    for (final entry in byContact.entries) {
      entry.value.unreadCount = unreadByContact[entry.key] ?? 0;
    }
    return byContact.values.toList(growable: false);
  }

  Future<List<PigeonProfile>> getContacts() async {
    final response = await _get('get_contacts');
    return _rows(response)
        .map((row) {
          final id = _string(row['id_friend']);
          final updatedAt = _parseDate(row['updated_at']);
          final online =
              updatedAt != null &&
              DateTime.now().difference(updatedAt).inSeconds < 60;
          return PigeonProfile(
            id: id,
            name: _string(row['name_friend']).isEmpty
                ? id
                : _string(row['name_friend']),
            avatarUrl: _assetUrl(_string(row['prof_photo'])),
            verification: _verification(row['prof_verified']),
            isOnline: online,
            lastSeen: _presenceLabel(updatedAt),
            isBlocked: _asInt(row['blocked']) == 1,
          );
        })
        .where((profile) => profile.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<PigeonProfile> getOwnProfile() async {
    final response = await _get('get_profile');
    final data = _map(response['data']);
    final id = _requireUserId();
    return PigeonProfile(
      id: id,
      name: id,
      bio: _string(data['prof_bio']),
      avatarUrl: _assetUrl(_string(data['prof_photo'])),
      verification: _verification(data['prof_verified']),
      isOnline: true,
    );
  }

  Future<PigeonProfile> getContactProfile(PigeonProfile contact) async {
    final response = await _get(
      'get_profile_full',
      query: {'id_friend': contact.id},
    );
    final profile = _map(response['profile']);
    final name = _string(response['custom_name']);
    return PigeonProfile(
      id: contact.id,
      name: name.isEmpty ? contact.id : name,
      bio: _string(profile['prof_bio']),
      avatarUrl: _assetUrl(_string(profile['prof_photo'])) ?? contact.avatarUrl,
      verification: _verification(profile['prof_verified']),
      isOnline: contact.isOnline,
      lastSeen: contact.lastSeen,
    );
  }

  Future<PigeonProfile> updateProfile({
    required String bio,
    String? photoDataUri,
  }) async {
    await _post('update_profile', {'bio': bio, 'photo': photoDataUri});
    return getOwnProfile();
  }

  Future<void> addContact({required String id, String name = ''}) async {
    await _post('add_contact', {
      'id_friend': id.trim(),
      'name_friend': name.trim(),
    });
  }

  Future<void> renameContact({required String id, required String name}) async {
    await _post('rename_friend', {'id_friend': id, 'new_name': name.trim()});
  }

  Future<void> deleteConversation(String contactId) async {
    await _post('delete_chat', {'id_friend': contactId});
  }

  Future<List<PigeonChatMessage>> getMessages(String contactId) async {
    final response = await _get('get_mails', query: {'id_friend': contactId});
    final userId = _requireUserId();
    return _rows(response)
        .map((row) {
          final senderId = _string(row['id_pru_from']);
          final viewedTo = _string(row['viewed_to']);
          return PigeonChatMessage(
            id: _string(row['id_mail']),
            body: _string(row['content']),
            isMine: senderId == userId,
            timeLabel: _timeLabel(row['created_at']),
            isRead:
                senderId == userId &&
                viewedTo.isNotEmpty &&
                viewedTo != '0000-00-00 00:00:00',
          );
        })
        .toList(growable: false);
  }

  Future<void> sendMessage({
    required String to,
    required String content,
  }) async {
    await _post('send_mail', {'id_to': to, 'content': content.trim()});
  }

  Future<List<PigeonFeedPost>> getFeed() async {
    final response = await _get('get_feed');
    return _rows(response)
        .map((row) {
          final authorId = _string(row['id_pru_author']);
          return PigeonFeedPost(
            postId: _asInt(row['post_id']),
            author: PigeonProfile(
              id: authorId,
              name: _string(row['author_name']).isEmpty
                  ? authorId
                  : _string(row['author_name']),
              avatarUrl: _assetUrl(_string(row['prof_photo'])),
              verification: _verification(row['prof_verified']),
            ),
            timeLabel: _relativeTime(row['created_at']),
            content: _string(row['content']),
            likes: _asInt(row['likes_count']),
            comments: _asInt(row['comments_count']),
            imageUrl: _assetUrl(_string(row['media_url'])),
            isLiked: _asInt(row['liked_by_me']) > 0,
          );
        })
        .toList(growable: false);
  }

  Future<void> createPost(String content) async {
    await _post('create_post', {'content': content.trim()});
  }

  Future<void> toggleLike(int postId) async {
    await _post('toggle_like', {'id_post': postId});
  }

  Future<void> editPost({required int postId, required String content}) async {
    await _post('edit_post', {'id_post': postId, 'content': content.trim()});
  }

  Future<void> deletePost(int postId) async {
    await _post('delete_post', {'id_post': postId});
  }

  Future<void> reportPost({required int postId, required String reason}) async {
    await _post('report_post', {'id_post': postId, 'reason': reason.trim()});
  }

  Future<void> sendBeep({
    required String recipientId,
    required String filePath,
  }) async {
    Future<http.Response> send() async {
      final request =
          http.MultipartRequest('POST', await _authorizedUri('send_beep'))
            ..fields['id_to'] = recipientId
            ..files.add(
              await http.MultipartFile.fromPath(
                'audio_file',
                filePath,
                filename: 'pigeon-ptt.m4a',
              ),
            );
      final cookie = _sessionCookie;
      if (cookie != null && cookie.isNotEmpty) {
        request.headers['Cookie'] = cookie;
      }
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamed);
    }

    var response = await send();
    if (response.statusCode == 403) {
      await _refreshToken();
      response = await send();
    }
    var decoded = _decodeResponse(response);
    if (decoded['code'] == 'PRU_403') {
      await _refreshToken();
      response = await send();
      decoded = _decodeResponse(response);
    }
    if (decoded['status'] == 'error') {
      throw PigeonApiException(
        _string(decoded['message']).isEmpty
            ? 'O serviço Pigeon recusou o envio do áudio.'
            : _string(decoded['message']),
      );
    }
  }

  Future<PigeonBeep?> getNextBeep() async {
    final response = await _get('get_beeps');
    final data = response['data'];
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final id = _asInt(map['id']);
    final url = _assetUrl(_string(map['file_url']));
    if (id <= 0 || url == null) return null;
    return PigeonBeep(id: id, fileUrl: url);
  }

  Future<void> deleteBeep(int beepId) async {
    await _post('delete_beep', {}, query: {'id_beep': '$beepId'});
  }

  Future<Uri> _authorizedUri(
    String action, {
    Map<String, String> query = const {},
  }) async {
    if (_dtts == null) await _refreshToken();
    return _apiUri.replace(
      queryParameters: {
        'action': action,
        'id_pru': _requireUserId(),
        'dtts': _dtts!,
        ...query,
      },
    );
  }

  Future<Map<String, dynamic>> _get(
    String action, {
    Map<String, String> query = const {},
  }) async {
    return _authorizedRequest(
      action,
      query: query,
      request: (uri) => _client
          .get(uri, headers: _requestHeaders)
          .timeout(const Duration(seconds: 20)),
    );
  }

  Future<Map<String, dynamic>> _post(
    String action,
    Map<String, dynamic> body, {
    Map<String, String> query = const {},
  }) async {
    return _authorizedRequest(
      action,
      query: query,
      request: (uri) => _client
          .post(
            uri,
            headers: {..._requestHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20)),
    );
  }

  Future<Map<String, dynamic>> _authorizedRequest(
    String action, {
    required Future<http.Response> Function(Uri uri) request,
    Map<String, String> query = const {},
  }) async {
    var response = await request(await _authorizedUri(action, query: query));
    if (response.statusCode == 403) {
      await _refreshToken();
      response = await request(await _authorizedUri(action, query: query));
    }
    var decoded = _decodeResponse(response);
    if (decoded['code'] == 'PRU_403') {
      await _refreshToken();
      response = await request(await _authorizedUri(action, query: query));
      decoded = _decodeResponse(response);
    }
    if (decoded['status'] == 'error') {
      throw PigeonApiException(
        _string(decoded['message']).isEmpty
            ? 'O serviço Pigeon recusou a solicitação.'
            : _string(decoded['message']),
      );
    }
    return decoded;
  }

  Future<void> _refreshToken() async {
    final id = _requireUserId();
    final uri = _ttsUri.replace(
      queryParameters: {'id_pub': id, 'origin': 'pru'},
    );
    final response = await _client
        .get(uri, headers: _requestHeaders)
        .timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    final keys = data['chaves'];
    if (data['success'] == false ||
        data['session_expired'] == true ||
        keys is! List ||
        keys.isEmpty ||
        keys.first is! Map) {
      throw PigeonApiException(
        _string(data['message']).isEmpty
            ? 'Não foi possível abrir uma sessão segura no Pigeon.'
            : _string(data['message']),
      );
    }
    final token = _string(Map<String, dynamic>.from(keys.first)['token']);
    if (token.isEmpty) {
      throw const PigeonApiException(
        'O serviço de autenticação não retornou o token DTTS.',
      );
    }
    _dtts = token;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PigeonApiException(
        'Falha HTTP ${response.statusCode} ao comunicar com o Pigeon.',
      );
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Resposta JSON não é um objeto.');
      }
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const PigeonApiException(
        'O servidor Pigeon retornou uma resposta inválida.',
      );
    }
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  PigeonProfile _profileFromRow(
    Map<String, dynamic> row, {
    required String id,
    required String name,
  }) {
    return PigeonProfile(
      id: id,
      name: name,
      avatarUrl: _assetUrl(_string(row['prof_photo'])),
      verification: _verification(row['prof_verified']),
    );
  }

  PigeonVerification _verification(dynamic value) => switch (_asInt(value)) {
    1 => PigeonVerification.blue,
    2 => PigeonVerification.system,
    _ => PigeonVerification.none,
  };

  String? _assetUrl(String value) {
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme ?? false) return value;
    if (value.startsWith('//')) return 'https:$value';
    return 'https://pigeon.enxos.online/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));
  }

  String _presenceLabel(DateTime? lastSeen) {
    if (lastSeen == null) return 'Status indisponível';
    final seconds = DateTime.now().difference(lastSeen).inSeconds;
    if (seconds < 60) return 'Online';
    if (seconds < 3600) return 'há ${seconds ~/ 60} min';
    if (seconds < 86400) return 'há ${seconds ~/ 3600}h';
    return 'há ${seconds ~/ 86400}d';
  }

  String _timeLabel(dynamic value) {
    final raw = _string(value);
    if (raw.length >= 5 && RegExp(r'\d{2}:\d{2}$').hasMatch(raw)) {
      return raw.substring(raw.length - 5);
    }
    return raw;
  }

  String _relativeTime(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return _timeLabel(value);
    final difference = DateTime.now().difference(date);
    if (difference.inSeconds < 60) return 'agora mesmo';
    if (difference.inMinutes < 60) return 'há ${difference.inMinutes}m';
    if (difference.inHours < 24) return 'há ${difference.inHours}h';
    return 'há ${difference.inDays}d';
  }

  String _requireUserId() {
    final id = _userId;
    if (id == null || id.isEmpty || _disposed) {
      throw const PigeonApiException('A sessão Pigeon não está ativa.');
    }
    return id;
  }

  Map<String, String> get _requestHeaders {
    final cookie = _sessionCookie;
    if (cookie == null || cookie.isEmpty) return {};
    return {'Cookie': cookie};
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';
  static int _asInt(dynamic value) => int.tryParse(_string(value)) ?? 0;
  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
}

class PigeonApiException implements Exception {
  const PigeonApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
