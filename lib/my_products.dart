import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'product_detail.dart';
import 'firestore_image.dart';

class MyProductsScreen extends StatefulWidget {
  final String userId;
  const MyProductsScreen({super.key, required this.userId});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final prods = await ApiService.getProductsByUserId(widget.userId);
    if (mounted) setState(() { _products = prods; _isLoading = false; });
  }

  Future<void> _delete(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Өшіру'),
        content: const Text('Бұл тағамды өшіргіңіз келе ме?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Жоқ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Иә', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService.deleteProduct(productId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Менің тағамдарым'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Сізде әлі тағам жоқ', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _products.length,
                    itemBuilder: (context, i) {
                      final p = _products[i] as Map<String, dynamic>;
                      final imageUrl = (p['imageUrl'] ?? 'assets/images/soup.jpg').toString();
                      final title = (p['title'] ?? p['titleKz'] ?? '').toString();
                      final price = p['price']?.toString() ?? '0';
                      final category = (p['category'] ?? '').toString();
                      final productId = p['_id']?.toString() ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: p, userId: widget.userId),
                          )),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80, height: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: FirestoreImage(imageUrl: imageUrl, width: 80, height: 80),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(category, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      Text('$price ₸', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: productId.isNotEmpty ? () => _delete(productId) : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
