/// Central place for app-wide constants.
class AppConstants {
  AppConstants._();

  /// Your live CartGuard AI MERN API (Node/Express) deployed on Render.
  /// Change this if you redeploy the backend elsewhere.
  static const String baseUrl = 'https://cartguard-ai-1.onrender.com/api';

  static const String appName = 'CartGuard';
  static const String appTagline = 'Shop smart. Never lose your cart.';

  // SharedPreferences keys
  static const String keyToken = 'cg_token';
  static const String keyUser = 'cg_user';
  static const String keySessionId = 'cg_session_id';
  static const String keyOnboardingSeen = 'cg_onboarding_seen';

  // Heartbeat / behavioral signal interval (mirrors the backend's
  // micro-telemetry engine that powers cart-abandonment prediction).
  static const Duration heartbeatInterval = Duration(seconds: 25);
}
