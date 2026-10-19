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
    FlutterForegroundTask.updateService(
      notificationTitle: 'enxOS ativo',
      notificationText: 'Sincronização PTT • ${_formatTime(timestamp)}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    // Tratamento de dados recebidos em segundo plano com uso correto de debugPrint
    if (data is Map && data['action'] == 'play_ptt') {
      debugPrint('Executando PTT via Foreground Service em segundo plano.');
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
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
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

  static void sendCommandToService(Map<String, dynamic> data) {
    if (isSupported) {
      FlutterForegroundTask.sendDataToTask(data);
    }
  }
}
