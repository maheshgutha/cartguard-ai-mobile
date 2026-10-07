import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Thrown for any non-2xx API response or network failure with a human-readable [message].
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Thin wrapper around the CartGuard AI Node/Express REST API.
/// Base URL: https://cartguard-ai-1.onrender.com/api
class ApiClient {
  ApiClient({this.token});

  String? token;
  final String _base = AppConstants.baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _u(String path) => Uri.parse('$_base$path');

  dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    final msg = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Something went wrong (${res.statusCode})';
    throw ApiException(msg, res.statusCode);
  }

  Future<http.Response> _executeWithTimeout(Future<http.Response> Function() requestFn) async {
    try {
      return await requestFn().timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw ApiException(
        'Server is waking up (Render cold start). Please try again in a few seconds.',
      );
    } on SocketException {
      throw ApiException(
        'Could not reach CartGuard servers. Please check your internet connection.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: $e');
    }
  }

  Future<dynamic> _get(String path) async {
    final res = await _executeWithTimeout(() => http.get(_u(path), headers: _headers));
    return _decode(res);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await _executeWithTimeout(
        () => http.post(_u(path), headers: _headers, body: jsonEncode(body)));
    return _decode(res);
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final res = await _executeWithTimeout(
        () => http.put(_u(path), headers: _headers, body: jsonEncode(body)));
    return _decode(res);
  }

  Future<dynamic> _delete(String path) async {
    final res = await _executeWithTimeout(() => http.delete(_u(path), headers: _headers));
    return _decode(res);
  }

  // ── Auth ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final res = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await _post('/auth/login', {'email': email, 'password': password});
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _get('/auth/me');
    return Map<String, dynamic>.from(res);
  }

  // ── Products ────────────────────────────────────────────────────────
  Future<List<dynamic>> getProducts() async {
    final res = await _get('/products');
    if (res is List) return res;
    if (res is Map && res['products'] is List) return res['products'];
    return [];
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    final res = await _get('/products/$id');
    return Map<String, dynamic>.from(res);
  }

  // ── Cart ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCart() async {
    final res = await _get('/cart');
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> addToCart(String productId, {int quantity = 1}) async {
    final res = await _post('/cart/add', {'productId': productId, 'quantity': quantity});
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> updateCartItem(String productId, int quantity) async {
    final res = await _put('/cart/update', {'productId': productId, 'quantity': quantity});
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> removeFromCart(String productId) async {
    final res = await _delete('/cart/$productId');
    return Map<String, dynamic>.from(res);
  }

  /// Sends a behavioral micro-signal (e.g. tab_switch, idle, payment_error)
  /// that feeds the CartGuard risk-scoring ML engine.
  Future<void> sendSignal(String type, {Map<String, dynamic>? meta}) async {
    try {
      await _post('/cart/signal', {'type': type, if (meta != null) ...meta});
    } catch (_) {
      // Signals are best-effort — never block the UI on telemetry failures.
    }
  }

  Future<void> heartbeat() async {
    try {
      await _post('/cart/heartbeat', {});
    } catch (_) {}
  }

  Future<void> goodbye() async {
    try {
      await _post('/cart/goodbye', {});
    } catch (_) {}
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final res = await _get('/cart/notifications');
      if (res is List) return res;
      if (res is Map && res['notifications'] is List) return res['notifications'];
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<String> chat(String message) async {
    final res = await _post('/cart/chat', {'message': message});
    if (res is Map && res['reply'] != null) return res['reply'].toString();
    if (res is Map && res['message'] != null) return res['message'].toString();
    return "I'm here to help — could you rephrase that?";
  }

  // ── Orders ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> placeOrder() async {
    final res = await _post('/orders', {});
    return Map<String, dynamic>.from(res);
  }

  Future<List<dynamic>> myOrders() async {
    final res = await _get('/orders/mine');
    if (res is List) return res;
    if (res is Map && res['orders'] is List) return res['orders'];
    return [];
  }

  // ── Admin (role: admin only — server enforces via requireRole) ────────
  Future<Map<String, dynamic>> adminOverview() async {
    final res = await _get('/admin/overview');
    return Map<String, dynamic>.from(res);
  }

  Future<List<dynamic>> adminLiveSessions() async {
    final res = await _get('/admin/live-sessions');
    if (res is List) return res;
    return [];
  }

  Future<List<dynamic>> adminOrders() async {
    final res = await _get('/admin/orders');
    if (res is List) return res;
    return [];
  }

  Future<Map<String, dynamic>> adminAuditLog({int limit = 100, String? sessionId, bool excludeCooldown = false}) async {
    final qs = <String>['limit=$limit'];
    if (sessionId != null && sessionId.isNotEmpty) qs.add('session_id=$sessionId');
    if (excludeCooldown) qs.add('exclude_cooldown=true');
    final res = await _get('/admin/audit-log?${qs.join('&')}');
    return Map<String, dynamic>.from(res);
  }

  Future<List<dynamic>> adminDemoScenarios() async {
    final res = await _get('/admin/demo-scenarios');
    if (res is Map && res['scenarios'] is List) return res['scenarios'];
    if (res is List) return res;
    return [];
  }

  Future<Map<String, dynamic>> adminRunDemoScenario(String name) async {
    final res = await _post('/admin/demo-scenarios/$name/run', {});
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> adminUpliftSimulation({int nSessions = 10000}) async {
    final res = await _get('/admin/uplift?n_sessions=$nSessions');
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> adminWhatsAppStatus() async {
    final res = await _get('/admin/whatsapp-status');
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> adminStartWhatsApp() async {
    final res = await _post('/admin/whatsapp-start', {});
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> adminClearCooldown() async {
    final res = await _post('/admin/clear-cooldown', {});
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> adminSendTestEmail({String? toEmail, int discountPercent = 10}) async {
    final res = await _post('/admin/send-test-email', {
      if (toEmail != null) 'to_email': toEmail,
      'discount_percent': discountPercent,
    });
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> adminSendWhatsApp({required String phone, required String message}) async {
    final res = await _post('/admin/whatsapp-send', {'phone': phone, 'message': message});
    return Map<String, dynamic>.from(res);
  }
}
