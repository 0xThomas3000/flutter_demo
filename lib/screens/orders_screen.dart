import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../providers/orders.dart' show Orders;
import '../widgets/order_item.dart';

class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders';

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<Orders>(context).orders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      drawer: AppDrawer(),
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'No orders found !!!',
                style: TextStyle(fontSize: 15),
              ),
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (ctx, index) => OrderItem(orders[index]),
            ),
    );
  }
}
