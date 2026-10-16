import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';
import '../services/pigeon_audio_platform.dart';
import '../widgets/pigeon_avatar.dart';
import '../widgets/verified_badge.dart';

class PttTab extends StatefulWidget {
  const PttTab({
    required this.contacts,
    required this.primary,
    required this.palette,
    required this.active,
    required this.onSendAudio,
    required this.onGetNextBeep,
    required this.onPlayBeep,
    required this.onDeleteBeep,
    super.key,
  });

  final List<PigeonProfile> contacts;
  final Color primary;
  final EnxosPalette palette;
  final bool active;
  final Future<void> Function(PigeonProfile contact, String filePath)
  onSendAudio;
  final Future<PigeonBeep?> Function() onGetNextBeep;
  final Future<void> Function(String url) onPlayBeep;
  final Future<void> Function(int beepId) onDeleteBeep;

  @override
  State<PttTab> createState() => _PttTabState();
}

class _PttTabState extends State<PttTab> {
  static const _maximumTalkDuration = Duration(seconds: 10);
  PigeonProfile? _selectedContact;
  Timer? _talkLimit;
  Timer? _beepPolling;
  bool _isTransmitting = false;
  bool _recording = false;
  bool _startingRecording = false;
  bool _stopAfterStart = false;
  bool _pollingBeep = false;
  String _status = 'Selecione um contato e segure para falar';

  @override
  void initState() {
    super.initState();
    if (widget.active) _startPolling();
  }

