// profile.dart
import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'login.dart';
import 'add_product.dart';
import 'my_products.dart';
import 'localization.dart';

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
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Colors.orange),
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
              Text(
                Loc.tr('contact_info'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
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
                value: user['phone'] ?? 'N/A',
              ),

              _buildInfoCard(
                context: context,
                icon: Icons.local_shipping_outlined,
                label: Loc.tr('delivery_addr'),
                value: user['deliveryAddress'] != null && user['deliveryAddress'].toString().isNotEmpty
                    ? user['deliveryAddress'].toString()
                    : Loc.tr('not_specified'),
                onEdit: () async {
                  final ctrl = TextEditingController(text: user['deliveryAddress'] ?? '');
                  final newAddr = await showDialog<String>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(Loc.tr('delivery_addr')),
                      content: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: 'Almaty, Abay 15, apt 10',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(Loc.tr('cancel'))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                          child: Text(Loc.tr('save'), style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (newAddr != null && context.mounted) {
                    try {
                      await ApiService.updateUserAddress(user['userId'], newAddr);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Loc.tr('saved'))));
                        reloadUser();
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${Loc.tr('error')}: $e')));
                    }
                  }
                },
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
              const SizedBox(height: 16),
              
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
