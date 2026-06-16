import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'localization.dart';
import 'product_detail.dart';
import 'firestore_image.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String? sellerName;
  final String? sellerLogo;
  final String? sellerInstagram;
  final String userId;
  final String? address;
  final String? phone;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    this.sellerName,
    this.sellerLogo,
    this.sellerInstagram,
    required this.userId,
    this.address,
    this.phone,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSellerRating();
  }

  Future<void> _loadSellerRating() async {
    try {
      final r = await ApiService.getSellerRating(widget.sellerId);
      if (mounted) {
        setState(() {
          _rating = r;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    try {
      final all = await ApiService.getProducts();
      final filtered = all.where((p) => p['sellerId'] == widget.sellerId).toList();
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
    final name = widget.sellerName ?? Loc.tr('seller_label');
    final logo = widget.sellerLogo ?? '';
    final instagram = widget.sellerInstagram ?? '';
    final phone = widget.phone ?? '+7 701 123 4567';

    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(Loc.tr('seller_profile')),
            elevation: 0,
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
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
                        child: logo.startsWith('assets/')
                            ? Image.asset(logo, width: 100, height: 100, fit: BoxFit.cover)
                            : logo.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: logo,
                                    width: 100, height: 100, fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => _initials(name),
                                  )
                                : _initials(name),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.yellow, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            _rating > 0 ? _rating.toStringAsFixed(1) : '5.0',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
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
                      if (instagram.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.camera_alt, color: Colors.purple),
                          title: Text('@$instagram', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                        ),
                      ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.orange),
                        title: Text(widget.address == null || widget.address!.isEmpty ? Loc.tr('not_specified') : widget.address!),
                        subtitle: Text(Loc.tr('address'), style: const TextStyle(fontSize: 12)),
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
                             String pTitle = '';
                             if (lang == 'kz') {
                               pTitle = (p['titleKz'] ?? '').toString();
                             } else if (lang == 'ru') {
                               pTitle = (p['titleRu'] ?? '').toString();
                             } else if (lang == 'en') {
                               pTitle = (p['titleEn'] ?? '').toString();
                             }
                             if (pTitle.trim().isEmpty) {
                               pTitle = (p['title'] ?? '').toString();
                             }

                             return ListTile(
                               leading: SizedBox(
                                 width: 50, height: 50,
                                 child: ClipRRect(
                                   borderRadius: BorderRadius.circular(8),
                                   child: FirestoreImage(imageUrl: (p['imageUrl'] ?? '').toString(), width: 50, height: 50),
                                 ),
                               ),
                               title: Text(pTitle),
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
      },
    );
  }

  Widget _initials(String name) {
    return Container(
      width: 100, height: 100,
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
      ),
    );
  }
}
