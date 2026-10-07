import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadOrders());
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.secondary;
      case 'CANCELLED':
        return AppColors.danger;
      case 'SHIPPED':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    if (admin.busy && admin.orders.isEmpty) {
      return const ListRowSkeleton(count: 6);
    }
    if (admin.error != null && admin.orders.isEmpty) {
      return ErrorStateView(message: admin.error!, onRetry: () => admin.loadOrders());
    }
    if (admin.orders.isEmpty) {
      return const EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        subtitle: 'Placed orders from every shopper will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => admin.loadOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: admin.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final order = Map<String, dynamic>.from(admin.orders[i] as Map);
          final user = order['user'];
          final name = (user is Map ? user['name'] : null) ?? 'Unknown';
          final total = order['totalAmount'] is num ? (order['totalAmount'] as num).toDouble() : 0.0;
          final status = (order['status'] ?? 'PLACED').toString();
          final items = (order['items'] as List?) ?? [];
          final id = (order['_id'] ?? '').toString();

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
                    Expanded(
                      child: Text(
                        id.length > 8 ? '#${id.substring(id.length - 8)}' : '#$id',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _statusColor(status))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(name.toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${items.length} item${items.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Text('₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
              ],
            ),
          );
        },
      ),
    );
  }
}
