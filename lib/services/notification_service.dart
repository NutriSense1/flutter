import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

/// Wraps FirebaseMessaging so the rest of the app never touches the SDK
/// directly. Call [initAfterSignIn] once a profile exists (home screen /
/// main shell init) and [removeTokenOnSignOut] right before signing out.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api;
  String? _lastRegisteredToken;

  NotificationService(this._api);

  /// A function the UI can override to show an in-app banner for
  /// foreground pushes (FCM does NOT show a system tray notification
  /// while the app is open and in the foreground — that's expected
  /// behavior on every platform, not a bug — so the app has to do it).
  void Function(RemoteMessage message)? onForegroundMessage;

  Future<void> initAfterSignIn() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) return; // person declined — nothing more to do

      await _registerCurrentToken();
      _messaging.onTokenRefresh.listen((_) => _registerCurrentToken());

      FirebaseMessaging.onMessage.listen((message) {
        onForegroundMessage?.call(message);
      });
    } catch (_) {
      // Push is a nice-to-have, never let setup failures block the app.
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token == _lastRegisteredToken) return;
      await _api.registerDeviceToken(token, _platformName());
      _lastRegisteredToken = token;
    } catch (_) {
      // Will retry next app launch / next onTokenRefresh event.
    }
  }

  Future<void> removeTokenOnSignOut() async {
    final token = _lastRegisteredToken;
    if (token == null) return;
    try {
      await _api.removeDeviceToken(token);
    } catch (_) {
      // Best-effort — the backend keeping a stale token around for a
      // signed-out device is a minor inconvenience, not worth blocking
      // sign-out over.
    }
    _lastRegisteredToken = null;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }
}
