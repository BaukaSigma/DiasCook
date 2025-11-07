// home.dart
import 'package:flutter/material.dart';
import 'package:first/api.dart'; 
import 'login.dart'; 
import 'profile.dart'; 
import 'cart.dart';
import 'search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.startIndex = 0,
    this.userId = 'guest', 
  });

  final int startIndex;
  final String userId;

  static void openTab(BuildContext context, int index, {String userId = 'guest'}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(startIndex: index, userId: userId)),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final List<int> _navHistory = [];

  static const _titles = <String>[
    'Басты',         
    'Іздеу',         
    'Тауар қосу',   
    'Себет',      
    'Профиль',      
  ];

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;

    _tabs = <Widget>[
      const _HomeTab(), 
      SearchScreen(userId: widget.userId),        
      const _AddProductTab(),      
      _CartTab(userId: widget.userId),      
      ProfileScreen(userId: widget.userId), 
    ];
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    _navHistory.add(_currentIndex);
    setState(() => _currentIndex = index);
  }

  Future<bool> _onWillPop() async {
    if (_navHistory.isNotEmpty) {
      setState(() => _currentIndex = _navHistory.removeLast());
      return false; 
    }
    return true; 
  }

  @override
  Widget build(BuildContext context) {
    // Индекс вкладки "Профиль" - 4. 
    final bool isProfileTab = _currentIndex == 4;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // Если это вкладка Профиль, AppBar = null (скрыть)
        appBar: isProfileTab ? null : AppBar( 
          title: Text(_titles[_currentIndex]),
          backgroundColor: Colors.orange, 
          foregroundColor: Colors.white, 
          centerTitle: true,
          elevation: 4, 
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.orange, 
          unselectedItemColor: Colors.grey, 
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Басты',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Іздеу',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Тауар қосу', 
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart_outlined),
              label: 'Себет',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({super.key});

  static const List<Map<String, String>> categories = [
    {'title': 'Бірінші тағамдар', 'path': 'assets/images/soup.jpg'},
    {'title': 'Екінші тағамдар', 'path': 'assets/images/pasta.jpg'},
    {'title': 'Десерттер', 'path': 'assets/images/dessert.jpg'},
    {'title': 'Салтанатты', 'path': 'assets/images/ceremony.jpg'},
    {'title': 'Ұлттық', 'path': 'assets/images/national.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title('Танымал санаттар'),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _HorizontalCategory(
                  title: categories[index]['title']!,
                  assetPath: categories[index]['path']!,
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          const _Title('Жаңа ұсыныстар'), 
          const SizedBox(height: 12),
          
          const _RecommendedDishes(userId: 'guest'),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HorizontalCategory extends StatelessWidget {
  final String title;
  final String assetPath;

  const _HorizontalCategory({
    super.key,
    required this.title, 
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Санат: "$title" ашу')),
        );
      },
      child: Container(
        width: 100, 
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: AssetImage(assetPath),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedDishes extends StatelessWidget {
  final String userId;
  const _RecommendedDishes({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Қате: ${snapshot.error}. Бэкендті тексеріңіз.')); 
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Тауарлар табылмады.')); 
        }

        final products = snapshot.data!;

        return Column(
          children: products.map((product) {
            return _ProductCard(
              title: product['title'] ?? 'Тақырыпсыз тауар',
              sellerName: product['sellerName'] ?? 'Сатушысыз', 
              imageUrl: product['imageUrl'] ?? 'assets/images/default.jpg',
              price: product['price']?.toString() ?? 'N/A', 
              productId: product['_id'],
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String sellerName;
  final String imageUrl;
  final String productId;
  final String price;
  
  const _ProductCard({
    super.key,
    required this.title,
    required this.sellerName,
    required this.imageUrl,
    required this.productId,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Сатушы: $sellerName',
                    style: const TextStyle(color: Colors.grey)), 
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${price.replaceAll(RegExp(r'\.0*$'), '')} ₸', 
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart, size: 18),
                          label: const Text('Сатып алу'), 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$title тауары себетке қосылды!')),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    return Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800));
  }
}


class _AddProductTab extends StatelessWidget {
  const _AddProductTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_business, size: 80, color: Colors.orange), 
          SizedBox(height: 16),
          Text(
            'Жаңа тауар қосу',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Сатуға арналған өзіңіздің үй тағамыңызды қосыңыз.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Іздеу функционалы жақында қосылады.')); 
  }
}

class _CartTab extends StatelessWidget {
  final String userId;
  const _CartTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == 'guest') {
      return _buildGuestContent(context);
    }
    
    // Толық функционалды Себет экранына сілтеме жасаймыз
    return CartScreen(userId: userId);
  }

  Widget _buildGuestContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Себет бос',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Тауарларды себетке қосу үшін алдымен тіркеліңіз немесе кіріңіз.',
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