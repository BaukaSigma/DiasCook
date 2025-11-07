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

  // --- Қолданушы ---
  static Future<Map<String, dynamic>> getUserById(String userId) async {
      final res = await http.get(Uri.parse('$baseUrl/user/$userId')); // ✅ Дұрыс, 'user' қолданылған
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['ok'] == true) { // 👈 Бұл жерде 'ok: true' тексеруі дұрыс
        return body; 
      } else {
        throw Exception(body['error'] ?? 'Пайдаланушыны жүктеу қатесі.');
      }
  }


  // --- Себет (Cart) Функциялары ---
  
  // 1. Себеттегі тауарларды алу
  static Future<List<dynamic>> getCart(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/cart/$userId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Себетті жүктеу қатесі: ${res.statusCode}');
    }
  }

  // 2. Себетке тауар қосу (home.dart-та қолданылады)
  static Future<Map<String, dynamic>> addToCart(String userId, String productId, int quantity) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cart/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId, 'quantity': quantity}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {'ok': true, 'message': body['message']};
    } else {
      throw Exception(body['error'] ?? 'Себетке қосу қатесі.');
    }
  }

  // 3. Тауардың санын өзгерту (cart.dart-та қолданылады)
  static Future<Map<String, dynamic>> updateCartItemQuantity(String userId, String productId, int quantity) async {
    final res = await http.put(
      Uri.parse('$baseUrl/cart/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId, 'quantity': quantity}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {'ok': true, 'message': body['message']};
    } else {
      throw Exception(body['error'] ?? 'Санын өзгерту қатесі.');
    }
  }

  // 4. Тауарды себеттен жою (cart.dart-та қолданылады)
  static Future<Map<String, dynamic>> removeCartItem(String userId, String productId) async {
    // 🚨 ТЕКСЕРУ: Бэкендте DELETE request-ті body арқылы жіберуіңіз керек
    final req = http.Request('DELETE', Uri.parse('$baseUrl/cart/remove'));
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode({'userId': userId, 'productId': productId});
    
    final res = await req.send();
    final body = jsonDecode(await res.stream.bytesToString());

    if (res.statusCode == 200) {
      return {'ok': true, 'message': body['message']};
    } else {
      throw Exception(body['error'] ?? 'Жою қатесі.');
    }
  }
  
  // 5. Тапсырыс беру функциясы (cart.dart-та қолданылады)
  static Future<Map<String, dynamic>> checkout(String userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {'ok': true, 'message': body['message']};
    } else {
      throw Exception(body['error'] ?? 'Тапсырыс беру қатесі.');
    }
  }
}