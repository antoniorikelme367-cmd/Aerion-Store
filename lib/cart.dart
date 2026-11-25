import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final String sub;
  final String img;
  final bool contain;
  final double price;
  final bool rental;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.sub,
    required this.img,
    this.contain = false,
    required this.price,
    this.rental = false,
    this.quantity = 1,
  });
}

class ShoppingCart extends ChangeNotifier {
  final List<CartItem> items = [];

  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  double get total => items.fold(0, (sum, item) => sum + item.price * item.quantity);

  void add(CartItem item) {
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index].quantity += item.quantity;
    }
    notifyListeners();
  }

  void setQuantity(CartItem item, int quantity) {
    if (!items.contains(item)) return;
    if (quantity <= 0) {
      items.remove(item);
    } else {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void remove(CartItem item) {
    items.remove(item);
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }
}

final ShoppingCart cart = ShoppingCart();
