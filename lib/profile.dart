// profile.dart
import 'package:flutter/material.dart';
import 'package:first/api.dart';
import 'login.dart';

// Виджет для отображения единицы информации в красивой карточке
Widget _buildInfoCard({
  required BuildContext context,
  required IconData icon,
  required String label,
  required String value,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: Colors.orange.shade700, size: 28),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    ),
  );
}

// Виджет для отображения контента профиля (при успешной загрузке)
Widget _buildProfileContent(BuildContext context, Map<String, dynamic> user) {
  final fullName = '${user['name'] ?? ''} ${user['surname'] ?? ''}';
  // Стандартная высота AppBar обычно около 56.0. 
  // Мы используем это значение для расчета отступа.
  const double appBarHeight = kToolbarHeight; 

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ------------------------------------
        // Блок заголовка, аватара и градиента
        // ------------------------------------
        Container(
          // ИСПРАВЛЕНО: Устанавливаем padding сверху равный высоте системного статус-бара
          // плюс стандартная высота AppBar (56.0). Затем вычитаем высоту 
          // нашего текста (например, 20), чтобы скомпенсировать.
          // ИЛИ, проще: просто используем стандартную высоту AppBar (56) + отступ статус-бара.
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 24, // Отступ от аватара до низа градиента
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
              // ------------------------------------
              // Блок заголовка "Профиль"
              // ------------------------------------
              Padding(
                // Добавляем вертикальный отступ, чтобы имитировать центрирование в AppBar (56.0)
                // Стандартный AppBar имеет внутренний отступ, здесь мы просто добавляем
                // отступы сверху и снизу вокруг текста.
                padding: const EdgeInsets.symmetric(vertical: (appBarHeight - 20) / 2),
                child: Text(
                  'Профиль',
                  style: (Theme.of(context).appBarTheme.titleTextStyle ?? 
                          Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(
                            color: Colors.white,
                          ) ??
                      const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                ),
              ),
              // Убираем лишний SizedBox, так как вертикальный отступ теперь в Padding
              // const SizedBox(height: 30), 
              
              // Аватар и имя
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              
              // ИСПРАВЛЕНО: Добавлен горизонтальный Padding для имени и фамилии
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${user['userId'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        // ------------------------------------
        // Блок основной информации
        // ------------------------------------
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Байланыс ақпараты',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700),
              ),
              const Divider(color: Colors.orangeAccent),
              
              _buildInfoCard(
                context: context,
                icon: Icons.email_outlined,
                label: 'Электрондық пошта',
                value: user['email'] ?? 'N/A',
              ),
              
              _buildInfoCard(
                context: context,
                icon: Icons.phone_android_outlined,
                label: 'Телефон нөмірі',
                value: user['phone'] ?? 'N/A',
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка выхода
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Логика выхода
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Жүйеден шығу...')),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Шығу'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

// Виджет для отображения контента гостя
Widget _buildGuestContent(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person_outlined, size: 90, color: Colors.deepOrange),
          const SizedBox(height: 20),
          const Text('Сіз кірмегенсіз (Гость)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text(
            'Профиль деректерін көру үшін кіріңіз немесе тіркеліңіз.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Кіру'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == 'guest') {
      return _buildGuestContent(context);
    }
    
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUserById(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } 
        
        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Қате: ${snapshot.error}. Бэкендті тексеріңіз.'));
        } 
        
        // snapshot.data тексереміз және 'user' ішкі объектісінің бар-жоғын қараймыз
        if (snapshot.hasData && snapshot.data?['ok'] == true) {
          // 🎯 ДҰРЫС ШЕШІМ: 'user' кілтіндегі деректерді аламыз
          final Map<String, dynamic>? userData = snapshot.data!['user']; 
          
          if (userData != null) {
              return _buildProfileContent(context, userData); // ⬅️ Енді дұрыс деректер жіберіледі
          } else {
              return const Center(child: Text('Пайдаланушы деректері табылмады (userData null).'));
          }
        } 
        
        // Жоғарыдағы тексеруден өтпесе
        return const Center(child: Text('Пайдаланушы деректері табылмады.'));

      },
    );
  }
}