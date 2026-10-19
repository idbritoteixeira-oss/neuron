import 'package:flutter/services.dart';

/// Bridge fino para gravação e reprodução no Android sem pacote de áudio extra.
abstract final class PigeonAudioPlatform {
  static const MethodChannel _channel = MethodChannel('enxos/pigeon_audio');

  static Future<void> startRecording() async {
    await _channel.invokeMethod<void>('startRecording');
  }

  static Future<String> stopRecording() async {
    final path = await _channel.invokeMethod<String>('stopRecording');
    if (path == null || path.isEmpty) {
      throw const PlatformException(
        code: 'empty_recording',
        message: 'A gravação não foi criada.',
      );
    }
    return path;
  }

  static Future<void> play(String url) =>
      _channel.invokeMethod<void>('play', {'url': url});

  static Future<void> stopPlayback() => _channel.invokeMethod<void>('stop');
}
