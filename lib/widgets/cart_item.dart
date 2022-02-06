import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart.dart';

class CartItem extends StatelessWidget {
  final String id;
  final String productId;
  final String title;
  final int quantity;
  final double price;

  CartItem(
    this.id,
    this.productId,
    this.title,
    this.quantity,
    this.price,
  );

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context, listen: false);
    return Dismissible(
      key: ValueKey(productId),
      onDismissed: (direction) {
        cart.removeItem(productId);
      },
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
        padding: const EdgeInsets.only(
          right: 15,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 40,
        ),
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
      ),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                fit: BoxFit.cover,
                child: Text(
                  '\$${price.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          title: Text(
            title,
          ),
          subtitle: Text(
            'Total: \$${(price * quantity).toStringAsFixed(2)}',
          ),
          trailing: Text(
            '$quantity x',
          ),
        ),
      ),
    );
  }
}
