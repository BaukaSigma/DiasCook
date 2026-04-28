import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'localization.dart';
import 'product_detail.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerLogo;
  final String userId;
  final String address;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLogo,
    required this.userId,
    required this.address,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  final double rating = 4.8; 
  final String phone = '+7 701 123 4567'; 

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final all = await ApiService.getProducts();
      final filtered = all.where((p) => p['sellerId'] == widget.sellerId || p['sellerName'] == widget.sellerName).toList();
      if (mounted) {
        setState(() {
          _products = filtered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Loc.tr('seller_profile')),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade700, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: widget.sellerLogo.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: widget.sellerLogo,
                            width: 100, height: 100, fit: BoxFit.cover,
                            errorWidget: (c, u, e) => _initials(),
                          )
                        : _initials(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.sellerName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 24),
                      const SizedBox(width: 4),
                      Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Loc.tr('contacts'), style: TextStyle(fontSize: 20, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.orange),
                    title: Text(phone),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.orange),
                    title: Text(widget.address.isEmpty ? Loc.tr('not_specified') : widget.address),
                  ),
                  const SizedBox(height: 24),

                  Text(Loc.tr('recipes'), style: TextStyle(fontSize: 20, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                  const Divider(),

                  if (_isLoading)
                     const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (_products.isEmpty)
                     Padding(
                       padding: const EdgeInsets.all(20.0),
                       child: Center(child: Text(Loc.tr('empty'), style: const TextStyle(color: Colors.grey))),
                     )
                  else
                     ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: _products.length,
                       itemBuilder: (context, index) {
                         final p = _products[index];
                         return ListTile(
                           leading: ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: CachedNetworkImage(
                               imageUrl: p['imageUrl'] ?? '',
                               width: 50, height: 50, fit: BoxFit.cover,
                               errorWidget: (c, u, e) => const Icon(Icons.fastfood, color: Colors.orange),
                             ),
                           ),
                           title: Text(p['title'] ?? ''),
                           subtitle: Text('${p['price']} ₸', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                           onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(userId: widget.userId, product: p)));
                           },
                         );
                       },
                     ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials() {
    return Container(
      width: 100, height: 100,
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        widget.sellerName.isNotEmpty ? widget.sellerName[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
      ),
    );
  }
}
