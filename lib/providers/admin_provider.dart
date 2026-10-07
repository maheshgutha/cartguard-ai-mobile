import 'package:flutter/material.dart';
import '../services/api_client.dart';

/// Backs the entire admin dashboard. Every call hits endpoints under
/// /api/admin, which the server gates with `protect + requireRole("admin")` —
/// this provider assumes the caller already confirmed `AuthProvider.isAdmin`.
class AdminProvider extends ChangeNotifier {
  AdminProvider(this.api);
  final ApiClient api;

  bool _busy = false;
  String? _error;
  Map<String, dynamic> overview = {};
  List<dynamic> liveSessions = [];
  List<dynamic> orders = [];
  List<dynamic> auditLogs = [];
  List<dynamic> demoScenarios = [];
  Map<String, dynamic> whatsAppStatus = {};

  bool get busy => _busy;
  String? get error => _error;

  Future<void> loadOverview() => _guard(() async {
        overview = await api.adminOverview();
      });

  Future<void> loadLiveSessions() => _guard(() async {
        liveSessions = await api.adminLiveSessions();
      });

  Future<void> loadOrders() => _guard(() async {
        orders = await api.adminOrders();
      });

  Future<void> loadAuditLog() => _guard(() async {
        final res = await api.adminAuditLog(limit: 100);
        final logs = res['logs'];
        auditLogs = logs is List ? logs : [];
      });

  Future<void> loadDemoScenarios() => _guard(() async {
        demoScenarios = await api.adminDemoScenarios();
      });

  Future<Map<String, dynamic>?> runDemoScenario(String name) async {
    try {
      return await api.adminRunDemoScenario(name);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadWhatsAppStatus() => _guard(() async {
        whatsAppStatus = await api.adminWhatsAppStatus();
      });

  Future<void> refreshAll() async {
    await Future.wait([
      loadOverview(),
      loadLiveSessions(),
      loadOrders(),
    ]);
  }

  Future<void> _guard(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Could not reach CartGuard servers. Check your connection.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
