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
        return lang == 'kz' ? 'Тапсырыс қабылданды' : 'Заказ принят';
      case 'cooking':
        return lang == 'kz' ? 'Дайындалуда' : 'Готовится';
      case 'ready':
        return lang == 'kz' ? 'Дайын' : 'Готов';
      case 'completed':
        return lang == 'kz' ? 'Аяқталды' : 'Завершён';
      case 'cancelled':
        return lang == 'kz' ? 'Бас тартылды' : 'Отменён';
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

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Loc.lang.value == 'kz' ? 'Тапсырыс күйі жаңартылды' : 'Статус заказа обновлен'),
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
            title: Text(lang == 'kz' ? 'Сатушы тапсырыстары' : 'Управление заказами (Продавец)'),
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
                              lang == 'kz' ? 'Тапсырыстар табылмады' : 'Новых заказов нет',
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
                                    '${lang == 'kz' ? 'Тұтынушы' : 'Покупатель'}: ${order['userName'] ?? 'N/A'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lang == 'kz' ? 'Телефон' : 'Телефон'}: ${order['userPhone'] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lang == 'kz' ? 'Алу түрі' : 'Получение'}: ${deliveryType == 'pickup' ? (lang == 'kz' ? 'Өзім алып кету' : 'Самовывоз') : (lang == 'kz' ? 'Жеткізу' : 'Доставка')}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (deliveryType == 'external_delivery') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${lang == 'kz' ? 'Мекенжай' : 'Адрес'}: ${order['deliveryAddress'] ?? ''}',
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
                                            child: Text(
                                              item['title'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                                        lang == 'kz' ? 'Сомасы' : 'Сумма к оплате',
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
                                        '${lang == 'kz' ? 'Ағымдағы күйі' : 'Текущий статус'}: ',
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
                                    lang == 'kz' ? 'Күйді өзгерту:' : 'Изменить статус на:',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildStatusButton('accepted', 'Принят', Colors.orange, status, orderId),
                                        const SizedBox(width: 8),
                                        _buildStatusButton('cooking', 'Готовится', Colors.amber.shade700, status, orderId),
                                        const SizedBox(width: 8),
                                        _buildStatusButton('ready', 'Готов', Colors.blue, status, orderId),
                                        const SizedBox(width: 8),
                                        _buildStatusButton('completed', 'Завершён', Colors.green, status, orderId),
                                        const SizedBox(width: 8),
                                        _buildStatusButton('cancelled', 'Отменён', Colors.red, status, orderId),
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
