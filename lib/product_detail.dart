import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first/api.dart';
import 'seller_profile.dart';
import 'localization.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String userId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.userId = 'guest',
  });


  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  bool _favoriteLoading = false;


  List<String> _normalizeList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = value.toString().trim();
    return text.isEmpty ? [] : [text];
  }

  List<String> _preferList(dynamic primary, dynamic fallback) {
    final primaryList = _normalizeList(primary);
    if (primaryList.isNotEmpty) return primaryList;
    return _normalizeList(fallback);
  }

  String? _findLine(String description, String prefix) {
    for (final raw in description.split("\n")) {
      final line = raw.trim();
      if (line.startsWith(prefix)) return line;
    }
    return null;
  }

  List<String> _parseCommaList(String line, String prefix) {
    final text = line.replaceFirst(prefix, "").trim();
    if (text.isEmpty) return [];
    return text
        .split(",")
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _parseStepsLine(String line, String prefix) {
    final text = line.replaceFirst(prefix, "").trim();
    if (text.isEmpty) return [];
    return text
        .split(RegExp(r"\.\s+"))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _extractMetaParts(String description) {
    for (final raw in description.split("\n")) {
      final line = raw.trim();
      if (line.contains(" | ")) {
        return line
            .split(" | ")
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.2)),
    );
  }

  Widget _stepRow(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              index.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    if (widget.userId == 'guest') return;
    final productId = widget.product['_id']?.toString();
    if (productId == null) return;
    try {
      final favs = await ApiService.getFavorites(widget.userId);
      if (!mounted) return;
      setState(() {
        _isFavorite = favs.any((item) => item['_id']?.toString() == productId);
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (widget.userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Таңдаулыға қосу үшін кіріңіз.')),
      );
      return;
    }
    final productId = widget.product['_id']?.toString();
    if (productId == null) return;
    setState(() => _favoriteLoading = true);
    try {
      final result = await ApiService.toggleFavorite(widget.userId, productId);
      final isLiked = result['isLiked'] == true;
      if (!mounted) return;
      setState(() => _isFavorite = isLiked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Сақталды')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _favoriteLoading = false);
      }
    }
  }

  // Сатушы аты-жөні арқылы шеңбер аватар
  Widget _sellerInitials(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = Loc.lang.value;
    
    // Выбор заголовка
    String title = '';
    if (lang == 'kz') {
      title = (widget.product['titleKz'] ?? '').toString();
    } else if (lang == 'ru') {
      title = (widget.product['titleRu'] ?? '').toString();
    }
    if (title.trim().isEmpty) {
      title = (widget.product['title'] ?? 'Тақырыпсыз').toString();
    }
    
    final String imageUrl = widget.product['imageUrl'] ?? 'assets/images/soup.jpg';
    
    // Логика выбора описания
    String description = '';
    if (lang == 'kz') {
      description = (widget.product['descriptionKz'] ?? '').toString();
    } else if (lang == 'ru') {
      description = (widget.product['descriptionRu'] ?? '').toString();
    }
    if (description.trim().isEmpty) {
      description = (widget.product['description'] ?? '').toString();
    }
    if (description.trim().isEmpty) {
      description = Loc.tr('not_specified');
    }

    final price = widget.product['price'] ?? 0;
    final String condition = widget.product['condition'] ?? Loc.tr('not_specified');
    final String location = widget.product['location'] ?? Loc.tr('not_specified');
    final String sellerName = widget.product['sellerName'] ?? widget.product['sellerId'] ?? Loc.tr('seller_label');
    final String sellerLogo = widget.product['sellerLogo'] ?? '';

    // Логика выбора состава и шагов
    List<String> ingredients = [];
    List<String> steps = [];

    if (lang == 'kz') {
      ingredients = _normalizeList(widget.product['ingredientsKz']);
      steps = _normalizeList(widget.product['stepsKz']);
    } else if (lang == 'ru') {
      ingredients = _normalizeList(widget.product['ingredientsRu']);
      steps = _normalizeList(widget.product['stepsRu']);
    }

    if (ingredients.isEmpty) {
      ingredients = _normalizeList(widget.product['ingredients']);
    }
    if (steps.isEmpty) {
      steps = _normalizeList(widget.product['steps']);
    }

    // Парсинг из описания (если поля пустые)
    const ingredientsPrefixRu = 'Состав:';
    const stepsPrefixRu = 'Приготовление:';
    
    if (ingredients.isEmpty) {
      final line = _findLine(description, ingredientsPrefixRu);
      if (line != null) ingredients = _parseCommaList(line, ingredientsPrefixRu);
    }
    if (steps.isEmpty) {
      final line = _findLine(description, stepsPrefixRu);
      if (line != null) steps = _parseStepsLine(line, stepsPrefixRu);
    }

    final metaParts = _extractMetaParts(description);
    final hasStructured = ingredients.isNotEmpty || steps.isNotEmpty || metaParts.isNotEmpty;

    final Widget productImage = imageUrl.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 300,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: Colors.grey.shade300,
              child: const Icon(Icons.error),
            ),
          )
        : Image.asset(imageUrl.replaceFirst('assets/assets/', 'assets/'), width: double.infinity, height: 300, fit: BoxFit.cover);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _favoriteLoading ? null : _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            productImage,
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${price} \u20B8',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                   Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text('${Loc.tr('location_label')}: $location', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text('${Loc.tr('condition_label')}: $condition', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // Сатушы блогі
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SellerProfileScreen(
                          sellerId: widget.product['sellerId'] ?? '',
                          sellerName: sellerName,
                          sellerLogo: sellerLogo,
                          userId: widget.userId,
                          address: location,
                        )
                      ));
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: sellerLogo.startsWith('http')
                                ? Image.network(sellerLogo, width: 48, height: 48, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _sellerInitials(sellerName))
                                : _sellerInitials(sellerName),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Loc.tr('seller_label'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(sellerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  Text(
                    Loc.tr('description_label'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (hasStructured) ...[
                    if (ingredients.isNotEmpty)
                      _sectionCard(
                        icon: Icons.receipt_long,
                        title: Loc.tr('ingredients_label'),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ingredients.map(_infoPill).toList(),
                        ),
                      ),
                    if (metaParts.isNotEmpty)
                      _sectionCard(
                        icon: Icons.info_outline,
                        title: Loc.tr('details_label'),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: metaParts.map(_infoPill).toList(),
                        ),
                      ),
                    if (steps.isNotEmpty)
                      _sectionCard(
                        icon: Icons.restaurant_menu,
                        title: Loc.tr('steps_label'),
                        child: Column(
                          children: [
                            for (int i = 0; i < steps.length; i++) _stepRow(i + 1, steps[i]),
                          ],
                        ),
                      ),
                    if (ingredients.isEmpty && steps.isEmpty && metaParts.isEmpty)
                      Text(description, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4)),
                  ] else
                    Text(description, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4)),

                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (widget.userId == 'guest') {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('login_to_add'))));
                          return;
                        }
                        try {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('adding_to_cart')), duration: const Duration(milliseconds: 500)));
                          await ApiService.addToCart(widget.userId, widget.product['_id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('added_to_cart'))));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${Loc.tr('error')}: $e')));
                          }
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(Loc.tr('add_to_cart'), style: const TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(Loc.tr('loading'))),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: Text(Loc.tr('contact_seller'), style: const TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
