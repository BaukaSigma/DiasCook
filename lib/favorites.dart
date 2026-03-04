import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart';
import 'login.dart';
import 'product_detail.dart';

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
    setState(() {
      _favoritesFuture = ApiService.getFavorites(widget.userId);
    });
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
        const SnackBar(content: Text('Таңдаулыдан алынды.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          return Center(child: Text('Қате: ${snapshot.error}'));
        }

        final favorites = snapshot.data?.reversed.toList() ?? [];
        if (favorites.isEmpty) {
          return const _EmptyFavoritesState();
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = favorites[index] as Map<String, dynamic>;
              final imageUrl = item['imageUrl'] ?? 'assets/images/soup.jpg';
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.toString().startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl, 
                            width: 52, 
                            height: 52, 
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 52,
                              height: 52,
                              color: Colors.grey.shade200,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 52,
                              height: 52,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.error),
                            ),
                          )
                        : Image.asset(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  ),
                  title: Text(item['title'] ?? 'Атауы жоқ'),
                  subtitle: Text(
                    item['category'] ?? '',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                        onPressed: () async {
                          if (widget.userId == 'guest') {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Себетке қосу үшін кіріңіз.')));
                            return;
                          }
                          try {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Себетке қосылуда...'), duration: Duration(milliseconds: 500)));
                            await ApiService.addToCart(widget.userId, item['_id']);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Себетке қосылды!')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Қате: $e')));
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: item,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
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
            const Text(
              'Таңдаулыңыз бос',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Таңдаулыны пайдалану үшін алдымен кіріңіз.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Кіру'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Таңдаулыда ештеңе жоқ', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
