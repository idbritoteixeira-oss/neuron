import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';
import '../services/pigeon_api.dart';
import '../widgets/verified_badge.dart';

class PigeonProfileScreen extends StatefulWidget {
  const PigeonProfileScreen({
    required this.profile,
    required this.api,
    super.key,
  });

  final PigeonProfile profile;
  final PigeonApi api;

  @override
  State<PigeonProfileScreen> createState() => _PigeonProfileScreenState();
}

class _PigeonProfileScreenState extends State<PigeonProfileScreen> {
  late final TextEditingController _bioController;
  late final TextEditingController _photoController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.profile.bio);
    _photoController = TextEditingController(
      text: widget.profile.avatarUrl ?? '',
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _photoController.dispose();
    _photoFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final photoUrl = _photoController.text.trim();
    if (photoUrl.isNotEmpty) {
      final uri = Uri.tryParse(photoUrl);
      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        setState(
          () => _error = 'A foto precisa usar um endereço HTTP ou HTTPS.',
        );
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? photoDataUri;
      if (photoUrl.isNotEmpty && photoUrl != widget.profile.avatarUrl) {
        photoDataUri = await _downloadPhoto(photoUrl);
      }
      final updated = await widget.api.updateProfile(
        bio: _bioController.text.trim(),
        photoDataUri: photoDataUri,
      );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não foi possível atualizar o perfil no servidor.';
        });
      }
    }
  }

  Future<String> _downloadPhoto(String photoUrl) async {
    final response = await http
        .get(Uri.parse(photoUrl))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const PigeonApiException(
        'Não foi possível baixar a imagem informada.',
      );
    }
    if (response.bodyBytes.length > 5 * 1024 * 1024) {
      throw const PigeonApiException('A imagem deve ter no máximo 5 MB.');
    }
    final contentType = response.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    const supportedTypes = {
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
    };
    if (contentType == null || !supportedTypes.contains(contentType)) {
      throw const PigeonApiException('Use uma imagem JPEG, PNG, GIF ou WebP.');
    }
    return 'data:$contentType;base64,${base64Encode(response.bodyBytes)}';
  }

  Widget _avatar(EnxosPalette palette) {
    final photoUrl = _photoController.text.trim();
    return CircleAvatar(
      radius: 48,
      backgroundColor: palette.borderAvatar,
      child: ClipOval(
        child: photoUrl.startsWith('http')
            ? Image.network(
                photoUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialAvatar(palette),
              )
            : _initialAvatar(palette),
      ),
    );
  }

  Widget _initialAvatar(EnxosPalette palette) => Container(
    width: 96,
    height: 96,
    alignment: Alignment.center,
    color: palette.borderAvatar,
    child: Text(
      widget.profile.initial,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);

    return Scaffold(
      backgroundColor: palette.page,
      appBar: AppBar(
        backgroundColor: palette.card,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        title: Text(
          'Editar perfil',
          style: TextStyle(color: palette.textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Center(child: _avatar(palette)),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    FocusScope.of(context).requestFocus(_photoFocusNode),
                child: const Text('Alterar foto por URL'),
              ),
            ),
            Center(
              child: Text(
                'Nome de perfil: ${widget.profile.id}',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.profile.id,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  VerifiedBadge(
                    verification: widget.profile.verification,
                    size: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              focusNode: _photoFocusNode,
              controller: _photoController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL da foto',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              minLines: 3,
              maxLines: 5,
              maxLength: 240,
              decoration: InputDecoration(
                labelText: 'Biografia',
                hintText: 'Escreva aqui a sua biografia...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: palette.input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1D9BF0),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1D9BF0),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF0C85D0),
                    width: 2,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando...' : 'Guardar perfil'),
            ),
            const SizedBox(height: 12),
            Text(
              'Biografia e foto são atualizadas no servidor Pigeon. O nome público é o seu ID.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  final FocusNode _photoFocusNode = FocusNode();
}
