import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // A list which can be changed over time and not final
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((item) => item.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts() async {
    final url = Uri.parse(
        'https://flutter-demo-7218c-default-rtdb.asia-southeast1.firebasedatabase.app/products.json');
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body)! as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      // execute a function on every entry in that map (on the outer map/on every unique ID we have)
      extractedData.forEach((prodId, prodData) {
        // Convert the data into Product objects based on Product class
        loadedProducts.add(
          Product(
            id: prodId,
            title: prodData['title'],
            description: prodData['description'],
            price: prodData['price'] as double,
            imageUrl: prodData['imageUrl'],
            isFavorite: prodData['isFavorite'],
          ),
        );
      });
      _items = loadedProducts;
      notifyListeners();
      print(json.decode(response.body));
    } catch (error) {
      throw (error);
    }
  }

  /* Add a new product into the current list of products */
  Future<void> addProduct(Product product) async {
    final url = Uri.parse(
        'https://flutter-demo-7218c-default-rtdb.asia-southeast1.firebasedatabase.app/products.json');
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'isFavorite': product.isFavorite,
          },
        ),
      );

      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
        // We work with a perfect copy of what we have on the back-end.
      );
      _items.add(newProduct);
      // _items.insert(0, newProduct); // at the start of the list
      notifyListeners(); // Notify widget classes listening to this class about changes in "_items" to be rebuilt
    } catch (error) {
      // Defines a function that receives an error
      print(error);
      // Throw that error we received again, and now create a new error based on the previous error obj
      throw (error); // Do this as we want to add a newer "catch" error clause in another place (edit_product_screen)
    }
    //return Future.value(); // Problem: instantly return => too early, not really work so we need to find another solution.
  }

  /* Edit and update the information about the selected product */
  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id.toString() == id);
    if (prodIndex >= 0) {
      // Can't use const anymore since it's not constant at compilation time.
      final url = Uri.parse(
          'https://flutter-demo-7218c-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json');
      await http.patch(
        url,
        body: json.encode(
          {
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price
          },
        ),
      );
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  /* Delete a specific product based on an product-id provided by someone */
  /*  Status code:
   *   200, 201: everything worked
   *   300: you were redirected.
   *   400, 500: sth went wrong
   *   Get, Post request: the HTTP package we're using automatically throws an error if we have a status code that >= 400.
   *                      (=> So for all these errors status code, it throws an error and we make it into catchError).
   *                      But for "delete", it doesn't do that and therefore we end up in the ".then" block...
   */
  void deleteProduct(String id) {
    final url = Uri.parse(
        'https://flutter-demo-7218c-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json');
    // Before we remove my item here and actually start sending the request, therefore just to be safe,
    // we'll copy it => create a new final variable which is existingProduct
    final existingProductIndex = _items.indexWhere((prod) =>
        prod.id.toString() == id); // Get an index of product we want to remove.
    // Added a runtime constant which is item for that existing product index.
    Product? existingProduct = _items[existingProductIndex];
    // Remove item from the list(not from memory). The item, object itself will live in memory.
    // Dart would normally clear it from memory if it finds no-one who is still interested in the data which would
    // normally be the case if we remove it from the list. But here, since we stored a reference to the product in
    // existingProduct, we still have someone interested in the existingProduct and therefore we still keep that product.
    /*
     *  Optimistic updating pattern: where I roll back if my product deletion should fail. Of course, we can notify listener after
     *   the roll back as well.
     */
    //_items.removeWhere((prod) => prod.id.toString() == id); // Remove item from items' list
    // Instead of using async/await, we can also do sth which is known as "optimistic updating"
    http.delete(url).then((response) // if we succeed.
        {
      print(response.statusCode);
      // Normally, for GET and POST, the HTTP package would have thrown an error and our code here would've been kicked off.
      if (response.statusCode >= 400) // Want to throw our own errors.
      {
        throw HttpException(
            'Could not delete product.'); // Since we're throwing this, we should now make it into catchError, so now we should restore that.
        //throw Exception(); // Not recommend to directly use it. Instead, we should build our own exception based on that Exception class here.
      }
      existingProduct =
          null; // to clear up that reference and let Dart remove that obj in memory because now, really no-one is interested in it anymore.
    }).catchError(
        (error) // don't await the result of this. But we can also use "async/await" approach
        {
      // Once an error occurred, just want to roll back the removal here.
      // This is optimistic updating because this ensures that I re-add that product if we fail.
      _items.insert(existingProductIndex,
          existingProduct!); // the existingProduct constant holds a reference to the old product, so it will reinsert it into the list if we get failed and got error.
      notifyListeners();
    });
    _items.removeAt(existingProductIndex);
    notifyListeners();
  }
}
