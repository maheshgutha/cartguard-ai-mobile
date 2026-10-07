import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_client.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this.api);

  final ApiClient api;

  List<Product> _all = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  String _category = 'All';

  bool get loading => _loading;
  String? get error => _error;
  String get category => _category;
  String get query => _query;

  List<String> get categories {
    final set = <String>{'All'};
    for (final p in _all) {
      if (p.category.trim().isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  List<Product> get products {
    return _all.where((p) {
      final matchesCategory = _category == 'All' || p.category == _category;
      final matchesQuery =
          _query.trim().isEmpty || p.name.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final raw = await api.getProducts();
      _all = raw.whereType<Map<String, dynamic>>().map((e) => Product.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Could not load products. Pull down to retry.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setCategory(String c) {
    _category = c;
    notifyListeners();
  }

  Product? byId(String id) {
    try {
      return _all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
