import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../orders/order_success_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placingOrder = false;

  Future<void> _checkout() async {
    setState(() => _placingOrder = true);
    try {
      final order = await context.read<ApiClient>().placeOrder();
      await context.read<CartProvider>().load();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: (order['_id'] ?? '').toString())),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not place order. Try again.')));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: SafeArea(
        child: cartProvider.loading && cart.items.isEmpty
            ? const ListRowSkeleton()
            : cart.items.isEmpty
                ? const EmptyStateView(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your cart is empty',
                    subtitle: 'Items you add will show up here, ready for checkout.',
                  )
                : RefreshIndicator(
                    onRefresh: () => cartProvider.load(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 210),
                      children: [
                        if (cart.recoveryMessage != null) _RecoveryBanner(cart: cart),
                        ...cart.items.map((item) => _CartTile(item: item)),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, -6))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SummaryRow(label: 'Subtotal (${cart.totalUnits} items)', value: _currency.format(cart.cartValue)),
                    if (cart.recoveryDiscount > 0) ...[
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'CartGuard discount',
                        value: '- ${_currency.format(cart.recoveryDiscount)}',
                        valueColor: AppColors.secondary,
                      ),
                    ],
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                    _SummaryRow(
                      label: 'Total',
                      value: _currency.format((cart.cartValue - cart.recoveryDiscount).clamp(0, double.infinity)),
                      big: true,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Checkout',
                      icon: Icons.lock_rounded,
                      loading: _placingOrder,
                      onPressed: _checkout,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RecoveryBanner extends StatelessWidget {
  const _RecoveryBanner({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.mintGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cart.recoveryMessage!,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => context.read<CartProvider>().remove(item.productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 66,
                height: 66,
                child: item.image.isNotEmpty
                    ? CachedNetworkImage(imageUrl: item.image, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFF1EEF9), child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryLight)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 4),
                  Text(_currency.format(item.price), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 13.5)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF1EEF9), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniBtn(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      if (item.quantity > 1) {
                        context.read<CartProvider>().updateQuantity(item.productId, item.quantity - 1);
                      } else {
                        context.read<CartProvider>().remove(item.productId);
                      }
                    },
                  ),
                  SizedBox(width: 22, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                  _MiniBtn(
                    icon: Icons.add_rounded,
                    onTap: () => context.read<CartProvider>().updateQuantity(item.productId, item.quantity + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 15, color: AppColors.primaryDark)),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.big = false, this.valueColor});
  final String label;
  final String value;
  final bool big;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: big ? 16 : 13.5, fontWeight: big ? FontWeight.w800 : FontWeight.w500, color: big ? const Color(0xFF1A1523) : Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: big ? 20 : 14, fontWeight: FontWeight.w800, color: valueColor ?? (big ? AppColors.primaryDark : const Color(0xFF1A1523)))),
      ],
    );
  }
}
