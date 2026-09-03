import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';

enum OrderStatus { placed, confirmed, dispatched, delivered }

class OrderLineItem {
  final Product product;
  final int qty;
  const OrderLineItem({required this.product, required this.qty});
  double get total => product.price * qty;
}

class KOrder {
  final String id;
  final String entityName;
  final String orderType; // Distributor / Retailer
  final String date;
  final OrderStatus status;
  final List<OrderLineItem> items;

  const KOrder({
    required this.id,
    required this.entityName,
    required this.orderType,
    required this.date,
    required this.status,
    required this.items,
  });

  double get amount => items.fold(0, (sum, i) => sum + i.total);

  // const → final: Product/Category aren't const-constructible anymore
  // now that Product.id and Product.category (a Category object) are
  // required non-const fields.
  static final List<KOrder> mockList = [
    KOrder(
      id: '#KUT-08213',
      entityName: 'Sharma Electronics',
      orderType: 'Distributor',
      date: 'Jul 18',
      status: OrderStatus.dispatched,
      items: [
        OrderLineItem(
          product: Product(
            id: 'mock-1',
            name: 'Neo Elica 90cm',
            category: Category(id: 'mock-cat-1', name: 'Chimneys'),
            price: 18990,
          ),
          qty: 2,
        ),
        OrderLineItem(
          product: Product(
            id: 'mock-2',
            name: '3-Burner Auto Hob',
            category: Category(id: 'mock-cat-2', name: 'Hobs'),
            price: 9500,
          ),
          qty: 1,
        ),
      ],
    ),
    KOrder(
      id: '#KUT-08190',
      entityName: 'Newtown Appliances',
      orderType: 'Distributor',
      date: 'Jul 12',
      status: OrderStatus.delivered,
      items: [
        OrderLineItem(
          product: Product(
            id: 'mock-3',
            name: 'Zeus Auto Clean',
            category: Category(id: 'mock-cat-1', name: 'Chimneys'),
            price: 24500,
          ),
          qty: 3,
        ),
        OrderLineItem(
          product: Product(
            id: 'mock-4',
            name: 'Built-in Oven 60L',
            category: Category(id: 'mock-cat-3', name: 'Ovens'),
            price: 21500,
          ),
          qty: 1,
        ),
      ],
    ),
    KOrder(
      id: '#KUT-08150',
      entityName: 'Baruipur Home Corner',
      orderType: 'Retailer',
      date: 'Jul 9',
      status: OrderStatus.confirmed,
      items: [
        OrderLineItem(
          product: Product(
            id: 'mock-5',
            name: 'Curvo 60cm',
            category: Category(id: 'mock-cat-1', name: 'Chimneys'),
            price: 14250,
          ),
          qty: 2,
        ),
      ],
    ),
  ];
}
