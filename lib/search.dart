import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart';
import 'product_detail.dart';
import 'localization.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  List<dynamic> _allProducts = [];
  bool _isLoading = true;
  bool _isAISearch = false;

  final List<String> _categories = [
    'Таң ертеңгілік', 'Түскі ас', 'Кешкі ас', 'Тәттілер', 'Тағамдар', 'Алғашқы тағам', 'Гарнир', 'Сусындар', 'Басқа'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _selectedCategory = widget.initialCategory ?? '';
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final prods = await ApiService.getProducts();
      if (mounted) {
        setState(() {
          _allProducts = prods;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runAISearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isAISearch = true;
    });

    try {
      final result = await ApiService.searchProductsWithAI(query);
      if (mounted) {
        setState(() {
          _allProducts = result['results'] ?? result['products'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    }
  }

  List<dynamic> _getFilteredProducts(String lang) {
    if (_isAISearch) return _allProducts;

    return _allProducts.where((p) {
      final query = _searchController.text.toLowerCase();
      
      String title = (p['title'] ?? '').toString().toLowerCase();
      String titleKz = (p['titleKz'] ?? '').toString().toLowerCase();
      String titleRu = (p['titleRu'] ?? '').toString().toLowerCase();
      String titleEn = (p['titleEn'] ?? '').toString().toLowerCase();

      final matchesQuery = query.isEmpty || 
          title.contains(query) || 
          titleKz.contains(query) || 
          titleRu.contains(query) ||
          titleEn.contains(query);

      final cat = p['category']?.toString() ?? '';
      
      String localizedSelectedCat = _selectedCategory;
      if (localizedSelectedCat == Loc.tr('all_categories')) {
        localizedSelectedCat = '';
      }

      bool matchesCategory = true;
      if (localizedSelectedCat.isNotEmpty) {
        matchesCategory = (cat == localizedSelectedCat);
        if (!matchesCategory) {
          for (var c in _categories) {
             if (Loc.tr(_getCatKey(c)) == localizedSelectedCat) {
                matchesCategory = (cat == c);
                break;
             }
          }
        }
      }

      return matchesQuery && matchesCategory;
    }).toList();
  }

  String _getCatKey(String cat) {
    switch (cat) {
      case 'Таң ертеңгілік': return 'breakfast';
      case 'Түскі ас': return 'lunch';
      case 'Кешкі ас': return 'dinner';
      case 'Тәттілер': return 'desserts';
      case 'Тағамдар': return 'snacks';
      case 'Алғашқы тағам': return 'appetizer';
      case 'Гарнир': return 'side_dish';
      case 'Сусындар': return 'beverage';
      default: return 'other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        final filtered = _getFilteredProducts(lang);
        final displayCategories = [Loc.tr('all_categories'), ..._categories.map((c) => Loc.tr(_getCatKey(c)))];

        return Scaffold(
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _isAISearch = false),
                      decoration: InputDecoration(
                        hintText: Loc.tr('search'),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.auto_awesome, color: Colors.orange),
                          onPressed: _runAISearch,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayCategories.length,
                        itemBuilder: (context, index) {
                          final cat = displayCategories[index];
                          final isSelected = _selectedCategory == cat || (_selectedCategory.isEmpty && cat == Loc.tr('all_categories'));
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13)),
                              selected: isSelected,
                              onSelected: (v) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _isAISearch = false;
                                });
                              },
                              selectedColor: Colors.orange.shade900,
                              backgroundColor: Colors.white,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(Loc.tr('not_found'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                            ],
                          ))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              
                              String title = '';
                              if (lang == 'kz') title = p['titleKz'] ?? '';
                              else if (lang == 'ru') title = p['titleRu'] ?? '';
                              else if (lang == 'en') title = p['titleEn'] ?? '';
                              if (title.isEmpty) title = p['title'] ?? '';

                              final imageUrl = p['imageUrl'] ?? '';

                              return GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p, userId: widget.userId))),
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: imageUrl.startsWith('http')
                                            ? Image.network(
                                                imageUrl,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => const Icon(Icons.error, size: 50),
                                              )
                                            : const Icon(Icons.fastfood, size: 50),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text('${p['price']} ₸', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
            ],
          ),
        );
      },
    );
  }
}
