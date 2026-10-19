import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void enxosForegroundTaskStart() {
  FlutterForegroundTask.setTaskHandler(EnxosTaskHandler());
}

class EnxosTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'enxOS & Pigeon ativos',
      notificationText: 'Sessão e escuta PTT em segundo plano.',
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Aqui você pode inserir a lógica em background para verificar novos beeps do PTT
    // Exemplo: consultar a API se houver uma instância global ou callback configurado.
    
    FlutterForegroundTask.updateService(
      notificationTitle: 'enxOS ativo',
      notificationText: 'Sincronização PTT • ${_formatTime(timestamp)}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    // Permite enviar dados do app principal para o serviço em execução (ex: disparar PTT)
    if (data is Map && data['action'] == 'play_ptt') {
      debugInfo('Executando PTT via Foreground Service em segundo plano.');
    }
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ForegroundServiceController {
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static void initialize() {
    if (kIsWeb) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'enxos_foreground_service',
        channelName: 'Serviço enxOS',
        channelDescription: 'Indica que o serviço enxOS e PTT estão ativos.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000), // Intervalo ajustado para checagem
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true, // Mantém a CPU acordada para processar áudio/PTT se necessário
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> get isRunning async {
    if (!isSupported) return false;
    return FlutterForegroundTask.isRunningService;
  }

  static Future<bool> start() async {
    if (!isSupported) return false;

    var permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
      permission = await FlutterForegroundTask.checkNotificationPermission();
    }
    if (permission != NotificationPermission.granted) return false;

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 410,
        notificationTitle: 'enxOS ativo',
        notificationText: 'Sessão e PTT em execução em segundo plano.',
        callback: enxosForegroundTaskStart,
      );
    }
    return true;
  }

  static Future<void> stop() async {
    if (isSupported && await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// Método auxiliar para enviar comandos de PTT diretamente para o serviço rodando em background
  static void sendCommandToService(Map<String, dynamic> data) {
    if (isSupported) {
      FlutterForegroundTask.sendDataToTask(data);
    }
  }
}
