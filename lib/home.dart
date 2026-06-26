import 'package:flutter/material.dart';
import 'package:first/api.dart'; 
import 'profile.dart'; 
import 'search.dart';
import 'favorites.dart';
import 'product_detail.dart'; 
import 'cart.dart';
import 'localization.dart';
import 'firestore_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.startIndex = 0,
    this.userId = 'guest', 
    this.initialSearchCategory,
    this.initialSearchQuery,
  });

  final int startIndex;
  final String userId;
  final String? initialSearchCategory;
  final String? initialSearchQuery;

  static void openTab(
    BuildContext context,
    int index, {
    String userId = 'guest',
    String? initialSearchCategory,
    String? initialSearchQuery,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          startIndex: index,
          userId: userId,
          initialSearchCategory: initialSearchCategory,
          initialSearchQuery: initialSearchQuery,
        ),
      ),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final GlobalKey<FavoritesScreenState> _favoritesKey = GlobalKey<FavoritesScreenState>();
  final GlobalKey<CartScreenState> _cartKey = GlobalKey<CartScreenState>();
  final GlobalKey<_RecommendedDishesState> _dishesKey = GlobalKey<_RecommendedDishesState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _dishesKey.currentState?.reload();
    }
    if (index == 2) {
      _favoritesKey.currentState?.refreshFavorites();
    }
    if (index == 3) {
      _cartKey.currentState?.fetchCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        final List<String> titles = <String>[
          Loc.tr('home'),
          Loc.tr('search'),
          Loc.tr('favorites'),
          Loc.tr('cart'),
          Loc.tr('profile'),
        ];

        final List<Widget> tabs = <Widget>[
          _HomeTab(userId: widget.userId, dishesKey: _dishesKey),
          SearchScreen(
            userId: widget.userId,
            initialCategory: widget.initialSearchCategory,
            initialQuery: widget.initialSearchQuery,
          ),
          FavoritesScreen(key: _favoritesKey, userId: widget.userId),
          CartScreen(key: _cartKey, userId: widget.userId),
          ProfileScreen(userId: widget.userId),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              ValueListenableBuilder<String>(
                valueListenable: Loc.lang,
                builder: (context, currentLang, _) {
                  return DropdownButton<String>(
                    value: currentLang,
                    dropdownColor: Colors.orange.shade800,
                    iconEnabledColor: Colors.white,
                    underline: Container(),
                    onChanged: (val) {
                      if (val != null) Loc.lang.value = val;
                    },
                    items: const [
                      DropdownMenuItem(value: 'kz', child: Text('ҚАЗ', style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: 'ru', child: Text('РУС', style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: 'en', child: Text('ENG', style: TextStyle(color: Colors.white, fontSize: 13))),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.orange.shade800,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: Loc.tr('home')),
              BottomNavigationBarItem(icon: const Icon(Icons.search), label: Loc.tr('search')),
              BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: Loc.tr('favorites')),
              BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart), label: Loc.tr('cart')),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: Loc.tr('profile')),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userId;
  final GlobalKey<_RecommendedDishesState>? dishesKey;
  const _HomeTab({super.key, required this.userId, this.dishesKey});

  List<Map<String, String>> get categories => [
    {'title': Loc.tr('all_categories'), 'path': 'assets/images/soup.jpg'},
    {'title': Loc.tr('breakfast'), 'path': 'assets/images/baursak.jpg'},
    {'title': Loc.tr('lunch'), 'path': 'assets/images/manty.jpg'},
    {'title': Loc.tr('dinner'), 'path': 'assets/images/kuirdak.jpg'},
    {'title': Loc.tr('desserts'), 'path': 'assets/images/dessert.jpg'},
    {'title': Loc.tr('side_dish'), 'path': 'assets/images/pasta.jpg'},
    {'title': Loc.tr('beverage'), 'path': 'assets/images/ceremony.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/images/soup.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.15),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Loc.tr('welcome_title'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Loc.tr('welcome_subtitle'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      HomeScreen.openTab(
                        context,
                        1,
                        userId: userId,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade700,
                    ),
                    child: Text(Loc.tr('search')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Title(Loc.tr('popular_categories')),
          const SizedBox(height: 12),
          SizedBox(
            height: 130, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _HorizontalCategory(
                  title: category['title'] ?? '',
                  assetPath: category['path'] ?? 'assets/images/soup.jpg',
                  onTap: () {
                    HomeScreen.openTab(
                      context,
                      1,
                      userId: userId,
                      initialSearchCategory: category['title'],
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          _Title(Loc.tr('for_you')),
          const SizedBox(height: 12),
          _RecommendedDishes(key: dishesKey, userId: userId),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _HorizontalCategory extends StatelessWidget {
  final String title;
  final String assetPath;
  final VoidCallback onTap;

  const _HorizontalCategory({
    super.key,
    required this.title, 
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(assetPath.replaceFirst('assets/assets/', 'assets/'), width: 70, height: 70, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedDishes extends StatefulWidget {
  final String userId;
  const _RecommendedDishes({super.key, required this.userId});

  @override
  State<_RecommendedDishes> createState() => _RecommendedDishesState();
}

class _RecommendedDishesState extends State<_RecommendedDishes> {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _products = [];
  Set<String> _favoriteIds = {};

  void reload() {
    _loadProducts();
    _loadFavorites();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavorites();
  }

  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final prods = await ApiService.getRecommendedProducts(widget.userId);
      if (mounted) setState(() { _products = prods; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  Future<void> _loadFavorites() async {
    if (widget.userId == 'guest') return;
    try {
      final favs = await ApiService.getFavorites(widget.userId);
      if (mounted) {
        setState(() {
          _favoriteIds = favs
              .map((item) => item['_id']?.toString())
              .where((id) => id != null)
              .cast<String>()
              .toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(BuildContext context, Map<String, dynamic> product) async {
    if (widget.userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Loc.tr('must_login'))),
      );
      return;
    }
    final productId = product['_id']?.toString();
    if (productId == null) return;
    try {
      final result = await ApiService.toggleFavorite(widget.userId, productId);
      final isLiked = result['isLiked'] == true;
      if (mounted) {
        setState(() {
          if (isLiked) { _favoriteIds.add(productId); }
          else { _favoriteIds.remove(productId); }
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? Loc.tr('saved'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Loc.tr('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return Center(
      child: Column(
        children: [
          Text(Loc.tr('error')),
          TextButton(onPressed: _loadProducts, child: Text(Loc.tr('home'))),
        ],
      ),
    );
    if (_products.isEmpty) return Center(child: Text(Loc.tr('not_found')));

    return RefreshIndicator(
      onRefresh: () async {
        await _loadProducts();
        await _loadFavorites();
      },
      child: Column(
        children: _products.map((product) {
          final productId = product['_id']?.toString();
          final isLiked = productId != null && _favoriteIds.contains(productId);
          return _ProductCard(
            product: product,
            userId: widget.userId,
            isFavorite: isLiked,
            onFavoritePressed: () => _toggleFavorite(context, product),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product; 
  final String userId;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;

  const _ProductCard({
    super.key,
    required this.product,
    required this.userId,
    required this.onFavoritePressed,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        String title = '';
        if (lang == 'kz') {
          title = (product['titleKz'] ?? '').toString();
        } else if (lang == 'ru') {
          title = (product['titleRu'] ?? '').toString();
        } else if (lang == 'en') {
          title = (product['titleEn'] ?? '').toString();
        }
        if (title.trim().isEmpty) {
          title = (product['title'] ?? 'Title').toString();
        }

        final imageUrl = (product['imageUrl'] ?? 'assets/images/soup.jpg').toString();
        final price = product['price'] ?? 0;
        final sellerName = product['sellerName']?.toString().isNotEmpty == true
            ? product['sellerName'].toString()
            : (product['sellerId']?.toString() ?? Loc.tr('seller_label'));
        final sellerLogo = product['sellerLogo']?.toString() ?? '';
        Widget logoWidget;
        if (sellerLogo.startsWith('assets/')) {
          logoWidget = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(sellerLogo, width: 36, height: 36, fit: BoxFit.cover),
          );
        } else if (sellerLogo.startsWith('http')) {
          logoWidget = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(sellerLogo, width: 36, height: 36, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(sellerName)),
          );
        } else if (sellerLogo.startsWith('firestore_image:') || sellerLogo.startsWith('data:')) {
          logoWidget = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: FirestoreImage(imageUrl: sellerLogo, width: 36, height: 36, fit: BoxFit.cover),
          );
        } else {
          logoWidget = _initials(sellerName);
        }

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product, userId: userId),
          )),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: FirestoreImage(imageUrl: imageUrl, height: 180, width: double.infinity),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            logoWidget,
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sellerName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
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
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.red, size: 22,
                                  ),
                                  onPressed: onFavoritePressed,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 36, height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.add_shopping_cart, color: Colors.orange, size: 22),
                                  onPressed: () async {
                                    if (userId == 'guest') {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('login_to_add'))));
                                      return;
                                    }
                                    try {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('adding_to_cart')), duration: const Duration(milliseconds: 500)));
                                      await ApiService.addToCart(userId, product['_id']);
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('added_to_cart'))));
                                    } catch (e) {
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${Loc.tr('error')}: $e')));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_roundPrice(price)} ₸',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
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

  int _roundPrice(dynamic price) {
    final p = (price ?? 0).toDouble();
    return p.toInt();
  }

  Widget _initials(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    const colors = [
      Color(0xFFE53935), Color(0xFF8E24AA), Color(0xFF1E88E5),
      Color(0xFF00897B), Color(0xFFF4511E), Color(0xFF6D4C41),
      Color(0xFF039BE5), Color(0xFF43A047), Color(0xFFD81B60),
    ];
    final color = colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
