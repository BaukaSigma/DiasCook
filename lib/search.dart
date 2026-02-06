import 'package:flutter/material.dart';
import 'package:first/api.dart'; 
import 'recipe_detail.dart'; // Рецепт бетін ашу үшін

// Категориялар тізімі
const List<String> _categories = [
  'Барлық санаттар',
  'Бірінші тағамдар',
  'Екінші тағамдар',
  'Десерттер',
  'Салаттар',
  'Ұлттық',
];

class SearchScreen extends StatefulWidget {
  final String userId;
  final String? initialCategory;
  final String? initialQuery;

  const SearchScreen({
    super.key,
    required this.userId,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Future<List<dynamic>>? _productsFuture;
  List<dynamic> _allProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'Барлық санаттар';
  late final TextEditingController _searchController;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    final initialCategory = widget.initialCategory;
    if (initialCategory != null && _categories.contains(initialCategory)) {
      _selectedCategory = initialCategory;
    }
    _searchQuery = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    _productsFuture = _loadProducts();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (widget.userId == 'guest') return;
    try {
      final favs = await ApiService.getFavorites(widget.userId);
      setState(() {
        _favoriteIds = favs
            .map((item) => item['_id']?.toString())
            .where((id) => id != null)
            .cast<String>()
            .toSet();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      _allProducts = products;
      return products;
    } catch (e) {
      throw Exception('Жүктеу қатесі: $e');
    }
  }

  List<dynamic> _getFilteredProducts() {
    Iterable<dynamic> filtered = _allProducts.where((product) {
      if (_selectedCategory == 'Барлық санаттар') return true;
      return (product['category'] as String?) == _selectedCategory;
    });

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final title = (product['title'] as String?)?.toLowerCase() ?? '';
        return title.contains(_searchQuery.toLowerCase());
      });
    }
    return filtered.toList();
  }

  // Лайк басу логикасы
  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    try {
      if (widget.userId == 'guest') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Таңдаулыға қосу үшін кіріңіз.')),
        );
        return;
      }
      final productId = product['_id']?.toString();
      if (productId == null) return;
      final result = await ApiService.toggleFavorite(widget.userId, productId);
      final isLiked = result['isLiked'] == true;
      setState(() {
        if (isLiked) {
          _favoriteIds.add(productId);
        } else {
          _favoriteIds.remove(productId);
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Сақталды')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Қате: ${snapshot.error}'));
        }

        final filteredProducts = _getFilteredProducts();

        return Column(
          children: [
            // 1. Іздеу өрісі
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Рецепт атауын жазыңыз...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
            ),
            
            // 2. Категория таңдау
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
            ),

            const SizedBox(height: 10),

            // 3. Тізім
            Expanded(
              child: filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _buildSearchCard(product);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchCard(Map<String, dynamic> product) {
    final description = (product['description'] ?? '').toString();
    final category = (product['category'] ?? '').toString();
    final subtitleText = description.isNotEmpty ? description : category;
    final productId = product['_id']?.toString();
    final isFavorite = productId != null && _favoriteIds.contains(productId);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                product: product,
                userId: widget.userId,
              ),
            ),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (product['imageUrl'] ?? 'assets/images/soup.jpg')
                  .toString()
                  .startsWith('http')
              ? Image.network(
                  product['imageUrl'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  product['imageUrl'] ?? 'assets/images/soup.jpg',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
        ),
        title: Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitleText.isNotEmpty ? subtitleText : 'Сипаттама көрсетілмеген',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        // КОРЗИНКА ОРНЫНА ЛАЙК ИКОНКАСЫ
        trailing: IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          onPressed: () => _toggleFavorite(product),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Нәтиже табылмады', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}
