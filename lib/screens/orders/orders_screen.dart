import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../services/api_client.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _dateFmt = DateFormat('MMM d, yyyy • h:mm a');

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order>? _orders;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await context.read<ApiClient>().myOrders();
      _orders = raw.whereType<Map<String, dynamic>>().map((e) => Order.fromJson(e)).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load your orders.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: SafeArea(
        child: _loading
            ? const ListRowSkeleton()
            : _error != null
                ? ErrorStateView(message: _error!, onRetry: _load)
                : (_orders == null || _orders!.isEmpty)
                    ? const EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No orders yet',
                        subtitle: 'Your placed orders will show up here.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _orders!.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (_, i) => _OrderCard(order: _orders![i]),
                        ),
                      ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  Color get _statusColor {
    switch (order.status) {
      case 'RESCUED':
        return AppColors.secondary;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(order.status, style: TextStyle(color: _statusColor, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
          if (order.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(_dateFmt.format(order.createdAt!), style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
          ...order.items.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.quantity}× ${item.name}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                      ),
                      Text(_currency.format(item.price * item.quantity),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          if (order.items.length > 3)
            Text('+ ${order.items.length - 3} more item(s)', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text(_currency.format(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primaryDark)),
            ],
          ),
        ],
      ),
    );
  }
}
