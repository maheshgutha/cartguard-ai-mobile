import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../notifications/notifications_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final firstName = (auth.user?.name ?? '').split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ProductProvider>().load(silent: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName.isEmpty ? 'Hey there 👋' : 'Hey, $firstName 👋',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text('Find something you\'ll love today',
                                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      _NotificationBell(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => context.read<ProductProvider>().setQuery(v),
                    decoration: InputDecoration(
                      hintText: 'Search products…',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                _searchCtrl.clear();
                                context.read<ProductProvider>().setQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
              ),
              if (productProvider.categories.length > 1)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: productProvider.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = productProvider.categories[i];
                        final selected = productProvider.category == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => context.read<ProductProvider>().setCategory(cat),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : const Color(0xFF1A1523),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              if (productProvider.loading)
                const SliverToBoxAdapter(child: ProductGridSkeleton())
              else if (productProvider.error != null)
                SliverFillRemaining(
                  child: ErrorStateView(
                    message: productProvider.error!,
                    onRetry: () => context.read<ProductProvider>().load(),
                  ),
                )
              else if (productProvider.products.isEmpty)
                const SliverFillRemaining(
                  child: EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No products found',
                    subtitle: 'Try a different search term or category.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.64,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final product = productProvider.products[i];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
                          ),
                          onAdd: () async {
                            final ok = await context.read<CartProvider>().add(product.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? '${product.name} added to cart' : 'Could not add to cart'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                      childCount: productProvider.products.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: const Color(0xFFF1EEF9), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
      ),
    );
  }
}
