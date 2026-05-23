// lib/services/now_playing_notification_service.dart
// ── Shows a "Now Playing" system notification whenever the track changes ──
//
// Dependencies (add to pubspec.yaml):
//   flutter_local_notifications: ^17.0.0
//
// Android: no extra setup needed for basic notifications.
// iOS: call requestPermissions() early (done in init below).
// Add notification icon to Android:
//   android/app/src/main/res/drawable/ic_notification.png  (white 24×24 png)
// --------------------------------------------------------------------------

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NowPlayingNotificationService {
  NowPlayingNotificationService._();
  static final instance = NowPlayingNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'now_playing';
  static const _channelName = 'Now Playing';
  static const _notifId     = 42;

  bool _ready = false;

  // ── Call once at app startup (before runApp or inside main) ──────────────
  Future<void> init() async {
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const iOS     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
    _ready = true;
  }

  // ── Show / update the notification ───────────────────────────────────────
  Future<void> show({
    required String title,
    required String subtitle,
    String? arabicTitle,
  }) async {
    if (!_ready) return;

    // Body: combine subtitle + arabic title if present
    final body = arabicTitle != null && arabicTitle.isNotEmpty
        ? '$subtitle  •  $arabicTitle'
        : subtitle;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Shows the currently playing track',
      importance: Importance.low,        // silent — no sound/vibration
      priority: Priority.low,
      ongoing: true,                     // can't be swiped away while playing
      onlyAlertOnce: true,               // don't re-alert on updates
      playSound: false,
      enableVibration: false,
      showWhen: false,
      icon: '@drawable/ic_notification',
      styleInformation: BigTextStyleInformation(''),
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: false,   // don't show banner on iOS — just notification centre
      presentSound: false,
      presentBadge: false,
    );

    await _plugin.show(
      _notifId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iOSDetails),
    );
  }

  // ── Dismiss when playback stops / app closes ─────────────────────────────
  Future<void> dismiss() async {
    if (!_ready) return;
    await _plugin.cancel(_notifId);
  }
}