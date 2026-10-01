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
      notificationTitle: 'enxOS ativo',
      notificationText: 'Sessão em execução em segundo plano.',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'enxOS ativo',
      notificationText: 'Verificação de atividade • ${_formatTime(timestamp)}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

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
        channelDescription: 'Indica que o serviço enxOS está ativo.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: false,
        allowWifiLock: false,
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
        notificationText: 'Sessão em execução em segundo plano.',
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
}