import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/gradient_button.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    // Feeds the CartGuard ML engine's dwell-time / interest signal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiClient>().sendSignal('product_view', meta: {'productId': widget.productId});
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().byId(widget.productId);

    if (product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 340,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _RoundIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFFF1EEF9),
                    child: product.image.isNotEmpty
                        ? CachedNetworkImage(imageUrl: product.image, fit: BoxFit.cover)
                        : const Icon(Icons.shopping_bag_outlined, size: 90, color: AppColors.primaryLight),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(product.name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 3),
                                Text(product.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _Tag(text: product.category, color: AppColors.primary),
                          _Tag(text: product.qualityTier, color: AppColors.secondary),
                          _Tag(
                            text: product.inStock ? '${product.stock} in stock' : 'Out of stock',
                            color: product.inStock ? Colors.grey.shade600 : AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(_currency.format(product.price),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                      const SizedBox(height: 20),
                      if (product.description.isNotEmpty) ...[
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                        const SizedBox(height: 8),
                        Text(product.description,
                            style: TextStyle(fontSize: 14.5, color: Colors.grey.shade700, height: 1.5)),
                        const SizedBox(height: 22),
                      ],
                      if (product.specifications.isNotEmpty) ...[
                        const Text('Specifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F6FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Column(
                            children: product.specifications.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 130,
                                      child: Text(e.key,
                                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13.5)),
                                    ),
                                    Expanded(
                                      child: Text(e.value,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, -6))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _QtyStepper(
                      qty: _qty,
                      onChanged: (v) => setState(() => _qty = v),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GradientButton(
                        label: product.inStock ? 'Add to cart' : 'Out of stock',
                        icon: Icons.shopping_bag_rounded,
                        loading: _adding,
                        onPressed: product.inStock
                            ? () async {
                                setState(() => _adding = true);
                                final ok = await context.read<CartProvider>().add(product.id, quantity: _qty);
                                if (!mounted) return;
                                setState(() => _adding = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ok ? 'Added to cart 🎉' : 'Could not add to cart')),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.onChanged});
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF1EEF9), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _StepBtn(icon: Icons.remove_rounded, onTap: qty > 1 ? () => onChanged(qty - 1) : null),
          SizedBox(width: 30, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
          _StepBtn(icon: Icons.add_rounded, onTap: () => onChanged(qty + 1)),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey.shade400 : AppColors.primaryDark),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A1523)),
      ),
    );
  }
}
