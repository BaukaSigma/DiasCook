import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart';
import 'login.dart';
import 'product_detail.dart';
import 'localization.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  List<dynamic> _cartItems = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  int _roundPrice(dynamic price) {
    final p = (price ?? 0).toDouble();
    return (p / 100).round() * 100;
  }

  Future<void> fetchCart() async {
    if (widget.userId == 'guest') return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await ApiService.getCart(widget.userId);
      if (mounted) {
        setState(() {
          _cartItems = res['items'] ?? [];
          _total = (res['totalAmount'] ?? res['total'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    if (newQuantity < 1) return;
    try {
      await ApiService.updateCartQuantity(widget.userId, productId, newQuantity);
      fetchCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String productId) async {
    try {
      await ApiService.removeFromCart(widget.userId, productId);
      fetchCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Loc.tr('item_removed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    }
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;

    final String? method = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Loc.tr('payment_method')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: Text(Loc.tr('cash')),
              onTap: () => Navigator.pop(context, 'cash'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: Text(Loc.tr('card')),
              onTap: () => Navigator.pop(context, 'card'),
            ),
          ],
        ),
      ),
    );

    if (method == null) return;

    if (method == 'card') {
      final bool? paid = await _showCardPaymentDialog();
      if (paid != true) return;
    }

    try {
      setState(() => _isLoading = true);
      await ApiService.checkoutCart(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(method == 'card' ? Loc.tr('success_payment') : Loc.tr('cash_payment_msg')), backgroundColor: Colors.green),
        );
        fetchCart();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showCardPaymentDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Loc.tr('card')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: Loc.tr('card_number')),
              keyboardType: TextInputType.number,
              maxLength: 16,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(
                  decoration: InputDecoration(labelText: Loc.tr('expiry')),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  decoration: InputDecoration(labelText: Loc.tr('cvv')),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                )),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Loc.tr('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(Loc.tr('save'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        if (widget.userId == 'guest') {
          return _buildGuestContent();
        }

        return Scaffold(
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
                  ? Center(child: Text(Loc.tr('cart_empty'), style: const TextStyle(fontSize: 18, color: Colors.grey)))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              final product = item['productId'];
                              if (product == null) return const SizedBox.shrink();

                              String title = '';
                              if (lang == 'kz') title = product['titleKz'] ?? '';
                              else if (lang == 'ru') title = product['titleRu'] ?? '';
                              else if (lang == 'en') title = product['titleEn'] ?? '';
                              if (title.isEmpty) title = product['title'] ?? '';

                              final imageUrl = product['imageUrl'] ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imageUrl.startsWith('http')
                                        ? Image.network(
                                            imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(Icons.fastfood, size: 50),
                                          )
                                        : const Icon(Icons.fastfood, size: 50),
                                  ),
                                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${_roundPrice(product['price'])} ₸ x ${item['quantity']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQuantity(product['_id'], item['quantity'] - 1)),
                                      Text('${item['quantity']}'),
                                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQuantity(product['_id'], item['quantity'] + 1)),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(product['_id'])),
                                    ],
                                  ),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product, userId: widget.userId))),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(Loc.tr('total'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                                  Text('${_roundPrice(_total)} ₸', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: _checkout,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                                child: Text(Loc.tr('checkout_button'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildGuestContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(Loc.tr('guest'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(Loc.tr('guest_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: Text(Loc.tr('login')),
            ),
          ],
        ),
      ),
    );
  }
}