  @override
  void didUpdateWidget(covariant PttTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _startPolling();
    } else if (oldWidget.active && !widget.active) {
      _stopPolling();
    }
  }

  @override
  void dispose() {
    _talkLimit?.cancel();
    _stopPolling();
    if (_recording) {
      unawaited(_discardActiveRecording());
    }
    unawaited(PigeonAudioPlatform.stopPlayback());
    super.dispose();
  }

  Future<void> _discardActiveRecording() async {
    try {
      final path = await PigeonAudioPlatform.stopRecording();
      await File(path).delete();
    } catch (_) {
      // A tela pode ser removida no meio de uma gravação curta.
    }
  }

  void _selectContact(PigeonProfile contact) {
    setState(() {
      _selectedContact = contact;
      _status = 'Pronto. Segure para falar (máx. 10s)';
    });
  }

  Future<void> _startTalking() async {
    if (_selectedContact == null) {
      setState(() => _status = 'Selecione um contato da lista primeiro.');
      return;
    }
    if (_isTransmitting || _startingRecording) return;
    _talkLimit?.cancel();
    setState(() {
      _isTransmitting = true;
      _startingRecording = true;
      _stopAfterStart = false;
      _status = 'Solicitando acesso ao microfone...';
    });
    try {
      await PigeonAudioPlatform.startRecording();
      _startingRecording = false;
      _recording = true;
      if (!mounted) {
        await PigeonAudioPlatform.stopRecording();
        return;
      }
      if (_stopAfterStart || !_isTransmitting) {
        await _finishRecording();
        return;
      }
      setState(
        () => _status = 'Transmitindo para ${_selectedContact!.name}...',
      );
      _talkLimit = Timer(_maximumTalkDuration, _stopTalking);
    } catch (error) {
      _startingRecording = false;
      if (!mounted) return;
      setState(() {
        _isTransmitting = false;
        _status = error.toString().contains('microphone_permission_denied')
            ? 'Permita o acesso ao microfone para falar.'
            : 'Não foi possível iniciar o PTT.';
      });
    }
  }

  Future<void> _stopTalking() async {
    _talkLimit?.cancel();
    if (!_isTransmitting && !_startingRecording && !_recording) return;
    if (mounted) setState(() => _isTransmitting = false);
    if (_startingRecording) {
      _stopAfterStart = true;
      return;
    }
    await _finishRecording();
  }

  Future<void> _finishRecording() async {
    final contact = _selectedContact;
    if (!_recording || contact == null) return;
    _recording = false;
    if (mounted) setState(() => _status = 'Enviando áudio...');
    try {
      final path = await PigeonAudioPlatform.stopRecording();
      await widget.onSendAudio(contact, path);
      await File(path).delete().catchError((_) => File(path));
      if (mounted) {
        setState(() => _status = 'PTT enviado. Segure para falar novamente.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Falha ao enviar o áudio: $error');
      }
    } finally {
      if (mounted) setState(() => _isTransmitting = false);
    }
  }

  void _startPolling() {
    _beepPolling?.cancel();
    _beepPolling = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollReceivedAudio(),
    );
    _pollReceivedAudio();
  }

  void _stopPolling() {
    _beepPolling?.cancel();
    _beepPolling = null;
  }

  Future<void> _pollReceivedAudio() async {
    if (!widget.active || _pollingBeep || _isTransmitting || !mounted) return;
    _pollingBeep = true;
    try {
      final beep = await widget.onGetNextBeep();
      if (beep == null || !mounted) return;
      setState(() => _status = 'Reproduzindo áudio recebido...');
      await widget.onPlayBeep(beep.fileUrl);
      await widget.onDeleteBeep(beep.id);
      if (mounted) setState(() => _status = 'Áudio recebido reproduzido.');
    } catch (_) {
      if (mounted)
        setState(() => _status = 'Não foi possível reproduzir o PTT.');
    } finally {
      _pollingBeep = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedContact;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
      children: [
        if (selected != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.palette.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.palette.border),
            ),
            child: Row(
              children: [
                PigeonAvatar(
                  profile: selected,
                  primary: widget.primary,
                  palette: widget.palette,
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          selected.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      VerifiedBadge(verification: selected.verification),
                    ],
                  ),
                ),
                Text(
                  selected.id,
                  style: TextStyle(
                    color: widget.palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        for (final contact in widget.contacts)
          _PttContactTile(
            contact: contact,
            primary: widget.primary,
            palette: widget.palette,
            selected: contact.id == selected?.id,
            onTap: () => _selectContact(contact),
          ),
        if (widget.contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Nenhum contato encontrado.',
                style: TextStyle(color: widget.palette.textSecondary),
              ),
            ),
          ),
        const SizedBox(height: 22),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: widget.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isTransmitting
                      ? 'BOTÃO PTT PRESSIONADO'
                      : 'CANAL GLOBAL #01',
                  style: TextStyle(
                    color: widget.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onLongPressStart: (_) => _startTalking(),
                onLongPressEnd: (_) => _stopTalking(),
                onLongPressCancel: _stopTalking,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _isTransmitting ? 106 : 90,
                  height: _isTransmitting ? 106 : 90,
                  decoration: BoxDecoration(
                    color: _isTransmitting
                        ? const Color(0xFFEF4444)
                        : widget.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    boxShadow: _isTransmitting
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isTransmitting ? Icons.mic : Icons.mic_none,
                    size: 42,
                    color: _isTransmitting ? Colors.white : widget.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.palette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pressione e segure para falar · máximo 10 segundos',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.palette.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                widget.active
                    ? 'Áudios recebidos são verificados automaticamente.'
                    : 'Abra a aba PTT para receber áudios.',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.palette.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PttContactTile extends StatelessWidget {
  const _PttContactTile({
    required this.contact,
    required this.primary,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final PigeonProfile contact;
  final Color primary;
  final EnxosPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selected ? primary.withValues(alpha: 0.08) : palette.card,
        border: Border.all(color: selected ? primary : palette.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: ListTile(
        dense: true,
        leading: PigeonAvatar(
          profile: contact,
          primary: primary,
          palette: palette,
          radius: 19,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                contact.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            VerifiedBadge(verification: contact.verification),
          ],
        ),
        subtitle: Text(
          'ID: ${contact.id}',
          style: TextStyle(color: palette.textSecondary, fontSize: 11),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: primary)
            : Icon(Icons.radio_button_unchecked, color: palette.textMuted),
        onTap: onTap,
      ),
    );
  }
}
