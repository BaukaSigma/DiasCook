// cart.dart
import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'login.dart'; // Кіру экранына сілтеме үшін
import 'home.dart'; // Для навигации на главный экран

// Себет бетінің негізгі виджеті
class CartScreen extends StatefulWidget {
  final String userId;
  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Компонент-заглушка для пустой корзины
  Widget _buildEmptyCartStub(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Иконка корзины
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            // Заголовок
            const Text(
              'Ваша корзина пуста',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Описание
            Text(
              'Начните добавлять товары, чтобы сделать заказ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            // Кнопка для перехода на главный экран
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Переход на главную вкладку HomeScreen
                  HomeScreen.openTab(context, 0, userId: widget.userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Перейти к покупкам'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Заглушка, которая всегда показывает пустую корзину
  @override
  Widget build(BuildContext context) {
    return _buildEmptyCartStub(context);
  }
}