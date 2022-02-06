import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/http_exception.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String? id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
  });

  Future<void> toggleFavoriteStatus() async {
    bool oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    final url = await Uri.parse(
      'https://flutter-demo-7218c-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id',
    );
    try {
      final response = await http.patch(
        url,
        body: json.encode(
          {
            'isFavorite': isFavorite,
          },
        ),
      );
      if (response.statusCode >= 400) {
        throw HttpException('Could not update this Product!');
      }
    } catch (error) {
      print(error);
      isFavorite = oldStatus;
      notifyListeners();
    }
  }
}
