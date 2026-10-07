import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api);

  final ApiClient api;

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _busy = false;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get busy => _busy;
  bool get isAdmin => _user?.role == 'admin';

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUser);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _user = AppUser.fromJson(json);
        api.token = _user!.token;
        _status = AuthStatus.authenticated;
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final json = await api.login(email: email, password: password);
      await _persist(json);
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Could not reach CartGuard servers. Check your connection.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final json = await api.register(name: name, email: email, password: password, phone: phone);
      await _persist(json);
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Could not reach CartGuard servers. Check your connection.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _persist(Map<String, dynamic> json) async {
    _user = AppUser.fromJson(json);
    api.token = _user!.token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUser, jsonEncode(_user!.toJson()));
  }

  Future<void> logout() async {
    try {
      await api.goodbye();
    } catch (_) {}
    _user = null;
    api.token = null;
    _status = AuthStatus.unauthenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUser);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
