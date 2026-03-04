import 'package:flutter/material.dart';
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
  final _imageUrlController = TextEditingController();
  
  String _selectedCategory = 'Басқа';
  String _selectedCondition = 'Жаңа';
  bool _isLoading = false;

  final List<String> _categories = [
    'Сұлулық',
    'Жиһаз',
    'Ноутбуктер',
    'Киім',
    'Көлік',
    'Басқа'
  ];

  final List<String> _conditions = [
    'Жаңа',
    'Жақсы',
    'Қолданылған'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final productData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'price': int.tryParse(_priceController.text) ?? 0,
      'category': _selectedCategory,
      'condition': _selectedCondition,
      'location': _locationController.text.trim(),
      'imageUrl': _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : 'assets/images/soup.jpg',
      // Mocking Seller Info since we only have userId on frontend currently. In a real app we would get the true seller name from Auth contexts.
      'sellerId': widget.userId,
      'sellerName': 'Пайдаланушы (${widget.userId.substring(0, 5)})',
    };

    try {
      await ApiService.addProduct(productData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тауар сәтті қосылды!')),
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
        title: const Text('Тауар қосу'),
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
                        labelText: 'Тауар атауы',
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
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Суретке сілтеме (Url)',
                        border: OutlineInputBorder(),
                        hintText: 'https://mysite.com/image.jpg',
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Күйі',
                        border: OutlineInputBorder(),
                      ),
                      items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCondition = val!),
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
