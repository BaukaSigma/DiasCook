import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart';
import 'login.dart';
import 'product_detail.dart';
import 'localization.dart';
import 'user_orders.dart';

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
    return p.toInt();
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

    // Fetch user profile to get default address
    String defaultAddress = '';
    try {
      final profile = await ApiService.getUserProfile(widget.userId);
      defaultAddress = profile['deliveryAddress'] ?? profile['address'] ?? '';
    } catch (_) {}

    final addressController = TextEditingController(text: defaultAddress);
    String deliveryType = 'pickup'; // pickup or external_delivery
    String paymentMethod = 'Card'; // Card or Cash
    
    final formKey = GlobalKey<FormState>();
    final cardNoController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    final bool? completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Loc.lang.value == 'kz' ? 'Тапсырысты рәсімдеу' : 'Оформление заказа',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      
                      // Delivery Type Selection
                      Text(
                        Loc.lang.value == 'kz' ? 'Алу түрі' : 'Способ получения',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text(Loc.lang.value == 'kz' ? 'Самовывоз' : 'Самовывоз')),
                              selected: deliveryType == 'pickup',
                              selectedColor: Colors.amber.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => deliveryType = 'pickup');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text(Loc.lang.value == 'kz' ? 'Доставка' : 'Доставка')),
                              selected: deliveryType == 'external_delivery',
                              selectedColor: Colors.amber.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => deliveryType = 'external_delivery');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Delivery Info Text / Address Input
                      if (deliveryType == 'pickup')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store, color: Colors.green.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  Loc.lang.value == 'kz' 
                                      ? 'Тапсырысты өзіңіз алып кете аласыз.' 
                                      : 'Вы можете забрать заказ самостоятельно.',
                                  style: TextStyle(color: Colors.green.shade800),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, color: Colors.blue.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  Loc.lang.value == 'kz' 
                                      ? 'Жеткізу сыртқы қызмет арқылы жүзеге асырылады.' 
                                      : 'Доставка осуществляется сторонними службами.',
                                  style: TextStyle(color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: Loc.tr('delivery_addr'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return Loc.lang.value == 'kz' ? 'Мекенжайды енгізіңіз' : 'Введите адрес доставки';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      
                      // Payment Method Selection
                      Text(
                        Loc.lang.value == 'kz' ? 'Төлем түрі' : 'Способ оплаты',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text(Loc.lang.value == 'kz' ? 'Карта' : 'Картой')),
                              selected: paymentMethod == 'Card',
                              selectedColor: Colors.amber.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => paymentMethod = 'Card');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text(Loc.lang.value == 'kz' ? 'Қолма-қол' : 'Наличными')),
                              selected: paymentMethod == 'Cash',
                              selectedColor: Colors.amber.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => paymentMethod = 'Cash');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Card details if selected
                      if (paymentMethod == 'Card') ...[
                        TextFormField(
                          controller: cardNoController,
                          decoration: InputDecoration(
                            labelText: Loc.tr('card_number'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 19,
                          inputFormatters: [CardNumberInputFormatter()],
                          validator: (value) {
                            if (value == null || value.trim().length < 19) {
                              return Loc.tr('invalid_card_no');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: expiryController,
                                decoration: InputDecoration(
                                  labelText: Loc.tr('expiry'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.date_range),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                inputFormatters: [CardExpiryInputFormatter()],
                                validator: (value) {
                                  if (value == null || value.length < 5) {
                                    return Loc.tr('invalid_expiry');
                                  }
                                  final parts = value.split('/');
                                  if (parts.length != 2) return Loc.tr('invalid_expiry');
                                  final month = int.tryParse(parts[0]);
                                  final year = int.tryParse(parts[1]);
                                  if (month == null || month < 1 || month > 12) {
                                    return Loc.tr('invalid_month');
                                  }
                                  if (year == null || year < 26) {
                                    return Loc.lang.value == 'kz' ? 'Жыл қате (минумы 26)' : 'Год неверный (минимум 26)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: cvvController,
                                decoration: InputDecoration(
                                  labelText: Loc.tr('cvv'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.length < 3) {
                                    return Loc.tr('invalid_cvv');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context, true);
                            }
                          },
                          child: Text(
                            paymentMethod == 'Card' 
                                ? (Loc.lang.value == 'kz' ? 'Төлеу' : 'Оплатить')
                                : (Loc.lang.value == 'kz' ? 'Тапсырыс беру' : 'Оформить заказ'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (completed != true) return;

    try {
      setState(() => _isLoading = true);
      final res = await ApiService.checkoutCart(
        widget.userId,
        deliveryType,
        deliveryType == 'pickup' ? 'Самовывоз' : addressController.text.trim(),
        paymentMethod,
        cardNoController.text.trim(),
      );

      if (mounted) {
        if (res['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                paymentMethod == 'Card' 
                    ? Loc.tr('success_payment') 
                    : Loc.tr('cash_payment_msg'),
              ),
              backgroundColor: Colors.green,
            ),
          );
          fetchCart();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserOrdersScreen(userId: widget.userId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${Loc.tr('error')}: ${res['error']}')),
          );
        }
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

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var cleanText = text.replaceAll(RegExp(r'\D'), '');
    var formatted = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(cleanText[i]);
    }
    var string = formatted.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var cleanText = text.replaceAll(RegExp(r'\D'), '');
    var formatted = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && i % 2 == 0) {
        formatted.write('/');
      }
      formatted.write(cleanText[i]);
    }
    var string = formatted.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

