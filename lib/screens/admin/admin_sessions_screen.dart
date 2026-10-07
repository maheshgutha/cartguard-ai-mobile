import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';

class AdminSessionsScreen extends StatefulWidget {
  const AdminSessionsScreen({super.key});

  @override
  State<AdminSessionsScreen> createState() => _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends State<AdminSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadLiveSessions());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    if (admin.busy && admin.liveSessions.isEmpty) {
      return const ListRowSkeleton(count: 6);
    }
    if (admin.error != null && admin.liveSessions.isEmpty) {
      return ErrorStateView(message: admin.error!, onRetry: () => admin.loadLiveSessions());
    }
    if (admin.liveSessions.isEmpty) {
      return const EmptyStateView(
        icon: Icons.podcasts_outlined,
        title: 'No live carts right now',
        subtitle: 'Active shopper carts with items will show up here in real time.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => admin.loadLiveSessions(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: admin.liveSessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final cart = Map<String, dynamic>.from(admin.liveSessions[i] as Map);
          final user = cart['user'];
          final name = (user is Map ? user['name'] : null) ?? 'Guest';
          final email = (user is Map ? user['email'] : null) ?? '';
          final items = (cart['items'] as List?) ?? [];
          final value = cart['cartValue'] is num
              ? (cart['cartValue'] as num).toDouble()
              : items.fold<double>(0, (s, e) {
                  final m = e is Map ? e : {};
                  final price = m['price'] is num ? (m['price'] as num).toDouble() : 0.0;
                  final qty = m['quantity'] is num ? (m['quantity'] as num).toInt() : 1;
                  return s + price * qty;
                });

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(color: AppColors.bgLight, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          if (email.toString().isNotEmpty)
                            Text(email.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text('₹${value.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${items.length} item${items.length == 1 ? '' : 's'} in cart',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}
