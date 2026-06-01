import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart';
import 'login.dart';
import 'product_detail.dart';
import 'firestore_image.dart';
import 'localization.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;
  const FavoritesScreen({super.key, required this.userId});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  Future<List<dynamic>>? _favoritesFuture;

  @override
  void initState() {
    super.initState();
    if (widget.userId != 'guest') {
      _favoritesFuture = ApiService.getFavorites(widget.userId);
    }
  }

  Future<void> _refresh() async {
    if (widget.userId == 'guest') return;
    if (mounted) {
      setState(() {
        _favoritesFuture = ApiService.getFavorites(widget.userId);
      });
    }
  }

  void refreshFavorites() {
    _refresh();
  }

  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    try {
      final productId = product['_id']?.toString();
      if (productId == null) return;
      await ApiService.toggleFavorite(widget.userId, productId);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Loc.tr('item_removed'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${Loc.tr('error')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        if (widget.userId == 'guest') {
          return _buildGuestContent(context);
        }

        return FutureBuilder<List<dynamic>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('${Loc.tr('error')}: ${snapshot.error}'));
            }

            final favorites = snapshot.data?.reversed.toList() ?? [];
            if (favorites.isEmpty) {
              return Center(child: Text(Loc.tr('favorites_empty'), style: const TextStyle(fontSize: 18, color: Colors.grey)));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = favorites[index] as Map<String, dynamic>;
                  final imageUrl = item['imageUrl'] ?? '';
                  
                  String title = '';
                  if (lang == 'kz') title = item['titleKz'] ?? '';
                  else if (lang == 'ru') title = item['titleRu'] ?? '';
                  else if (lang == 'en') title = item['titleEn'] ?? '';
                  if (title.isEmpty) title = item['title'] ?? '';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: SizedBox(
                        width: 52, height: 52,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FirestoreImage(imageUrl: imageUrl.toString(), width: 52, height: 52),
                        ),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${item['price']} ₸',
                        style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                            onPressed: () async {
                              if (widget.userId == 'guest') {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('login_to_add'))));
                                return;
                              }
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('adding_to_cart')), duration: const Duration(milliseconds: 500)));
                                await ApiService.addToCart(widget.userId, item['_id']);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('added_to_cart'))));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${Loc.tr('error')}: $e')));
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _toggleFavorite(item),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item, userId: widget.userId))),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(Loc.tr('guest'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
