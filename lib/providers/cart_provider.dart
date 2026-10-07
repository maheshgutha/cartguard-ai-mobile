import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/api_client.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this.api);

  final ApiClient api;

  Cart _cart = Cart.empty();
  bool _loading = false;
  String? _error;

  Cart get cart => _cart;
  bool get loading => _loading;
  String? get error => _error;
  int get itemCount => _cart.totalUnits;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final json = await api.getCart();
      _cart = Cart.fromJson(json);
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Could not sync cart.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(String productId, {int quantity = 1}) async {
    try {
      final json = await api.addToCart(productId, quantity: quantity);
      _cart = Cart.fromJson(json);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not add item to cart.';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    // Optimistic update for a snappy UI.
    final prev = _cart;
    final updatedItems = _cart.items.map((i) {
      if (i.productId == productId) {
        return CartItem(productId: i.productId, name: i.name, price: i.price, image: i.image, quantity: quantity);
      }
      return i;
    }).toList();
    _cart = Cart(items: updatedItems, cartValue: updatedItems.fold(0.0, (s, i) => s + i.lineTotal));
    notifyListeners();

    try {
      final json = await api.updateCartItem(productId, quantity);
      _cart = Cart.fromJson(json);
    } catch (_) {
      _cart = prev; // rollback
    }
    notifyListeners();
  }

  Future<void> remove(String productId) async {
    final prev = _cart;
    _cart = Cart(
      items: _cart.items.where((i) => i.productId != productId).toList(),
      cartValue: _cart.items.where((i) => i.productId != productId).fold(0.0, (s, i) => s + i.lineTotal),
    );
    notifyListeners();
    try {
      final json = await api.removeFromCart(productId);
      _cart = Cart.fromJson(json);
    } catch (_) {
      _cart = prev;
    }
    notifyListeners();
  }

  void clearLocal() {
    _cart = Cart.empty();
    notifyListeners();
  }
}
