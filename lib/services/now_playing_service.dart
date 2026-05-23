// lib/services/now_playing_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NowPlayingNotificationService {
  NowPlayingNotificationService._();
  static final instance = NowPlayingNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'now_playing_v2';
  static const _channelName = 'Now Playing';
  static const _notifId     = 42;

  bool _ready = false;

  Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iOS     = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: false,
        requestBadgePermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: iOS),
      );

      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _ready = true;
      debugPrint("NowPlayingNotificationService: Initialization successful.");
    } catch (e) {
      debugPrint("NowPlayingNotificationService: Initialization failed: $e");
    }
  }

  Future<void> show({
    required String title,
    required String subtitle,
    String? arabicTitle,
    bool isPlaying = true,
  }) async {
    if (!_ready) {
      debugPrint("NowPlayingNotificationService: Cannot show, service not ready.");
      return;
    }

    try {
      final body = arabicTitle != null && arabicTitle.isNotEmpty
          ? '$subtitle  •  $arabicTitle'
          : subtitle;

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Shows the currently playing track',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: false,
        styleInformation: const MediaStyleInformation(),
        // Restore action buttons so you can control playback directly from the card
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'play_pause_action',
            isPlaying ? 'Pause' : 'Play',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentSound: false,
        presentBadge: false,
      );

      await _plugin.show(
        _notifId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iOSDetails),
      );

      debugPrint("NowPlayingNotificationService: Notification sent successfully.");
    } catch (e) {
      debugPrint("NowPlayingNotificationService Error: Failed to show notification: $e");
    }
  }

  Future<void> dismiss() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_notifId);
      debugPrint("NowPlayingNotificationService: Notification dismissed.");
    } catch (e) {
      debugPrint("NowPlayingNotificationService Error: Failed to dismiss notification: $e");
    }
  }
}