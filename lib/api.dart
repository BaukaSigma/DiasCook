import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Auth ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        final isAdmin = doc.data()?['isAdmin'] == true;
        return {'ok': true, 'userId': user.uid, 'isAdmin': isAdmin, 'user': doc.data()};
      }
      return {'ok': false, 'error': 'Қате'};
    } on FirebaseAuthException catch (e) {
      return {'ok': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: data['email'], password: data['password']
      );
      final user = userCredential.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'name': data['name'],
          'surname': data['surname'],
          'phone': data['phone'],
          'email': data['email'],
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return {'ok': true, 'userId': user.uid};
      }
      return {'ok': false, 'error': 'Қате'};
    } on FirebaseAuthException catch (e) {
      return {'ok': false, 'error': e.message};
    }
  }

  // --- Өнімдер ---
  static Future<List<dynamic>> getProducts() async {
    final snapshot = await _db.collection('products').get();
    return snapshot.docs.map((d) => {'_id': d.id, ...d.data()}).toList();
  }

  static Future<Map<String, dynamic>> getProductById(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (!doc.exists) throw Exception('Табылмады');
    return {'_id': doc.id, ...doc.data()!};
  }

  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> product) async {
    final docRef = await _db.collection('products').add(product);
    return {'ok': true, 'productId': docRef.id};
  }

  static Future<Map<String, dynamic>> searchProductsWithAI(String query) async {
    // В Firebase нет встроенного AI, делаем обычный текстовый поиск
    final snapshot = await _db.collection('products').get();
    final results = snapshot.docs.where((d) {
      final title = (d.data()['title'] ?? '').toString().toLowerCase();
      return title.contains(query.toLowerCase());
    }).map((d) => {'_id': d.id, ...d.data()}).toList();
    return {'ok': true, 'results': results};
  }

  // --- Қолданушы ---
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('Табылмады');
    return {'ok': true, 'user': doc.data()};
  }

  static Future<void> updateUserAddress(String userId, String address) async {
    await _db.collection('users').doc(userId).update({'deliveryAddress': address});
  }

  static Future<List<dynamic>> getRecommendedProducts(String userId) async {
    // Firebase: просто возвращаем первые 10 товаров
    final snapshot = await _db.collection('products').limit(10).get();
    return snapshot.docs.map((d) => {'_id': d.id, ...d.data()}).toList();
  }

  // --- Әкімші (Admin) ---
  static Future<List<dynamic>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((d) => {'_id': d.id, ...d.data()}).toList();
  }

  static Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> recipe) async {
    final docRef = await _db.collection('products').add(recipe);
    return {'ok': true, 'recipeId': docRef.id};
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    return {'ok': false, 'error': 'Firebase Auth арқылы жасаңыз'};
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> user) async {
    await _db.collection('users').doc(id).update(user);
    return {'ok': true};
  }

  static Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  static Future<Map<String, dynamic>> updateRecipe(String id, Map<String, dynamic> recipe) async {
    await _db.collection('products').doc(id).update(recipe);
    return {'ok': true};
  }

  static Future<void> deleteRecipe(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // --- Таңдаулылар (Favorites) ---
  static Future<Map<String, dynamic>> toggleFavorite(String userId, String productId) async {
    final userRef = _db.collection('users').doc(userId);
    final doc = await userRef.get();
    List favorites = doc.data()?['favorites'] ?? [];
    bool isLiked = false;
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
      isLiked = true;
    }
    await userRef.update({'favorites': favorites});
    return {'ok': true, 'isLiked': isLiked, 'message': isLiked ? 'Сақталды' : 'Өшірілді'};
  }

  static Future<List<dynamic>> getFavorites(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    List favorites = doc.data()?['favorites'] ?? [];
    if (favorites.isEmpty) return [];
    
    // В Firestore нельзя делать in запрос с > 10 элементами, поэтому загружаем все и фильтруем (для диплома пойдет)
    final snapshot = await _db.collection('products').get();
    return snapshot.docs
        .where((d) => favorites.contains(d.id))
        .map((d) => {'_id': d.id, ...d.data()})
        .toList();
  }
  
  // --- Себет (Cart) ---
  static Future<Map<String, dynamic>> getCart(String userId) async {
    final snapshot = await _db.collection('users').doc(userId).collection('cart').get();
    final items = snapshot.docs.map((d) => {'_id': d.id, ...d.data()}).toList();
    
    // Подтягиваем данные продуктов
    double total = 0;
    List cartWithProducts = [];
    for (var item in items) {
      final pDoc = await _db.collection('products').doc(item['productId']).get();
      if (pDoc.exists) {
        final pData = pDoc.data()!;
        final price = pData['price'] ?? 0;
        final qty = item['quantity'] ?? 1;
        total += price * qty;
        cartWithProducts.add({
          '_id': item['_id'],
          'productId': {'_id': pDoc.id, ...pData},
          'quantity': qty,
        });
      }
    }
    return {'items': cartWithProducts, 'totalAmount': total};
  }

  static Future<Map<String, dynamic>> addToCart(String userId, String productId) async {
    final cartRef = _db.collection('users').doc(userId).collection('cart');
    final existing = await cartRef.where('productId', isEqualTo: productId).get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await doc.reference.update({'quantity': FieldValue.increment(1)});
    } else {
      await cartRef.add({'productId': productId, 'quantity': 1});
    }
    return {'ok': true};
  }

  static Future<Map<String, dynamic>> updateCartQuantity(String userId, String productId, int quantity) async {
    final cartRef = _db.collection('users').doc(userId).collection('cart');
    final existing = await cartRef.where('productId', isEqualTo: productId).get();
    if (existing.docs.isNotEmpty) {
      if (quantity <= 0) {
        await existing.docs.first.reference.delete();
      } else {
        await existing.docs.first.reference.update({'quantity': quantity});
      }
    }
    return {'ok': true};
  }

  static Future<Map<String, dynamic>> removeFromCart(String userId, String productId) async {
    final cartRef = _db.collection('users').doc(userId).collection('cart');
    final existing = await cartRef.where('productId', isEqualTo: productId).get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }
    return {'ok': true};
  }

  static Future<Map<String, dynamic>> checkoutCart(String userId) async {
    // Просто очищаем корзину
    final cartRef = _db.collection('users').doc(userId).collection('cart');
    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    return {'ok': true};
  }
}
