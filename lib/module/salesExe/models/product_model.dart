class Product {
  final String name;
  final String category;
  final double price;
  final String suction;
  final String filter;
  final String warranty;

  const Product({
    required this.name,
    required this.category,
    required this.price,
    this.suction = '1200 m³/hr',
    this.filter = 'Filterless, auto-clean',
    this.warranty = '5 years motor',
  });

  static const List<Product> catalog = [
    Product(name: 'Neo Elica 90cm', category: 'Chimneys', price: 18990),
    Product(name: 'Zeus Auto Clean', category: 'Chimneys', price: 24500),
    Product(name: 'Curvo 60cm', category: 'Chimneys', price: 14250),
    Product(name: 'Ceylon Straight', category: 'Chimneys', price: 16800),
    Product(name: '3-Burner Auto Hob', category: 'Hobs', price: 9500),
    Product(name: '2-Burner Glass Hob', category: 'Hobs', price: 6200),
    Product(name: 'Induction Cooktop', category: 'Cooktops', price: 3400),
    Product(name: 'Built-in Oven 60L', category: 'Ovens', price: 21500),
    Product(name: 'RO + UV Purifier', category: 'Purifiers', price: 8990),
  ];

  static const List<String> categories = ['Chimneys', 'Hobs', 'Cooktops'];
}
