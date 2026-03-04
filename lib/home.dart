// home.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart'; 
import 'profile.dart'; 
import 'search.dart';
import 'favorites.dart';
import 'product_detail.dart'; 
import 'cart.dart';

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

  static const _titles = <String>[
    '\u0411\u0430\u0441\u0442\u044B',
    '\u0406\u0437\u0434\u0435\u0443',
    '\u04B0\u043D\u0430\u0439\u0434\u044B',
    '\u0421\u0435\u0431\u0435\u0442',
    '\u041F\u0430\u0440\u0430\u049B\u0448\u0430',
  ];

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;

    _tabs = <Widget>[
      _HomeTab(userId: widget.userId),
      SearchScreen(
        userId: widget.userId,
        initialCategory: widget.initialSearchCategory,
        initialQuery: widget.initialSearchQuery,
      ),
      FavoritesScreen(key: _favoritesKey, userId: widget.userId),
      CartScreen(key: _cartKey, userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  // РќР°РІРёРіР°С†РёСЏ Р»РѕРіРёРєР°СЃС‹ (У©Р·РіРµСЂС–СЃСЃС–Р· Т›Р°Р»Р°РґС‹, Р±С–СЂР°Т› РёРЅРґРµРєСЃ РµРЅРґС– Р¶Р°ТЈР° Р±РµС‚РєРµ СЃС–Р»С‚РµР№РґС–)
  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    if (index == 2) {
      _favoritesKey.currentState?.refreshFavorites();
    }
    if (index == 3) {
      _cartKey.currentState?.fetchCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '\u0411\u0430\u0441\u0442\u044B'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '\u0406\u0437\u0434\u0435\u0443'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '\u04B0\u043D\u0430\u0439\u0434\u044B'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '\u0421\u0435\u0431\u0435\u0442'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '\u041F\u0430\u0440\u0430\u049B\u0448\u0430'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userId;
  const _HomeTab({super.key, required this.userId});

  static const List<Map<String, String>> categories = [
    {'title': 'Барлық санаттар', 'path': 'assets/images/soup.jpg'},
    {'title': 'Таң ертеңгілік', 'path': 'assets/images/baursak.jpg'},
    {'title': 'Түскі ас', 'path': 'assets/images/manty.jpg'},
    {'title': 'Кешкі ас', 'path': 'assets/images/kuirdak.jpg'},
    {'title': 'Тәттілер', 'path': 'assets/images/dessert.jpg'},
    {'title': 'Тағамдар', 'path': 'assets/images/shrimp_pasta.jpg'},
    {'title': 'Алғашқы тағам', 'path': 'assets/images/borsh.jpg'},
    {'title': 'Гарнир', 'path': 'assets/images/pasta.jpg'},
    {'title': 'Сусындар', 'path': 'assets/images/ceremony.jpg'},
    {'title': 'Басқа', 'path': 'assets/images/national.jpg'},
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\u049A\u043E\u0448 \u043A\u0435\u043B\u0434\u0456\u04A3\u0456\u0437!',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '\u0411\u04AF\u0433\u0456\u043D \u043D\u0435 \u0456\u0437\u0434\u0435\u0439\u043C\u0456\u0437?',
                          style: TextStyle(color: Colors.white70),
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
                    child: const Text('\u0406\u0437\u0434\u0435\u0443'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _Title('\u0422\u0430\u043D\u044B\u043C\u0430\u043B \u0441\u0430\u043D\u0430\u0442\u0442\u0430\u0440'),
          const SizedBox(height: 12),
          // РЎРђРќРђРўРўРђР Р”Р« Р–УЁРќР”Р•РЈ:
          SizedBox(
            height: 130, // Р‘РёС–РєС‚С–РіС–РЅ ТЇР»РєРµР№С‚С–Рї, overflow Р±РѕР»РґС‹СЂРјР°Сѓ
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index]; // 'products' РµРјРµСЃ, 'categories'
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
          const _Title('\u0421\u0456\u0437\u0433\u0435 \u0430\u0440\u043D\u0430\u043B\u0493\u0430\u043D'),
          const SizedBox(height: 12),
          _RecommendedDishes(userId: userId),
          const SizedBox(height: 24),
        ],
      ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange.shade100,
                  backgroundImage: AssetImage(assetPath),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
  Set<String> _favoriteIds = {};
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadProducts();
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
        const SnackBar(content: Text('РўР°ТЈРґР°СѓР»С‹Т“Р° Т›РѕСЃСѓ ТЇС€С–РЅ РєС–СЂС–ТЈС–Р·.')),
      );
      return;
    }
    final productId = product['_id']?.toString();
    if (productId == null) return;
    try {
      final result = await ApiService.toggleFavorite(widget.userId, productId);
      final isLiked = result['isLiked'] == true;
      // Only update favorites set вЂ” do NOT reload the product list
      if (mounted) {
        setState(() {
          if (isLiked) { _favoriteIds.add(productId); }
          else { _favoriteIds.remove(productId); }
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'РЎР°Т›С‚Р°Р»РґС‹')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ТљР°С‚Рµ: $e')),
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
          const Text('Р–ТЇРєС‚РµСѓ Т›Р°С‚РµСЃС–.'),
          TextButton(onPressed: _loadProducts, child: const Text('ТљР°Р№С‚Р° РєУ©СЂСѓ')),
        ],
      ),
    );
    if (_products.isEmpty) return const Center(child: Text('РўР°СѓР°СЂР»Р°СЂ С‚Р°Р±С‹Р»РјР°РґС‹.'));

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
    final title = product['title'] ?? 'РўР°Т›С‹СЂС‹РїСЃС‹Р·';
    final imageUrl = product['imageUrl'] ?? 'assets/images/soup.jpg';
    final price = product['price'] ?? 0;
    final sellerName = product['sellerName']?.toString().isNotEmpty == true
        ? product['sellerName'].toString()
        : (product['sellerId']?.toString() ?? 'РЎР°С‚СѓС€С‹');
    final sellerLogo = product['sellerLogo']?.toString() ?? '';

    // РђРІР°С‚Р°СЂ С€РµТЈР±РµСЂС–
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
          Stack(
            children: [
              imageUrl.startsWith('http') 
                ? CachedNetworkImage(
                    imageUrl: imageUrl, 
                    height: 180, 
                    width: double.infinity, 
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.error),
                    ),
                  )
                : Image.asset(imageUrl.replaceFirst('assets/assets/', 'assets/'), height: 180, width: double.infinity, fit: BoxFit.cover),
            ],
          ),
            // РўР°СѓР°СЂ Р°С‚С‹ + РєР°С‚РµРіРѕСЂРёСЏ
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            // РўУ©РјРµРЅРіС– Р±У©Р»С–РјС–: Р»РѕРіРѕ СЃРѕР»РґР°, РєРЅРѕРїРєР°Р»Р°СЂ + Р±Р°Т“Р° РѕТЈРґР°
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // РЎРѕР»: Р»РѕРіРѕ + Р±СЂРµРЅРґ Р°С‚С‹
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
                  // РћТЈ: РєРЅРѕРїРєР°Р»Р°СЂ Р¶У™РЅРµ Р±Р°Т“Р°
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // Р›Р°Р№РєРєРЅРѕРїРєР°СЃС‹
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
                          // РљРµСЂС–РєРЅРѕРїРєР°СЃС‹
                          SizedBox(
                            width: 36, height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.add_shopping_cart, color: Colors.orange, size: 22),
                              onPressed: () async {
                                if (userId == 'guest') {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('РЎРµР±РµС‚РєРµ Т›РѕСЃСѓ ТЇС€С–РЅ РєС–СЂС–ТЈС–Р·.')));
                                  return;
                                }
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('РЎРµР±РµС‚РєРµ Т›РѕСЃС‹Р»СѓРґР°...'), duration: Duration(milliseconds: 500)));
                                  await ApiService.addToCart(userId, product['_id']);
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('РЎРµР±РµС‚РєРµ Т›РѕСЃС‹Р»РґС‹!')));
                                } catch (e) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ТљР°С‚Рµ: $e')));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Р‘Р°Т“Р°
                      Text(
                        '$price \u20B8',
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
  }

  Widget _initials(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}



