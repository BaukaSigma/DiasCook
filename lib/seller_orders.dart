import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'localization.dart';
import 'firestore_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerOrdersScreen extends StatefulWidget {
  final String sellerId;
  const SellerOrdersScreen({super.key, required this.sellerId});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
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
      final orders = await ApiService.getSellerOrders(widget.sellerId);
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
      case 'delivering':
        return lang == 'kz' ? 'Жеткізілуде' : (lang == 'en' ? 'Delivering' : 'Доставляется');
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
      case 'delivering':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Loc.lang.value == 'kz' ? 'Тапсырыс күйі жаңартылды' : (Loc.lang.value == 'en' ? 'Order status updated' : 'Статус заказа обновлен')),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(Loc.tr('seller_orders')),
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
                            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              lang == 'kz' ? 'Тапсырыстар табылмады' : (lang == 'en' ? 'No new orders' : 'Новых заказов нет'),
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
                          final orderId = order['orderId'];
                          final status = order['orderStatus'] ?? 'accepted';
                          final items = order['items'] as List? ?? [];
                          final deliveryType = order['deliveryType'] ?? 'pickup';

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
                                        '#${orderId.toString().substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        _formatDate(order['createdAt']),
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  
                                  Text(
                                    '${lang == 'kz' ? 'Тұтынушы' : (lang == 'en' ? 'Customer' : 'Покупатель')}: ${order['userName'] ?? 'N/A'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lang == 'kz' ? 'Телефон' : (lang == 'en' ? 'Phone' : 'Телефон')}: ${order['userPhone'] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${Loc.tr('getting_method')}: ${deliveryType == 'pickup' ? Loc.tr('pickup') : Loc.tr('delivery')}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (deliveryType == 'external_delivery') ...[
                                    const SizedBox(height: 4),
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
                                      '${lang == 'kz' ? 'Мекенжай' : (lang == 'en' ? 'Address' : 'Адрес')}: ${order['deliveryAddress'] ?? ''}',
                                      style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  
                                  const Divider(height: 20),
                                  
                                  ...items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: FirestoreImage(imageUrl: item['imageUrl'] ?? ''),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                           Expanded(
                                            child: Builder(
                                              builder: (context) {
                                                String itemTitle = '';
                                                if (lang == 'kz') {
                                                  itemTitle = item['titleKz'] ?? '';
                                                } else if (lang == 'ru') {
                                                  itemTitle = item['titleRu'] ?? '';
                                                } else if (lang == 'en') {
                                                  itemTitle = item['titleEn'] ?? '';
                                                }
                                                if (itemTitle.isEmpty) {
                                                  itemTitle = item['title'] ?? '';
                                                }
                                                return Text(
                                                  itemTitle,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                );
                                              }
                                            ),
                                          ),
                                          Text(
                                            '${item['quantity']} × ${item['price']} ₸',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  
                                  const Divider(height: 20),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        lang == 'kz' ? 'Сомасы' : (lang == 'en' ? 'Total' : 'Сумма к оплате'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        '${order['totalPrice']?.toInt() ?? 0} ₸',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    children: [
                                      Text(
                                        '${lang == 'kz' ? 'Ағымдағы күйі' : (lang == 'en' ? 'Current status' : 'Текущий статус')}: ',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(status, lang),
                                          style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  Text(
                                    lang == 'kz' ? 'Күйді өзгерту:' : (lang == 'en' ? 'Change status to:' : 'Изменить статус на:'),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                         _buildStatusButton('accepted', Loc.lang.value == 'en' ? 'Accepted' : 'Принят', Colors.orange, status, orderId),
                                         const SizedBox(width: 8),
                                         _buildStatusButton('cooking', Loc.lang.value == 'en' ? 'Cooking' : 'Готовится', Colors.amber.shade700, status, orderId),
                                         const SizedBox(width: 8),
                                         _buildStatusButton('ready', Loc.lang.value == 'en' ? 'Ready' : 'Готов', Colors.blue, status, orderId),
                                         if (deliveryType == 'external_delivery') ...[
                                           const SizedBox(width: 8),
                                           _buildStatusButton('delivering', Loc.lang.value == 'en' ? 'Delivering' : 'Доставляется', Colors.purple, status, orderId),
                                         ],
                                         const SizedBox(width: 8),
                                         _buildStatusButton('completed', Loc.lang.value == 'en' ? 'Completed' : 'Завершён', Colors.green, status, orderId),
                                         const SizedBox(width: 8),
                                         _buildStatusButton('cancelled', Loc.lang.value == 'en' ? 'Cancelled' : 'Отменён', Colors.red, status, orderId),
                                      ],
                                    ),
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

  Widget _buildStatusButton(String targetStatus, String label, Color color, String currentStatus, String orderId) {
    final bool isSelected = currentStatus == targetStatus;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        backgroundColor: isSelected ? color.withOpacity(0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: isSelected ? null : () => _updateStatus(orderId, targetStatus),
      child: Text(
        Loc.lang.value == 'kz'
            ? _getStatusText(targetStatus, 'kz')
            : label,
        style: TextStyle(
          color: isSelected ? color : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
