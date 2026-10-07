import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';

void main() {
  runApp(const CartGuardApp());
}

class CartGuardApp extends StatelessWidget {
  const CartGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProxyProvider<ApiClient, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<ApiClient>()),
          update: (ctx, api, previous) => previous ?? AuthProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiClient, ProductProvider>(
          create: (ctx) => ProductProvider(ctx.read<ApiClient>()),
          update: (ctx, api, previous) => previous ?? ProductProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiClient, CartProvider>(
          create: (ctx) => CartProvider(ctx.read<ApiClient>()),
          update: (ctx, api, previous) => previous ?? CartProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiClient, AdminProvider>(
          create: (ctx) => AdminProvider(ctx.read<ApiClient>()),
          update: (ctx, api, previous) => previous ?? AdminProvider(api),
        ),
      ],
      child: MaterialApp(
        title: 'CartGuard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
