class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String qualityTier;
  final double price;
  final String image;
  final int stock;
  final double rating;
  final Map<String, String> specifications;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.qualityTier,
    required this.price,
    required this.image,
    required this.stock,
    required this.rating,
    required this.specifications,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final specsRaw = json['specifications'];
    final specs = <String, String>{};
    if (specsRaw is Map) {
      specsRaw.forEach((key, value) {
        specs[key.toString()] = value.toString();
      });
    }

    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? 'Unnamed product',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      qualityTier: json['qualityTier'] ?? 'Standard',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      image: json['image'] ?? '',
      stock: (json['stock'] is num) ? (json['stock'] as num).toInt() : 0,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.0,
      specifications: specs,
    );
  }

  bool get inStock => stock > 0;
}
