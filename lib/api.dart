// api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://localhost:3001/api'; 

  // --- Өнімдер ---
  static Future<List<dynamic>> getProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Өнімдерді жүктеу қатесі: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getProductById(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/products/$id'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Өнімді жүктеу қатесі: ${res.statusCode}');
    }
  }

  // --- Қарапайым пайдаланушылар үшін тауар қосу ---
  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> product) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Тауар қосу қатесі.');
    }
  }

  // --- ИИ көмегімен іздеу ---
  static Future<Map<String, dynamic>> searchProductsWithAI(String query) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products/ai-search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'ИИ іздеу қатесі.');
    }
  }

  // --- Қолданушы ---
  static Future<Map<String, dynamic>> getUserById(String userId) async {
      final res = await http.get(Uri.parse('$baseUrl/user/$userId'));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['ok'] == true) {
        return body; 
      } else {
        throw Exception(body['error'] ?? 'Пайдаланушыны жүктеу қатесі.');
      }
  }

  // --- Жеткізу мекенжайын жаңарту ---
  static Future<void> updateUserAddress(String userId, String address) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/$userId/address'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deliveryAddress': address}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['ok'] != true) {
      throw Exception(body['error'] ?? 'Мекенжайды сақтау қатесі.');
    }
  }

  // --- ML Рекомендациялар ---
  static Future<List<dynamic>> getRecommendedProducts(String userId) async {
    try {
      final url = '$baseUrl/products/recommended/$userId';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      throw Exception('Жүктеу қатесі (Status ${res.statusCode}): ${res.body}');
    } catch (e) {
      throw Exception('Қосылу қатесі: $e');
    }
  }

  // --- Әкімші (Admin) ---
  static Future<List<dynamic>> getAllUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/users'));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body['users'] ?? [];
    } else {
      throw Exception(body['error'] ?? 'Пайдаланушыларды жүктеу қатесі.');
    }
  }

  static Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> recipe) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/recipes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(recipe),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Рецепт қосу қатесі.');
    }
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Пайдаланушы қосу қатесі.');
    }
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> user) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Пайдаланушыны жаңарту қатесі.');
    }
  }

  static Future<void> deleteUser(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/users/$id'));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['ok'] != true) {
      throw Exception(body['error'] ?? 'Пайдаланушыны жою қатесі.');
    }
  }

  static Future<Map<String, dynamic>> updateRecipe(String id, Map<String, dynamic> recipe) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/recipes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(recipe),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Рецептті жаңарту қатесі.');
    }
  }

  static Future<void> deleteRecipe(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/recipes/$id'));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['ok'] != true) {
      throw Exception(body['error'] ?? 'Рецептті жою қатесі.');
    }
  }

  // --- Таңдаулылар (Favorites) ---
  static Future<Map<String, dynamic>> toggleFavorite(String userId, String productId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/favorites/toggle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Таңдаулыларға қосу қатесі.');
    }
  }

  static Future<List<dynamic>> getFavorites(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/favorites/$userId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Таңдаулыларды жүктеу қатесі: ${res.statusCode}');
    }
  }
  
  // --- Себет (Cart) ---
  static Future<Map<String, dynamic>> getCart(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/cart/$userId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Себетті жүктеу қатесі: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> addToCart(String userId, String productId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cart/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Себетке қосу қатесі.');
    }
  }

  static Future<Map<String, dynamic>> updateCartQuantity(String userId, String productId, int quantity) async {
    final res = await http.put(
      Uri.parse('$baseUrl/cart/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId, 'quantity': quantity}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Санды өзгерту қатесі.');
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(String userId, String productId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/cart/remove'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Себеттен жою қатесі.');
    }
  }

  static Future<Map<String, dynamic>> checkoutCart(String userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cart/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['ok'] == true) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Сатып алу қатесі.');
    }
  }
}
