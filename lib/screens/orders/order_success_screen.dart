import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/gradient_button.dart';
import '../main_nav_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8).toUpperCase() : orderId.toUpperCase();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.mintGradient),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.35), blurRadius: 26, offset: const Offset(0, 12))],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 28),
              const Text('Order placed! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'Your order has been confirmed. CartGuard will keep you posted on its status.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.5, height: 1.5),
              ),
              if (shortId.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF1EEF9), borderRadius: BorderRadius.circular(12)),
                  child: Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ],
              const SizedBox(height: 40),
              GradientButton(
                label: 'Back to shopping',
                icon: Icons.storefront_rounded,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavScreen()),
                  (route) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
