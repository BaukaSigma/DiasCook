import 'package:flutter/material.dart';
import 'package:first/api.dart';
import '../login.dart';
import '../product_detail.dart';
import '../home.dart';
import '../localization.dart';
import '../firestore_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AdminPanelScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  const AdminPanelScreen({super.key, required this.admin});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  static const _titles = <String>[
    'Пайдаланушылар',
    'Рецепттер',
    'Рецепт қосу',
    'Тапсырыстар',
    'Әкімші профилі',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = <Widget>[
      const AdminUsersTab(),
      const AdminRecipesTab(),
      const AdminAddRecipeTab(),
      const AdminOrdersTab(),
      AdminProfileTab(admin: widget.admin),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Пайдаланушылар'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Рецепттер'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Қосу'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Тапсырыстар'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Парақша'),
        ],
      ),
    );
  }
}

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.getAllUsers();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = ApiService.getAllUsers();
    });
  }

  Future<void> _openUserForm({Map<String, dynamic>? user}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (_) => _UserFormSheet(user: user),
    );

    if (saved == true) {
      await _refreshUsers();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userId = user['userId']?.toString() ?? user['_id']?.toString();
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Жоюды растаңыз'),
        content: const Text('Пайдаланушыны жоюға сенімдісіз бе?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Бас тарту')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Жою')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ApiService.deleteUser(userId);
      if (!mounted) return;
      await _refreshUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пайдаланушы жойылды.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Қате: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Column(
            children: [
              _AdminSectionHeader(
                title: 'Пайдаланушылар',
                actionLabel: 'Қосу',
                onAction: () => _openUserForm(),
              ),
              const Expanded(
                child: _EmptyState(
                  icon: Icons.people_outline,
                  text: 'Пайдаланушылар табылмады',
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _AdminSectionHeader(
              title: 'Пайдаланушылар',
              actionLabel: 'Қосу',
              onAction: () => _openUserForm(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshUsers,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index] as Map<String, dynamic>;
                    final fullName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
                    final isAdmin = user['isAdmin'] == true;
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.person, color: Colors.orange),
                        ),
                        title: Text(fullName.isNotEmpty ? fullName : 'Аты көрсетілмеген'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'Электрондық пошта жоқ'),
                            Text(user['phone'] ?? 'Телефон нөмірі жоқ'),
                            if (isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Chip(
                                  label: const Text('Әкімші'),
                                  backgroundColor: Colors.orange.shade50,
                                  labelStyle: TextStyle(color: Colors.orange.shade800),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openUserForm(user: user);
                            } else if (value == 'delete') {
                              _deleteUser(user);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Өңдеу')),
                            PopupMenuItem(value: 'delete', child: Text('Жою')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AdminRecipesTab extends StatefulWidget {
  const AdminRecipesTab({super.key});

  @override
  State<AdminRecipesTab> createState() => _AdminRecipesTabState();
}

class _AdminRecipesTabState extends State<AdminRecipesTab> {
  late Future<List<dynamic>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _recipesFuture = ApiService.getProducts();
  }

  Future<void> _refreshRecipes() async {
    setState(() {
      _recipesFuture = ApiService.getProducts();
    });
  }

  Future<void> _openEditRecipe(Map<String, dynamic> recipe) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (_) => _RecipeFormSheet(recipe: recipe),
    );

    if (saved == true) {
      await _refreshRecipes();
    }
  }

  Future<void> _deleteRecipe(Map<String, dynamic> recipe) async {
    final recipeId = recipe['_id']?.toString();
    if (recipeId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Жоюды растаңыз'),
        content: const Text('Рецептті жоюға сенімдісіз бе?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Бас тарту')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Жою')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ApiService.deleteRecipe(recipeId);
      if (!mounted) return;
      await _refreshRecipes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт жойылды.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _recipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Қате: ${snapshot.error}'));
        }

        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return Column(
            children: [
              _AdminSectionHeader(
                title: 'Рецепттер',
                actionLabel: 'Жаңарту',
                icon: Icons.refresh,
                onAction: _refreshRecipes,
              ),
              const Expanded(
                child: _EmptyState(
                  icon: Icons.menu_book_outlined,
                  text: 'Рецепттер табылмады',
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _AdminSectionHeader(
              title: 'Рецепттер',
              actionLabel: 'Жаңарту',
              icon: Icons.refresh,
              onAction: _refreshRecipes,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshRecipes,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final recipe = recipes[index] as Map<String, dynamic>;
                    final title = recipe['title'] ?? 'Тақырыпсыз';
                    final category = recipe['category'] ?? '';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
                        title: Text(title.toString()),
                        subtitle: Text(
                          category.toString().isNotEmpty ? category.toString() : 'Санат көрсетілмеген',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditRecipe(recipe);
                            } else if (value == 'delete') {
                              _deleteRecipe(recipe);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Өңдеу')),
                            PopupMenuItem(value: 'delete', child: Text('Жою')),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: recipe, userId: 'admin')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AdminAddRecipeTab extends StatefulWidget {
  const AdminAddRecipeTab({super.key});

  @override
  State<AdminAddRecipeTab> createState() => _AdminAddRecipeTabState();
}

class _AdminAddRecipeTabState extends State<AdminAddRecipeTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _sellerIdController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _sellerIdController.dispose();
    super.dispose();
  }

  List<String> _splitLines(String value) {
    return value
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _createRecipe() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Атауы мен сипаттамасын толтырыңыз.')),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = {
      'title': title,
      'description': description,
      'category': _categoryController.text.trim(),
      'imageUrl': _imageUrlController.text.trim().isEmpty
          ? 'assets/images/soup.jpg'
          : _imageUrlController.text.trim(),
      'videoUrl': _videoUrlController.text.trim(),
      'ingredients': _splitLines(_ingredientsController.text),
      'steps': _splitLines(_stepsController.text),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'location': _locationController.text.trim(),
      'sellerId': _sellerIdController.text.trim().isEmpty ? 'admin' : _sellerIdController.text.trim(),
    };

    try {
      await ApiService.createRecipe(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт қосылды!'), backgroundColor: Colors.green),
      );
      _titleController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _imageUrlController.clear();
      _videoUrlController.clear();
      _ingredientsController.clear();
      _stepsController.clear();
      _priceController.clear();
      _locationController.clear();
      _sellerIdController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InputField(
            controller: _titleController,
            label: 'Рецепт атауы',
            icon: Icons.title,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _descriptionController,
            label: 'Сипаттамасы',
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _categoryController,
            label: 'Санат',
            icon: Icons.category,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _imageUrlController,
            label: 'Сурет URL немесе assets жолы',
            icon: Icons.image,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _videoUrlController,
            label: 'Бейне-нұсқаулық сілтемесі',
            icon: Icons.play_circle_outline,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _priceController,
            label: 'Бағасы (₸)',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _locationController,
            label: 'Қала / Мекенжай',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _sellerIdController,
            label: 'Сатушы ID',
            icon: Icons.account_box,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _ingredientsController,
            label: 'Ингредиенттер (әр жолға біреуден)',
            icon: Icons.checklist,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _stepsController,
            label: 'Дайындау қадамдары (әр жолға біреуден)',
            icon: Icons.format_list_numbered,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : _createRecipe,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Сақталуда...' : 'Сақтау'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProfileTab extends StatefulWidget {
  final Map<String, dynamic> admin;
  const AdminProfileTab({required this.admin, super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  late Map<String, dynamic> _admin;

  @override
  void initState() {
    super.initState();
    _admin = Map<String, dynamic>.from(widget.admin);
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _admin['name'] ?? '');
    final surnameController = TextEditingController(text: _admin['surname'] ?? '');
    final emailController = TextEditingController(text: _admin['email'] ?? '');
    final phoneController = TextEditingController(text: _admin['phone'] ?? '');

    Uint8List? newImageBytes;
    String? newImageName;
    String currentAvatar = _admin['sellerLogo'] ?? '';
    bool isUploading = false;

    final updates = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Профильді өңдеу'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25, maxWidth: 400, maxHeight: 400);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setState(() {
                          newImageBytes = bytes;
                          newImageName = picked.name;
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: newImageBytes != null
                                ? Image.memory(newImageBytes!, width: 80, height: 80, fit: BoxFit.cover)
                                : (currentAvatar.isNotEmpty
                                    ? FirestoreImage(imageUrl: currentAvatar, width: 80, height: 80, fit: BoxFit.cover)
                                    : const Icon(Icons.person, size: 50, color: Colors.orange)),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Аты', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: surnameController, decoration: const InputDecoration(labelText: 'Тегі', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder())),
                  if (isUploading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context, null),
                child: const Text('Бас тарту'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        setState(() => isUploading = true);
                        try {
                          String avatarUrl = currentAvatar;
                          if (newImageBytes != null && newImageName != null) {
                            avatarUrl = await ApiService.uploadImage(newImageBytes!, newImageName!);
                          }
                          Navigator.pop(context, {
                            'name': nameController.text.trim(),
                            'surname': surnameController.text.trim(),
                            'email': emailController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'sellerLogo': avatarUrl,
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Қате: $e')));
                          setState(() => isUploading = false);
                        }
                      },
                child: const Text('Сақтау'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    if (updates == null) return;

    final userId = _admin['userId']?.toString();
    if (userId == null || userId.isEmpty) return;

    try {
      await ApiService.updateUserProfile(userId, updates);
      if (!mounted) return;
      setState(() {
        _admin = {..._admin, ...updates};
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сақталды.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Қате: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${_admin['name'] ?? ''} ${_admin['surname'] ?? ''}'.trim();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(42),
            child: (_admin['sellerLogo']?.toString().isNotEmpty == true)
                ? FirestoreImage(imageUrl: _admin['sellerLogo'].toString(), width: 84, height: 84, fit: BoxFit.cover)
                : const CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 42),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isNotEmpty ? fullName : 'Әкімші',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _admin['email'] ?? 'Электрондық пошта көрсетілмеген',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            'ID: ${_admin['userId'] ?? 'N/A'}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Профильді өңдеу'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen(userId: _admin['userId'] ?? 'guest')),
                (_) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Пайдаланушы режимі'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Шығу'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  const _AdminSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(icon),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final Map<String, dynamic>? user;
  const _UserFormSheet({this.user});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  bool _isAdmin = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _surnameController = TextEditingController(text: user?['surname'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _passwordController = TextEditingController();
    _isAdmin = user?['isAdmin'] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || surname.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Барлық өрістерді толтырыңыз.')),
      );
      return;
    }

    if (widget.user == null && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Құпиясөзді енгізіңіз.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.user == null) {
        await ApiService.createUser({
          'name': name,
          'surname': surname,
          'email': email,
          'phone': phone,
          'password': password,
          'isAdmin': _isAdmin,
        });
      } else {
        final userId = widget.user?['userId']?.toString() ?? widget.user?['_id']?.toString();
        if (userId == null) return;
        final payload = {
          'name': name,
          'surname': surname,
          'email': email,
          'phone': phone,
          'isAdmin': _isAdmin,
        };
        if (password.isNotEmpty) {
          payload['password'] = password;
        }
        await ApiService.updateUser(userId, payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.user == null ? 'Пайдаланушы қосылды.' : 'Өзгерістер сақталды.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.user == null ? 'Пайдаланушы қосу' : 'Пайдаланушыны өңдеу',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _InputField(controller: _nameController, label: 'Аты', icon: Icons.person),
            const SizedBox(height: 12),
            _InputField(controller: _surnameController, label: 'Тегі', icon: Icons.person_outline),
            const SizedBox(height: 12),
            _InputField(controller: _emailController, label: 'Электрондық пошта', icon: Icons.email),
            const SizedBox(height: 12),
            _InputField(controller: _phoneController, label: 'Телефон нөмірі', icon: Icons.phone),
            const SizedBox(height: 12),
            _InputField(
              controller: _passwordController,
              label: widget.user == null ? 'Құпиясөз' : 'Құпиясөз (қаласаңыз)',
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isAdmin,
              onChanged: (value) => setState(() => _isAdmin = value),
              title: const Text('Әкімші құқығы'),
              activeColor: Colors.orange.shade700,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Сақталуда...' : 'Сақтау'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeFormSheet extends StatefulWidget {
  final Map<String, dynamic> recipe;
  const _RecipeFormSheet({required this.recipe});

  @override
  State<_RecipeFormSheet> createState() => _RecipeFormSheetState();
}

class _RecipeFormSheetState extends State<_RecipeFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _stepsController;
  
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _sellerIdController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _titleController = TextEditingController(text: recipe['title'] ?? '');
    _descriptionController = TextEditingController(text: recipe['description'] ?? '');
    _categoryController = TextEditingController(text: recipe['category'] ?? '');
    _imageUrlController = TextEditingController(text: recipe['imageUrl'] ?? '');
    _videoUrlController = TextEditingController(text: recipe['videoUrl'] ?? '');
    _ingredientsController = TextEditingController(text: _joinLines(recipe['ingredients']));
    _stepsController = TextEditingController(text: _joinLines(recipe['steps']));
    
    _priceController = TextEditingController(text: recipe['price']?.toString() ?? '');
    _locationController = TextEditingController(text: recipe['location'] ?? '');
    _sellerIdController = TextEditingController(text: recipe['sellerId'] ?? '');
  }

  String _joinLines(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).join('\n');
    }
    return value?.toString() ?? '';
  }

  List<String> _splitLines(String value) {
    return value
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _sellerIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Атауы мен сипаттамасы міндетті.')),
      );
      return;
    }

    final recipeId = widget.recipe['_id']?.toString();
    if (recipeId == null) return;

    setState(() => _saving = true);

    final payload = {
      'title': title,
      'description': description,
      'category': _categoryController.text.trim(),
      'imageUrl': _imageUrlController.text.trim(),
      'videoUrl': _videoUrlController.text.trim(),
      'ingredients': _splitLines(_ingredientsController.text),
      'steps': _splitLines(_stepsController.text),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'location': _locationController.text.trim(),
      'sellerId': _sellerIdController.text.trim().isEmpty ? 'admin' : _sellerIdController.text.trim(),
    };

    try {
      await ApiService.updateRecipe(recipeId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт жаңартылды.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context, false),
                ),
                const Expanded(child: Text('Рецептті өңдеу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            _InputField(controller: _titleController, label: 'Рецепт атауы', icon: Icons.title),
            const SizedBox(height: 12),
            _InputField(
              controller: _descriptionController,
              label: 'Сипаттамасы',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _InputField(controller: _categoryController, label: 'Санат', icon: Icons.category),
            const SizedBox(height: 12),
            _InputField(
              controller: _imageUrlController,
              label: 'Сурет URL немесе assets жолы',
              icon: Icons.image,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _videoUrlController,
              label: 'Бейне-нұсқаулық сілтемесі',
              icon: Icons.play_circle_outline,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _priceController,
              label: 'Бағасы (₸)',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _locationController,
              label: 'Қала / Мекенжай',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _sellerIdController,
              label: 'Сатушы ID',
              icon: Icons.account_box,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _ingredientsController,
              label: 'Ингредиенттер (әр жолға біреуден)',
              icon: Icons.checklist,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _stepsController,
              label: 'Дайындау қадамдары (әр жолға біреуден)',
              icon: Icons.format_list_numbered,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Сақталуда...' : 'Сақтау'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final bool obscureText;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final finalKeyboardType = (keyboardType == TextInputType.text && maxLines > 1)
        ? TextInputType.multiline
        : keyboardType;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: finalKeyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.getAllOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = ApiService.getAllOrders();
    });
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else {
      dt = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    }
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Заказ принят';
      case 'cooking':
        return 'Готовится';
      case 'ready':
        return 'Готов';
      case 'delivering':
        return 'Доставляется';
      case 'completed':
        return 'Завершен';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.orange;
      case 'cooking':
        return Colors.amber.shade700;
      case 'ready':
        return Colors.blue;
      case 'delivering':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Қате: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long,
            text: 'Тапсырыстар табылмады',
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final status = order['orderStatus'] ?? 'accepted';
              final items = order['items'] as List? ?? [];
              final deliveryType = order['deliveryType'] ?? 'pickup';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Тапсырыс #${order['orderId'].toString().substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor(status)),
                            ),
                            child: Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Күні: ${_formatDate(order['createdAt'])}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const Divider(height: 20),
                      
                      Text('Клиент: ${order['userName'] ?? 'N/A'} (${order['userPhone'] ?? 'N/A'})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('Продавец ID: ${order['sellerId'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                      Text('${Loc.tr('getting_method')}: ${deliveryType == 'pickup' ? Loc.tr('pickup') : Loc.tr('delivery')}',
                          style: const TextStyle(fontSize: 13)),
                      if (deliveryType == 'external_delivery') ...[
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            Loc.tr('delivery_in_progress'),
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('Адрес: ${order['deliveryAddress'] ?? ''}',
                            style: const TextStyle(fontSize: 13, color: Colors.orangeAccent)),
                      ],
                      
                      const Divider(height: 20),
                      
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: FirestoreImage(
                                    imageUrl: item['imageUrl'] ?? '',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ValueListenableBuilder<String>(
                                  valueListenable: Loc.lang,
                                  builder: (context, lang, _) {
                                    String itemTitle = '';
                                    if (lang == 'kz') {
                                      itemTitle = item['titleKz'] ?? '';
                                    } else if (lang == 'ru') {
                                      itemTitle = item['titleRu'] ?? '';
                                    } else if (lang == 'en') {
                                      itemTitle = item['titleEn'] ?? '';
                                    }
                                    if (itemTitle.isEmpty) {
                                      itemTitle = item['title'] ?? '';
                                    }
                                    return Text(itemTitle, style: const TextStyle(fontSize: 13));
                                  },
                                ),
                              ),
                              Text('${item['quantity']} × ${item['price']} ₸',
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }),
                      
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Жалпы сомасы / Общая сумма', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${order['totalPrice']?.toInt() ?? 0} ₸',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Способ оплаты: ${order['paymentMethod']} (${order['paymentStatus'] == 'confirmed' ? 'Оплачено' : 'В ожидании'})',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
