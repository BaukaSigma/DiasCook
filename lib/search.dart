import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart'; 
import 'product_detail.dart';

// Тамақ категориялары
const List<String> _categories = [
  'Барлық санаттар',
  'Таң ертеңгілік',
  'Түскі ас',
  'Кешкі ас',
  'Тәттілер',
  'Тағамдар',
  'Алғашқы тағам',
  'Гарнир',
  'Сусындар',
  'Басқа',
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

  // ИИ үшін state
  bool _isAiSearch = false;
  bool _isAiLoading = false;
  String? _aiMessage;
  List<dynamic> _aiProducts = [];

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
      // Reverse so newest user additions are on top
      final reversedProducts = products.reversed.toList();
      _allProducts = reversedProducts;
      return reversedProducts;
    } catch (e) {
      throw Exception('Жүктеу қатесі: $e');
    }
  }

  Future<void> _performAiSearch() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сұрауды енгізіңіз')),
      );
      return;
    }

    setState(() {
      _isAiSearch = true;
      _isAiLoading = true;
      _aiMessage = null;
      _aiProducts = [];
    });

    try {
      final result = await ApiService.searchProductsWithAI(_searchController.text.trim());
      setState(() {
        _aiMessage = result['message'];
        _aiProducts = result['products'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiMessage = 'Қате: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAiLoading = false);
      }
    }
  }

  void _clearAiSearch() {
    setState(() {
      _isAiSearch = false;
      _searchController.clear();
      _searchQuery = '';
      _aiMessage = null;
      _aiProducts = [];
    });
  }

  List<dynamic> _getFilteredProducts() {
    if (_isAiSearch) {
      return _aiProducts;
    }

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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        if (_isAiSearch) return; // ИИ іздеу кезінде нақты уақытта жаңартпаймыз
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Тауар атауын жазыңыз...',
                        prefixIcon: const Icon(Icons.search, color: Colors.orange),
                        suffixIcon: _isAiSearch 
                            ? IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: _clearAiSearch) 
                            : null,
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
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isAiLoading ? null : _performAiSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: _isAiLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('✨ ИИ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
            
            if (_isAiSearch && _aiMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_aiMessage!, style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.w500)),
                    ),
                  ],
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
    final productId = product['_id']?.toString();
    final isFavorite = productId != null && _favoriteIds.contains(productId);
    final price = product['price'] ?? 0;
    final title = (product['title'] ?? '').toString();
    final imageUrl = (product['imageUrl'] ?? 'assets/images/soup.jpg').toString();
    final sellerName = product['sellerName']?.toString().isNotEmpty == true
        ? product['sellerName'].toString()
        : (product['sellerId']?.toString() ?? 'Сатушы');
    final sellerLogo = product['sellerLogo']?.toString() ?? '';

    Widget logoWidget;
    if (sellerLogo.startsWith('http')) {
      logoWidget = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(sellerLogo, width: 36, height: 36, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _initials(sellerName)),
      );
    } else {
      logoWidget = _initials(sellerName);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product, userId: widget.userId),
        ));
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Сурет
            imageUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 160, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
                    errorWidget: (_, __, ___) => Container(height: 160, color: Colors.grey.shade300, child: const Icon(Icons.error)),
                  )
                : Image.asset(imageUrl.replaceFirst('assets/assets/', 'assets/'), height: 160, width: double.infinity, fit: BoxFit.cover),
            // Тауар аты
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            // Лого + бренд солда, кнопкалар + баға оңда
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        logoWidget,
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(sellerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis, maxLines: 2),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 36, height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 22),
                              onPressed: () => _toggleFavorite(product),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 36, height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.add_shopping_cart, color: Colors.orange, size: 22),
                              onPressed: () async {
                                if (widget.userId == 'guest') {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Себетке қосу үшін кіріңіз.')));
                                  return;
                                }
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Себетке қосылуда...'), duration: Duration(milliseconds: 500)));
                                  await ApiService.addToCart(widget.userId, productId!);
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Себетке қосылды!')));
                                } catch (e) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Қате: $e')));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('$price ₸', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(18)),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
