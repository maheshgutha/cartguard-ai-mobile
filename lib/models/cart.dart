class CartItem {
  final String productId;
  final String name;
  final double price;
  final String image;
  final int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productField = json['product'];
    String productId;
    if (productField is Map) {
      productId = (productField['_id'] ?? '').toString();
    } else {
      productId = (productField ?? '').toString();
    }
    return CartItem(
      productId: productId,
      name: json['name'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      image: json['image'] ?? '',
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1,
    );
  }

  double get lineTotal => price * quantity;
}

class Cart {
  final List<CartItem> items;
  final double cartValue;
  final String? recoveryMessage;
  final double recoveryDiscount;

  Cart({
    required this.items,
    required this.cartValue,
    this.recoveryMessage,
    this.recoveryDiscount = 0,
  });

  factory Cart.empty() => Cart(items: [], cartValue: 0);

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsRaw = (json['items'] as List?) ?? [];
    final items = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => CartItem.fromJson(e))
        .toList();

    double computedValue = 0;
    if (json['cartValue'] is num) {
      computedValue = (json['cartValue'] as num).toDouble();
    } else {
      computedValue = items.fold(0.0, (sum, i) => sum + i.lineTotal);
    }

    final offer = json['recoveryOffer'];
    String? msg;
    double discount = 0;
    if (offer is Map) {
      final message = offer['message'];
      if (message is String && message.trim().isNotEmpty) msg = message;
      if (offer['discountAmount'] is num) {
        discount = (offer['discountAmount'] as num).toDouble();
      }
    }

    return Cart(items: items, cartValue: computedValue, recoveryMessage: msg, recoveryDiscount: discount);
  }

  int get totalUnits => items.fold(0, (sum, i) => sum + i.quantity);
}
