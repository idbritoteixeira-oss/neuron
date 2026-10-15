import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';
import '../widgets/pigeon_avatar.dart';
import '../widgets/verified_badge.dart';

class PttTab extends StatefulWidget {
  const PttTab({
    required this.contacts,
    required this.primary,
    required this.palette,
    super.key,
  });

  final List<PigeonProfile> contacts;
  final Color primary;
  final EnxosPalette palette;

  @override
  State<PttTab> createState() => _PttTabState();
}

class _PttTabState extends State<PttTab> {
  static const _maximumTalkDuration = Duration(seconds: 10);
  PigeonProfile? _selectedContact;
  Timer? _talkLimit;
  bool _isTransmitting = false;
  String _status = 'Selecione um contato e segure para falar';

  @override
  void dispose() {
    _talkLimit?.cancel();
    super.dispose();
  }

  void _selectContact(PigeonProfile contact) {
    setState(() {
      _selectedContact = contact;
      _status = 'Pronto. Segure para falar (máx. 10s)';
    });
  }

  void _startTalking() {
    if (_selectedContact == null) {
      setState(() => _status = 'Selecione um contato da lista primeiro.');
      return;
    }
    _talkLimit?.cancel();
    setState(() {
      _isTransmitting = true;
      _status = 'PTT pressionado para ${_selectedContact!.name}';
    });
    _talkLimit = Timer(_maximumTalkDuration, _stopTalking);
  }

  void _stopTalking() {
    _talkLimit?.cancel();
    if (!mounted || !_isTransmitting) return;
    setState(() {
      _isTransmitting = false;
      _status = 'Pronto. Segure para falar (máx. 10s)';
    });
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
                'Áudio e envio dependem da conexão com o serviço Pigeon.',
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
