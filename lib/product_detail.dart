import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart';
import 'seller_profile.dart';
import 'localization.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String userId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.userId = 'guest',
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  List<String> _normalizeList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = value.toString().trim();
    return text.isEmpty ? [] : [text];
  }

  List<String> _preferList(dynamic kz, dynamic ru, dynamic en, dynamic fallback) {
    final lang = Loc.lang.value;
    if (lang == 'kz') {
       final list = _normalizeList(kz);
       if (list.isNotEmpty) return list;
    } else if (lang == 'ru') {
       final list = _normalizeList(ru);
       if (list.isNotEmpty) return list;
    } else if (lang == 'en') {
       final list = _normalizeList(en);
       if (list.isNotEmpty) return list;
    }
    return _normalizeList(fallback);
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.2)),
    );
  }

  Widget _stepRow(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              index.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    if (widget.userId == 'guest') return;
    final productId = widget.product['_id']?.toString();
    if (productId == null) return;
    try {
      final favs = await ApiService.getFavorites(widget.userId);
      if (!mounted) return;
      setState(() {
        _isFavorite = favs.any((item) => item['_id']?.toString() == productId);
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (widget.userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Loc.tr('must_login'))),
      );
      return;
    }
    final productId = widget.product['_id']?.toString();
    if (productId == null) return;
    setState(() => _favoriteLoading = true);
    try {
      final result = await ApiService.toggleFavorite(widget.userId, productId);
      final isLiked = result['isLiked'] == true;
      if (!mounted) return;
      setState(() => _isFavorite = isLiked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? Loc.tr('saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${Loc.tr('error')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _favoriteLoading = false);
      }
    }
  }

  Widget _sellerInitials(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        String title = '';
        if (lang == 'kz') {
          title = (widget.product['titleKz'] ?? '').toString();
        } else if (lang == 'ru') {
          title = (widget.product['titleRu'] ?? '').toString();
        } else if (lang == 'en') {
          title = (widget.product['titleEn'] ?? '').toString();
        }
        if (title.trim().isEmpty) {
          title = (widget.product['title'] ?? 'Title').toString();
        }
        
        final String imageUrl = widget.product['imageUrl'] ?? 'assets/images/soup.jpg';
        
        String description = '';
        if (lang == 'kz') {
          description = (widget.product['descriptionKz'] ?? '').toString();
        } else if (lang == 'ru') {
          description = (widget.product['descriptionRu'] ?? '').toString();
        } else if (lang == 'en') {
          description = (widget.product['descriptionEn'] ?? '').toString();
        }
        if (description.trim().isEmpty) {
          description = (widget.product['description'] ?? '').toString();
        }

        final ingredients = _preferList(
          widget.product['ingredientsKz'],
          widget.product['ingredientsRu'],
          widget.product['ingredientsEn'],
          widget.product['ingredients']
        );
        final steps = _preferList(
          widget.product['stepsKz'],
          widget.product['stepsRu'],
          widget.product['stepsEn'],
          widget.product['steps']
        );

        final sellerName = widget.product['sellerName']?.toString() ?? Loc.tr('seller_label');
        final sellerLogo = widget.product['sellerLogo']?.toString() ?? '';
        final instagram = widget.product['sellerInstagram']?.toString() ?? '';
        final phone = widget.product['sellerPhone']?.toString() ?? '+7 (701) 123-45-67';
        final fullAddress = widget.product['fullAddress']?.toString() ?? widget.product['location']?.toString() ?? Loc.tr('not_specified');

        return Scaffold(
          backgroundColor: const Color(0xFFFDF7F2),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.orange.shade700,
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.error, size: 50)),
                          ),
                        )
                      : Image.asset(imageUrl.replaceFirst('assets/assets/', 'assets/'), fit: BoxFit.cover),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: _favoriteLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                        onPressed: _favoriteLoading ? null : _toggleFavorite,
                      ),
                    ),
                  ),
                ],
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${widget.product['price'] ?? 0} \u20B8',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      if (description.isNotEmpty)
                        _sectionCard(
                          icon: Icons.description_outlined,
                          title: Loc.tr('description_label'),
                          child: Text(description, style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5)),
                        ),

                      if (ingredients.isNotEmpty)
                        _sectionCard(
                          icon: Icons.shopping_basket_outlined,
                          title: Loc.tr('ingredients_label'),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ingredients.map(_infoPill).toList(),
                          ),
                        ),

                      if (steps.isNotEmpty)
                        _sectionCard(
                          icon: Icons.restaurant_menu_outlined,
                          title: Loc.tr('steps_label'),
                          child: Column(
                            children: [
                              for (int i = 0; i < steps.length; i++) _stepRow(i + 1, steps[i]),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: () {
                           if (widget.product['sellerId'] != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => SellerProfileScreen(
                                  sellerId: widget.product['sellerId'], 
                                  userId: widget.userId,
                                  sellerName: sellerName,
                                  sellerLogo: sellerLogo,
                                  sellerInstagram: instagram,
                                  address: fullAddress,
                                  phone: phone,
                                ),
                              ));
                           }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Row(
                            children: [
                              sellerLogo.startsWith('http')
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(sellerLogo, width: 48, height: 48, fit: BoxFit.cover, 
                                        errorBuilder: (_,__,___) => _sellerInitials(sellerName)),
                                    )
                                  : _sellerInitials(sellerName),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(Loc.tr('seller_label'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    Text(sellerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(fullAddress, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.orange),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (widget.userId == 'guest') {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('login_to_add'))));
                        return;
                      }
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('adding_to_cart')), duration: const Duration(milliseconds: 500)));
                        await ApiService.addToCart(widget.userId, widget.product['_id']);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('added_to_cart'))));
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${Loc.tr('error')}: $e')));
                      }
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(Loc.tr('add_to_cart')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showContactDialog(context, sellerName, sellerLogo, instagram, phone, fullAddress),
                    icon: const Icon(Icons.chat_bubble),
                    label: Text(Loc.tr('contact_seller')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContactDialog(BuildContext context, String name, String logo, String instagram, String phone, String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text(Loc.tr('contact_seller'), style: const TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: logo.startsWith('http') ? NetworkImage(logo) : null,
              child: !logo.startsWith('http') ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(phone, style: TextStyle(fontSize: 18, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            if (instagram.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text('@$instagram', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.purple)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}
