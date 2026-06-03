import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:first/api.dart';

class AddProductScreen extends StatefulWidget {
  final String userId;
  const AddProductScreen({super.key, required this.userId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Таң ертеңгілік';
  bool _isLoading = false;
  String _sellerName = '';
  String _sellerLogo = '';
  Uint8List? _imageBytes;
  String? _imageFileName;

  final List<String> _categories = [
    'Таң ертеңгілік',
    'Түскі ас',
    'Кешкі ас',
    'Тәттілер',
    'Алғашқы тағам',
    'Гарнир',
    'Сусындар',
    'Басқа',
  ];

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
  }

  Future<void> _loadSellerInfo() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          final n = (data['name'] ?? '').toString().trim();
          final s = (data['surname'] ?? '').toString().trim();
          _sellerName = [n, s].where((x) => x.isNotEmpty).join(' ');
          _sellerLogo = (data['sellerLogo'] ?? data['photoUrl'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Сильное сжатие: качество 25%, макс 400px — base64 будет ~30-60KB, влезет в Firestore
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25, maxWidth: 400, maxHeight: 400);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFileName = picked.name;
    });
  }

  Future<String> _saveImageToFirestore() async {
    if (_imageBytes == null) return 'assets/images/soup.jpg';
    try {
      final ext = (_imageFileName ?? 'img').split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mime;base64,${base64Encode(_imageBytes!)}';
      final docRef = await FirebaseFirestore.instance.collection('product_images').add({
        'data': dataUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'firestore_image:${docRef.id}';
    } catch (_) {
      return 'assets/images/soup.jpg';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final imageUrl = _imageBytes != null ? await _saveImageToFirestore() : 'assets/images/soup.jpg';
    final rawPrice = int.tryParse(_priceController.text) ?? 0;
    final roundedPrice = ((rawPrice / 100).round() * 100).toInt();

    final productData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'price': roundedPrice,
      'category': _selectedCategory,
      'location': _locationController.text.trim(),
      'imageUrl': imageUrl,
      'sellerId': widget.userId,
      'sellerName': _sellerName.isNotEmpty ? _sellerName : 'Пайдаланушы',
      if (_sellerLogo.isNotEmpty) 'sellerLogo': _sellerLogo,
    };

    try {
      await ApiService.addProduct(productData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тағам сәтті қосылды!')),
      );
      Navigator.pop(context); // Возврат на предыдущий экран
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тағам қосу'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Тағам атауы',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Бұл өрісті толтырыңыз' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Бағасы (₸)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Бағаны енгізіңіз';
                        if (int.tryParse(val) == null) return 'Тек сандар енгізіңіз';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Сипаттамасы',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Қала немесе орналасуы',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Қаланы көрсетіңіз' : null,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 52, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text('Фото таңдау', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Санат',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Қосу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
