// profile.dart
import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'login.dart';
import 'add_product.dart';
import 'my_products.dart';
import 'localization.dart';
import 'firestore_image.dart';
import 'user_orders.dart';
import 'seller_orders.dart';
import 'admin/admin_panel.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

Widget _buildInfoCard({
  required BuildContext context,
  required IconData icon,
  required String label,
  required String value,
  VoidCallback? onEdit,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: Colors.orange.shade700, size: 28),
      title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
      trailing: onEdit != null ? IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.orange), onPressed: onEdit) : null,
    ),
  );
}

Widget _buildProfileContent(BuildContext context, Map<String, dynamic> user, VoidCallback reloadUser) {
  final fullName = '${user['name'] ?? ''} ${user['surname'] ?? ''}';

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _editProfile(context, user, reloadUser),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.white,
                        child: user['sellerLogo'] != null && user['sellerLogo'].toString().isNotEmpty
                            ? FirestoreImage(
                                imageUrl: user['sellerLogo'].toString(),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  fullName.trim().isNotEmpty 
                                      ? fullName.trim()[0].toUpperCase() 
                                      : '?',
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _editProfile(context, user, reloadUser),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${user['userId'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Loc.tr('contact_info'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, size: 28, color: Colors.orange),
                    onPressed: () => _editProfile(context, user, reloadUser),
                  ),
                ],
              ),
              const Divider(color: Colors.orangeAccent),
              
              _buildInfoCard(
                context: context,
                icon: Icons.email_outlined,
                label: Loc.tr('email'),
                value: user['email'] ?? 'N/A',
              ),
              
              _buildInfoCard(
                context: context,
                icon: Icons.phone_android_outlined,
                label: Loc.tr('phone'),
                value: user['phone'] != null && user['phone'].toString().isNotEmpty
                    ? user['phone'].toString()
                    : Loc.tr('not_specified'),
              ),

              _buildInfoCard(
                context: context,
                icon: Icons.local_shipping_outlined,
                label: Loc.tr('delivery_addr'),
                value: user['deliveryAddress'] != null && user['deliveryAddress'].toString().isNotEmpty
                    ? user['deliveryAddress'].toString()
                    : Loc.tr('not_specified'),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(userId: user['userId'])));
                  },
                  icon: const Icon(Icons.add_business),
                  label: Text(Loc.tr('add_product')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MyProductsScreen(userId: user['userId'])));
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Менің тағамдарым'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Order History Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserOrdersScreen(userId: user['userId'])));
                  },
                  icon: const Icon(Icons.history),
                  label: Text(Loc.lang.value == 'kz' ? 'Тапсырыстар тарихы' : 'История заказов'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Seller Orders Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SellerOrdersScreen(sellerId: user['userId'])));
                  },
                  icon: const Icon(Icons.assignment),
                  label: Text(Loc.lang.value == 'kz' ? 'Тапсырыстарды басқару' : 'Мои заказы (Продавец)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Admin Panel Button (only if isAdmin is true)
              if (user['isAdmin'] == true) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelScreen(admin: user)));
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: Text(Loc.lang.value == 'kz' ? 'Әкімшілік панель' : 'Админ-панель'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(Loc.tr('logout')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _editProfile(BuildContext context, Map<String, dynamic> user, VoidCallback reloadUser) async {
  final nameController = TextEditingController(text: user['name'] ?? '');
  final surnameController = TextEditingController(text: user['surname'] ?? '');
  final phoneController = TextEditingController(text: user['phone'] ?? '');
  final addressController = TextEditingController(text: user['deliveryAddress'] ?? user['address'] ?? '');
  
  Uint8List? newImageBytes;
  String? newImageName;
  String currentAvatar = user['sellerLogo'] ?? '';
  bool isUploading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(Loc.lang.value == 'kz' ? 'Профильді өңдеу' : 'Редактировать профиль'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
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
                  
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: Loc.lang.value == 'kz' ? 'Аты' : 'Имя',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: surnameController,
                    decoration: InputDecoration(
                      labelText: Loc.lang.value == 'kz' ? 'Тегі' : 'Фамилия',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: Loc.lang.value == 'kz' ? 'Телефон' : 'Телефон',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: Loc.lang.value == 'kz' ? 'Жеткізу мекенжайы' : 'Адрес доставки',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: Text(Loc.tr('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: isUploading
                    ? null
                    : () async {
                        setState(() => isUploading = true);
                        try {
                          String avatarUrl = currentAvatar;
                          if (newImageBytes != null && newImageName != null) {
                            avatarUrl = await ApiService.uploadImage(newImageBytes!, newImageName!);
                          }
                          
                          await ApiService.updateUserProfile(user['userId'], {
                            'name': nameController.text.trim(),
                            'surname': surnameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'deliveryAddress': addressController.text.trim(),
                            'sellerLogo': avatarUrl,
                          });
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('saved'))));
                            Navigator.pop(context);
                            reloadUser();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${Loc.tr('error')}: $e')));
                          }
                          setState(() => isUploading = false);
                        }
                      },
                child: Text(Loc.tr('save'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildGuestContent(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person_outlined, size: 90, color: Colors.deepOrange),
          const SizedBox(height: 20),
          Text(Loc.tr('guest'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(Loc.tr('guest_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              icon: const Icon(Icons.login),
              label: Text(Loc.tr('login')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    setState(() {
      _userFuture = ApiService.getUserById(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Loc.lang,
      builder: (context, lang, child) {
        if (widget.userId == 'guest') {
          return _buildGuestContent(context);
        }
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } 
            if (snapshot.hasError) {
              return Center(child: Text('${Loc.tr('error')}: ${snapshot.error}'));
            } 
            if (snapshot.hasData && snapshot.data?['ok'] == true) {
              final Map<String, dynamic>? userData = snapshot.data!['user']; 
              if (userData != null) {
                  return _buildProfileContent(context, userData, _loadUser); 
              }
            } 
            return Center(child: Text(Loc.tr('not_found')));
          },
        );
      },
    );
  }
}
