import 'package:first/admin/admin_panel.dart';
import 'package:first/localization.dart';
import 'package:first/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    Loc.lang.value = 'kz';
  });

  test('English locale has translated profile and order labels', () {
    Loc.lang.value = 'en';

    expect(Loc.tr('my_products'), 'My Dishes');
    expect(Loc.tr('order_history'), 'Order History');
    expect(Loc.tr('seller_orders'), 'Seller Orders');
    expect(Loc.tr('pickup'), 'Pickup');
    expect(Loc.tr('delivery'), 'Delivery');
    expect(Loc.tr('delivery_in_progress'), 'Delivery in progress');
  });

  testWidgets('product detail shows newline-separated ingredients as separate rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          userId: 'guest',
          product: {
            '_id': 'test_recipe',
            'title': 'Тест',
            'description': 'Описание',
            'imageUrl': 'assets/images/soup.jpg',
            'price': 1000,
            'sellerId': 'seller_1',
            'ingredients': 'Колбаски\nТоматный соус\nСливочная фасоль',
            'steps': <String>[],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Колбаски'), findsOneWidget);
    expect(find.text('Томатный соус'), findsOneWidget);
    expect(find.text('Сливочная фасоль'), findsOneWidget);
  });

  testWidgets('admin profile exposes profile editing action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminProfileTab(
            admin: {
              'userId': 'admin_1',
              'name': 'Admin',
              'surname': 'User',
              'email': 'admin@example.com',
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.text('Профильді өңдеу'), findsOneWidget);
  });
}
