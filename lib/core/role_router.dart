import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_shell_screen.dart';
import '../screens/main_nav_screen.dart';

/// Single source of truth for "which screen does this user land on".
/// Used by splash, login, and register so role routing never drifts
/// out of sync between the three entry points.
Widget homeScreenForRole(AuthProvider auth) {
  if (auth.isAdmin) return const AdminShellScreen();
  return const MainNavScreen();
}
