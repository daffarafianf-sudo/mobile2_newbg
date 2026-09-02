import '../models/product.dart';

class DummyDataService {
  static List<Product> topProducts = [
    Product(
      name: "Kemeja Flanel Premium",
      stock: 45,
      price: 189000,
      sold: 87,
    ),
    Product(
      name: "Hoodie Oversize",
      stock: 12,
      price: 249000,
      sold: 64,
    ),
  ];

  static List<Product> products = [
    Product(
      name: "T-Shirt Basic",
      stock: 3,
      price: 89000,
      sold: 120,
    ),
  ];
}
