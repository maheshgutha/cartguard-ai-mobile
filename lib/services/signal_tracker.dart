import 'dart:async';
import 'package:flutter/widgets.dart';
import 'api_client.dart';
import '../core/constants.dart';

/// Mirrors the web storefront's micro-telemetry emitter: periodically
/// heartbeats the session and reports app-lifecycle events (backgrounding,
/// resuming) as behavioral signals so CartGuard's ML engine can score
/// abandonment risk and trigger recovery messages in real time.
class SignalTracker with WidgetsBindingObserver {
  SignalTracker(this._api);

  final ApiClient _api;
  Timer? _heartbeatTimer;
  bool _active = false;

  void start() {
    if (_active) return;
    _active = true;
    WidgetsBinding.instance.addObserver(this);
    _heartbeatTimer = Timer.periodic(AppConstants.heartbeatInterval, (_) => _api.heartbeat());
  }

  void stop() {
    if (!_active) return;
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _api.sendSignal('tab_switch');
        break;
      case AppLifecycleState.resumed:
        _api.heartbeat();
        break;
      case AppLifecycleState.detached:
        _api.goodbye();
        break;
      default:
        break;
    }
  }

  void reportFormError() => _api.sendSignal('form_field_error');
  void reportPaymentFailure() => _api.sendSignal('payment_failure');
  void reportProductView(String productId) =>
      _api.sendSignal('product_view', meta: {'productId': productId});
}
