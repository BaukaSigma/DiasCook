import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:first/api.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String userId;

  const RecipeDetailScreen({
    super.key,
    required this.product,
    this.userId = 'guest',
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  YoutubePlayerController? _controller;
  String _videoId = '';
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadFavoriteState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initVideo() {
    final url = (widget.product['videoUrl'] ?? '').toString().trim();
    final id = YoutubePlayer.convertUrlToId(url);
    if (id != null && id.isNotEmpty) {
      _videoId = id;
      _controller = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    // Деректерді алу (егер бос болса, әдепкі мәндерді қою)
    final String title = widget.product['title'] ?? 'Тақырыпсыз';
    final String imageUrl = widget.product['imageUrl'] ?? 'assets/images/soup.jpg';
    final String description = widget.product['description'] ?? 'Сипаттамасы жоқ.';
    final List<dynamic> ingredients = widget.product['ingredients'] ?? [];
    final List<dynamic> steps = widget.product['steps'] ?? [];

    final Widget recipeImage = imageUrl.startsWith('http')
        ? Image.network(imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover)
        : Image.asset(imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Артқа', style: TextStyle(color: Colors.white)),
        ),
        leadingWidth: 72,
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
            recipeImage,
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Сипаттамасы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16, color: Colors.black87)),

                  const Divider(height: 32),

                  const Text('Қажетті ингредиенттер', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...ingredients.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      )),

                  const Divider(height: 32),

                  const Text('Дайындау жолы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...steps.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.orange,
                            child: Text('$idx', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(entry.value.toString(), style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 32),

                  const Text('Бейне-нұсқаулық', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_controller == null)
                    const Text('Бейне әлі қосылмаған.', style: TextStyle(color: Colors.grey))
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: YoutubePlayer(
                        controller: _controller!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.orange,
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
