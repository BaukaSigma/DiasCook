import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'localization.dart';
import 'firestore_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserOrdersScreen extends StatefulWidget {
  final String userId;
  const UserOrdersScreen({super.key, required this.userId});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final orders = await ApiService.getUserOrders(widget.userId);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else {
      dt = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    }
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _getStatusText(String status, String lang) {
    switch (status) {
      case 'accepted':
        return lang == 'kz' ? 'Тапсырыс қабылданды' : (lang == 'en' ? 'Order accepted' : 'Заказ принят');
      case 'cooking':
        return lang == 'kz' ? 'Дайындалуда' : (lang == 'en' ? 'Cooking' : 'Готовится');
      case 'ready':
        return lang == 'kz' ? 'Дайын' : (lang == 'en' ? 'Ready' : 'Готов');
      case 'completed':
        return lang == 'kz' ? 'Аяқталды' : (lang == 'en' ? 'Completed' : 'Завершён');
      case 'cancelled':
        return lang == 'kz' ? 'Бас тартылды' : (lang == 'en' ? 'Cancelled' : 'Отменён');
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.orange;
      case 'cooking':
        return Colors.amber.shade700;
      case 'ready':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(Loc.tr('order_history')),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: _loadOrders,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              lang == 'kz' ? 'Тапсырыстар табылмады' : (lang == 'en' ? 'No orders yet' : 'Заказов пока нет'),
                              style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final status = order['orderStatus'] ?? 'accepted';
                          final deliveryType = order['deliveryType'] ?? 'pickup';
                          final items = order['items'] as List? ?? [];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${lang == 'kz' ? 'Тапсырыс' : (lang == 'en' ? 'Order' : 'Заказ')} #${order['orderId'].toString().substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _getStatusColor(status)),
                                        ),
                                        child: Text(
                                          _getStatusText(status, lang),
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${lang == 'kz' ? 'Күні' : (lang == 'en' ? 'Date' : 'Дата')}: ${_formatDate(order['createdAt'])}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                  const Divider(height: 24),
                                  ...items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: FirestoreImage(imageUrl: item['imageUrl'] ?? ''),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item['title'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            ),
                                          ),
                                          Text(
                                            '${item['quantity']} × ${item['price']} ₸',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        Loc.tr('getting_method'),
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                      ),
                                      Text(
                                        deliveryType == 'pickup' ? Loc.tr('pickup') : Loc.tr('delivery'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (deliveryType == 'pickup')
                                    Text(
                                      Loc.tr('pickup_note'),
                                      style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                                    )
                                  else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        Loc.tr('delivery_in_progress'),
                                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Loc.tr('delivery_note'),
                                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${lang == 'kz' ? 'Мекенжай' : (lang == 'en' ? 'Address' : 'Адрес')}: ${order['deliveryAddress'] ?? ''}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        lang == 'kz' ? 'Жалпы сомасы' : (lang == 'en' ? 'Total' : 'Общая сумма'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        '${order['totalPrice']?.toInt() ?? 0} ₸',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${Loc.tr('payment_method')}: ${order['paymentMethod'] == 'Card' ? (lang == 'kz' ? 'Карта (Kaspi)' : (lang == 'en' ? 'Card (Kaspi)' : 'Картой (Kaspi)')) : Loc.tr('cash')} - ${order['paymentStatus'] == 'confirmed' ? (lang == 'kz' ? 'Расталды' : (lang == 'en' ? 'Confirmed' : 'Подтверждена')) : (lang == 'kz' ? 'Күтілуде' : (lang == 'en' ? 'Pending' : 'В ожидании'))}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        );
      },
    );
  }
}
