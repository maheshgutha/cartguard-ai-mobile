import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_client.dart';
import '../auth/login_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_sessions_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_more_screen.dart';

/// Root shell for the admin role. A hard gate — if a non-admin session
/// somehow lands here (stale cache, role change on the server), it bounces
/// straight back to login instead of rendering admin data.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;
  late final AdminProvider _admin;

  final _titles = const ['Overview', 'Live Sessions', 'Orders', 'More'];

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _admin = AdminProvider(api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _admin.refreshAll());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final screens = const [
      AdminOverviewScreen(),
      AdminSessionsScreen(),
      AdminOrdersScreen(),
      AdminMoreScreen(),
    ];

    return ChangeNotifierProvider<AdminProvider>.value(
      value: _admin,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(_titles[_index]),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ADMIN',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.4)),
              ),
            ],
          ),
        ),
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.podcasts_outlined), activeIcon: Icon(Icons.podcasts_rounded), label: 'Sessions'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), activeIcon: Icon(Icons.more_horiz_rounded), label: 'More'),
          ],
        ),
      ),
    );
  }
}
