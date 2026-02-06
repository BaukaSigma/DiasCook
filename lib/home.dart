// home.dart
import 'package:flutter/material.dart';
import 'package:first/api.dart'; 
import 'profile.dart'; 
import 'search.dart';
import 'favorites.dart';
import 'recipe_detail.dart'; 

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

  // Мәзір атауларын өзгерттік
  static const _titles = <String>[
    'Басты',
    'Іздеу',
    'Ұнайды',
    'Парақша',
  ];

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;

    // Беттер тізімін жаңарттық
    _tabs = <Widget>[
      _HomeTab(userId: widget.userId),
      SearchScreen(
        userId: widget.userId,
        initialCategory: widget.initialSearchCategory,
        initialQuery: widget.initialSearchQuery,
      ),
      FavoritesScreen(key: _favoritesKey, userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  // Навигация логикасы (өзгеріссіз қалады, бірақ индекс енді жаңа бетке сілтейді)
  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    if (index == 2) {
      _favoritesKey.currentState?.refreshFavorites();
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Басты'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Іздеу'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Ұнайды'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Парақша'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userId;
  const _HomeTab({super.key, required this.userId});

  static const List<Map<String, String>> categories = [
    {'title': 'Бірінші тағамдар', 'path': 'assets/images/soup.jpg'},
    {'title': 'Екінші тағамдар', 'path': 'assets/images/manty.jpg'},
    {'title': 'Десерттер', 'path': 'assets/images/dessert.jpg'},
    {'title': 'Салаттар', 'path': 'assets/images/shrimp_pasta.jpg'},
    {'title': 'Ұлттық', 'path': 'assets/images/national.jpg'},
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
                image: AssetImage('assets/images/dessert.jpg'),
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
                          'Қош келдіңіз!',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Бүгін қандай рецепт дайындаймыз?',
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
                    child: const Text('Іздеу'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _Title('Танымал санаттар'),
          const SizedBox(height: 12),
          // САНАТТАРДЫ ЖӨНДЕУ:
          SizedBox(
            height: 130, // Биіктігін үлкейтіп, overflow болдырмау
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index]; // 'products' емес, 'categories'
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
          const _Title('Жаңа ұсыныстар'),
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

  @override
  void initState() {
    super.initState();
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

  Future<void> _toggleFavorite(BuildContext context, Map<String, dynamic> product) async {
    if (widget.userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Таңдаулыға қосу үшін кіріңіз.')),
      );
      return;
    }
    final productId = product['_id']?.toString();
    if (productId == null) return;
    try {
      final result = await ApiService.toggleFavorite(widget.userId, productId);
      final isLiked = result['isLiked'] == true;
      setState(() {
        if (isLiked) {
          _favoriteIds.add(productId);
        } else {
          _favoriteIds.remove(productId);
        }
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Сақталды')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Қате: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Қате: ${snapshot.error}')); 
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Рецепттер табылмады.')); 
        }

        final products = snapshot.data!;

        return Column(
          children: products.map((product) {
            final productId = product['_id']?.toString();
            final isLiked = productId != null && _favoriteIds.contains(productId);
            return _ProductCard(
              product: product,
              userId: widget.userId,
              isFavorite: isLiked,
              onFavoritePressed: () => _toggleFavorite(context, product),
            );
          }).toList(),
        );
      },
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
    // Деректерді объектіден суырып аламыз
    final title = product['title'] ?? 'Тақырыпсыз';
    final imageUrl = product['imageUrl'] ?? 'assets/images/soup.jpg';
    final description = product['description'] ?? '';
    final category = product['category'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Сурет жиегі дөңгелек болуы үшін
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Егер URL болса Image.network, егер жол болса Image.asset
              imageUrl.startsWith('http') 
                ? Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover)
                : Image.asset(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
              Positioned(
                top: 10, right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: onFavoritePressed,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (category.toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.toString(),
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  description.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // РЕЦЕПТ БЕТІНЕ ӨТУ
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(
                            product: product,
                            userId: userId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text("Рецептті көру"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
