import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/edit_product_screen.dart';
import '../widgets/user_product_item.dart';
import '../providers/products.dart';
import '../widgets/app_drawer.dart';

class UserProductsScreen extends StatelessWidget {
  static const routeName = '/user-products';

  Future<void> _refreshProducts(BuildContext context) async {
    await Provider.of<Products>(context, listen: false).fetchAndSetProducts();
  }

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<Products>(context).items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Products'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(EditProductScreen.routeName);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: RefreshIndicator(
        // Because onRefresh returns a future so RefreshIndicator knows when it's done fetching the data
        // because it'll show a spinner automatically in the meantime and it needs to know when to dismiss this.
        onRefresh: () => _refreshProducts(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: products.isEmpty
              ? const Center(
                  child: Text(
                    'No Products !!!',
                    style: TextStyle(fontSize: 15),
                  ),
                )
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (ctx, index) => Column(
                    children: [
                      UserProductItem(
                        id: products[index].id.toString(),
                        title: products[index].title,
                        imageUrl: products[index].imageUrl,
                      ),
                      const Divider(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
