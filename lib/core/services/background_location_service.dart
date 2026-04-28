import 'package:dio/dio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'networking/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────────
// Point d'entrée du service (top-level, appelé par flutter_foreground_task)
// ─────────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void startBackgroundCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundGpsTaskHandler());
}

// ─────────────────────────────────────────────────────────────────────────────────
// Handler : API compatible flutter_foreground_task ^8.17.0
// ─────────────────────────────────────────────────────────────────────────────────
class BackgroundGpsTaskHandler extends TaskHandler {
  // En v8+ onStart reçoit un TaskStarter, pas un SendPort
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  // En v8+ onRepeatEvent n'a qu'un seul paramètre
  @override
  void onRepeatEvent(DateTime timestamp) {
    _sendPosition(); // async fire-and-forget
  }

  Future<void> _sendPosition() async {
    try {
      final prefs    = await SharedPreferences.getInstance();
      final token    = prefs.getString('auth_token');
      final voyageId = prefs.getInt('active_voyage_id');
      if (token == null || voyageId == null) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));

      await dio.post(
        'chauffeur/voyages/$voyageId/update-location',
        data: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'speed': pos.speed * 3.6,
          'heading': pos.heading,
        },
      );

      final kmh = (pos.speed * 3.6).round();
      FlutterForegroundTask.updateService(
        notificationTitle: 'CAR225 — Voyage en cours',
        notificationText:
        'GPS actif  ${kmh > 0 ? "$kmh km/h" : "A l arret"}',
      );
    } catch (_) {
      // Silencieux : coupure réseau ou GPS indisponible
    }
  }

  // En v9+ onDestroy a un 2ème paramètre : isTimeout
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

// ─────────────────────────────────────────────────────────────────────────────────
// API publique
// ─────────────────────────────────────────────────────────────────────────────────
class BackgroundLocationService {
  /// A appeler une fois dans main() avant runApp()
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'car225_gps_channel',
        channelName: 'Suivi GPS CAR225',
        channelDescription:
        'Envoi continu de la position GPS pendant un voyage.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      // En v8+, interval est remplacé par eventAction
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
  static Future<void> start(int voyageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_voyage_id', voyageId);
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'CAR225 — Voyage en cours',
      notificationText: 'Suivi GPS actif en arriere-plan',
      callback: startBackgroundCallback,
    );
  }

  /// Arrête le service et nettoie les préférences.
  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_voyage_id');
  }

  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}