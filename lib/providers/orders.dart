import 'package:flutter/foundation.dart';
import '../providers/cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime datetime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.datetime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _items = [];

  List<OrderItem> get items {
    return [..._items];
  }

  void addOrder(List<CartItem> prods, double amount) {
    _items.insert(
      0,
      OrderItem(
        id: DateTime.now().toString(),
        amount: amount,
        products: prods,
        datetime: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
