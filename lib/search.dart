// search.dart

import 'package:flutter/material.dart';
import 'package:first/api.dart'; 
import 'login.dart'; 
import 'home.dart';

// ====================================================================
// --- КОНСТАНТЫ и МОДЕЛИ -------------------------------------------
// ====================================================================

// Предполагаемые категории продуктов для фильтрации
const List<String> _categories = [
  'Все категории', // Фильтр по умолчанию
  'Екінші тағамдар',
  'Десерттер',
  'Салаттар',
  'Сусындар',
  // Добавьте другие категории из вашей БД, если нужно
];

// ====================================================================
// --- СТРАНИЦА ПОИСКА (основной виджет) -----------------------------
// ====================================================================

class SearchScreen extends StatefulWidget {
  final String userId;
  const SearchScreen({super.key, required this.userId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Future<List<dynamic>>? _productsFuture;
  List<dynamic> _allProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'Все категории';

  @override
  void initState() {
    super.initState();
    // 1. Загрузка всех продуктов при старте
    _productsFuture = _loadProducts();
  }

  Future<List<dynamic>> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      // Сохраняем полный список продуктов для последующей фильтрации
      _allProducts = products;
      return products;
    } catch (e) {
      // Можно показать SnackBar с ошибкой, но FutureBuilder сам обработает ошибку
      throw Exception('Не удалось загрузить продукты: ${e.toString()}');
    }
  }

  // Функция фильтрации
  List<dynamic> _getFilteredProducts() {
    // 1. Фильтрация по категории
    Iterable<dynamic> filtered = _allProducts.where((product) {
      if (_selectedCategory == 'Все категории') {
        return true;
      }
      return (product['category'] as String?) == _selectedCategory;
    });

    // 2. Фильтрация по поисковому запросу (по названию)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final title = (product['title'] as String?)?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return title.contains(query);
      });
    }

    return filtered.toList();
  }

  // ====================================================================
  // --- КОМПОНЕНТЫ UI --------------------------------------------------
  // ====================================================================

  // Заглушка для пустого результата поиска
  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет результатов',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Поиск по запросу "$_searchQuery" в категории "$_selectedCategory" не дал результатов.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для отображения одного продукта в списке
  Widget _buildProductCard(Map<String, dynamic> product) {
    final title = product['title'] as String? ?? 'Название не указано';
    final price = (product['price'] as num?)?.toStringAsFixed(0) ?? '0';
    final seller = product['sellerName'] as String? ?? 'Продавец неизвестен';
    // Используем Image.asset с проверкой, как в ранее предоставленном коде
    final imageUrl = product['imageUrl'] as String? ?? 'assets/images/default.jpg';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        // Изображение продукта
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Если фото не найдено, показываем заглушку
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(seller, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '$price ₸',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.orange,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
          onPressed: () async {
            // Логика добавления в корзину (как в предыдущем исправлении)
             try {
              await ApiService.addToCart(widget.userId, product['_id'] as String, 1);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title добавлен в корзину!')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        onTap: () {
          // TODO: Переход на страницу деталей продукта
        },
      ),
    );
  }


  // ====================================================================
  // --- BUILD МЕТОДЫ (Рендеринг) ---------------------------------------
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    // 💡 ИСПРАВЛЕНИЕ: УДАЛЯЕМ Scaffold и AppBar!
    // Возвращаем сразу FutureBuilder с контентом.
    return FutureBuilder<List<dynamic>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
        }

        // Построение UI с фильтрами и списком
        final filteredProducts = _getFilteredProducts();

        return Column(
          children: [
            // 1. Поле поиска
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Найти блюдо',
                  hintText: 'Введите название товара...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            // 2. Выпадающий список категорий
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Фильтр по категории',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            // 3. Результаты поиска
            Expanded(
              child: filteredProducts.isEmpty
                  ? _buildNoResults()
                  : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(
                              filteredProducts[index] as Map<String, dynamic>);
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}