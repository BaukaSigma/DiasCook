import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first/mock_data.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;


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
        final userData = doc.data() ?? {};
        final name = userData['name'] ?? '';
        final surname = userData['surname'] ?? '';
        
        // Trigger email notification in background
        EmailService.sendLoginNotification(email, '$name $surname'.trim());
        
        return {'ok': true, 'userId': user.uid, 'isAdmin': isAdmin, 'user': userData};
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

  // Нормализация категорий (транслит → правильный KZ)
  static const Map<String, String> _catNorm = {
    // Таңғы астар
    'таңертеңгілік': 'Таңғы астар',
    'таны ертенгилик': 'Таңғы астар',
    'тан ертенгiлiк': 'Таңғы астар',
    'тан ертенгилик': 'Таңғы астар',
    'таңғы астар': 'Таңғы астар',
    'breakfast': 'Таңғы астар',
    'завтрак': 'Таңғы астар',
    
    // Түскі ас
    'тускi ас': 'Түскі ас',
    'тусkі ас': 'Түскі ас',
    'обед': 'Түскі ас',
    'lunch': 'Түскі ас',
    'chicken': 'Түскі ас',
    'pasta': 'Түскі ас',
    'seafood': 'Түскі ас',
    'vegetarian': 'Түскі ас',
    'vegan': 'Түскі ас',
    'starter': 'Түскі ас',
    'miscellaneous': 'Түскі ас',
    'тагамдар': 'Түскі ас',
    'закуски': 'Түскі ас',
    'snacks': 'Түскі ас',
    'алгашкы тагам': 'Түскі ас',
    'первые блюда': 'Түскі ас',
    'appetizer': 'Түскі ас',
    'appetizers': 'Түскі ас',
    'баска': 'Түскі ас',
    'другое': 'Түскі ас',
    'other': 'Түскі ас',
    
    // Кешкі ас
    'кешкi ас': 'Кешкі ас',
    'ужин': 'Кешкі ас',
    'dinner': 'Кешкі ас',
    'beef': 'Кешкі ас',
    'pork': 'Кешкі ас',
    'lamb': 'Кешкі ас',
    'goat': 'Кешкі ас',
    
    // Тәттілер
    'татiлер': 'Тәттілер',
    'тәттілер': 'Тәттілер',
    'десерты': 'Тәттілер',
    'desserts': 'Тәттілер',
    'dessert': 'Тәттілер',
    
    // Гарнир
    'гарнир': 'Гарнир',
    'side dish': 'Гарнир',
    'side_dish': 'Гарнир',
    'side': 'Гарнир',
    
    // Сусындар
    'сусындар': 'Сусындар',
    'напитки': 'Сусындар',
    'beverage': 'Сусындар',
    'beverages': 'Сусындар',
  };

  static List<dynamic> _cleanStepsList(List<dynamic>? raw) {
    if (raw == null) return [];
    final cleaned = <String>[];
    for (var item in raw) {
      String step = item.toString().trim();
      if (step.isEmpty) continue;
      
      final prefixRegex = RegExp(
        r'^('
        r'(?:қадам|кадам|step|этап)\s*\d+\s*[\.\:\-\–\—\s]*|'
        r'\d+\s*(?:қадам|кадам|step|этап)\s*[\.\:\-\–\—\s]*|'
        r'\d+[\.\)\:\-\–\—\s]+\s*'
        r')',
        caseSensitive: false,
      );
      
      while (prefixRegex.hasMatch(step)) {
        step = step.replaceFirst(prefixRegex, '').trim();
      }
      
      if (step.isNotEmpty) {
        step = step[0].toUpperCase() + step.substring(1);
        cleaned.add(step);
      }
    }
    return cleaned;
  }

  static String normalizeAstanaAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Астана';
    return trimmed
        .replaceAll('Алматы', 'Астана')
        .replaceAll('алматы', 'Астана')
        .replaceAll('Almaty', 'Astana')
        .replaceAll('almaty', 'Astana');
  }


  // --- Хелпер: обогащение продукта (аватарка, адрес, категория) ---
  static Map<String, dynamic> _enrichProduct(String id, Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from({'_id': id, ...data});

    // Clean steps lists if they exist
    if (result['steps'] is List) {
      result['steps'] = _cleanStepsList(result['steps']);
    }
    if (result['stepsRu'] is List) {
      result['stepsRu'] = _cleanStepsList(result['stepsRu']);
    }
    if (result['stepsKz'] is List) {
      result['stepsKz'] = _cleanStepsList(result['stepsKz']);
    }
    if (result['stepsEn'] is List) {
      result['stepsEn'] = _cleanStepsList(result['stepsEn']);
    }

    // Нормализуем категорию
    final rawCat = (result['category'] ?? '').toString();
    final normalized = _catNorm[rawCat.toLowerCase()];
    if (normalized != null) result['category'] = normalized;

    // Назначаем аватарки только для встроенных демо-продавцов.
    // Реальные пользователи не получают случайных лиц и отображаются с инициалами.
    final sellerId = (result['sellerId'] ?? '').toString();
    final logo = (result['sellerLogo'] ?? '').toString();
    
    if (sellerId == 'gulzira') {
      result['sellerLogo'] = 'assets/images/avatar_gulzira.jpg';
    } else if (sellerId == 'nazgul') {
      result['sellerLogo'] = 'assets/images/avatar_nazgul.jpg';
    } else if (sellerId == 'zarina') {
      result['sellerLogo'] = 'assets/images/avatar_zarina.jpg';
    } else if (sellerId == 'madina') {
      result['sellerLogo'] = 'assets/images/avatar_madina.jpg';
    } else if (sellerId == 'aigerim') {
      result['sellerLogo'] = 'assets/images/avatar_aigerim.jpg';
    } else if (sellerId == 'arman') {
      result['sellerLogo'] = 'assets/images/avatar_arman.jpg';
    } else if (sellerId == 'chef_erkebulan') {
      result['sellerLogo'] = 'assets/images/avatar_erkebulan.jpg';
    } else if (logo.isEmpty || 
               logo.contains('pravatar.cc') || 
               logo.contains('randomuser.me') || 
               (!logo.startsWith('http') && !logo.startsWith('assets/') && !logo.startsWith('data:'))) {
      result['sellerLogo'] = '';
    }
    // Если адрес пустой или не астанинский — показываем Астану.
    final loc = (result['location'] ?? '').toString();
    result['location'] = normalizeAstanaAddress(loc);
    final fullAddress = (result['fullAddress'] ?? '').toString();
    if (fullAddress.isNotEmpty) {
      result['fullAddress'] = normalizeAstanaAddress(fullAddress);
    }

    // Уникальные/не дублирующиеся картинки для блюд
    final imgUrl = (result['imageUrl'] ?? '').toString();
    if (imgUrl.isEmpty || 
        imgUrl == 'assets/images/national.jpg' || 
        imgUrl == 'assets/images/soup.jpg' || 
        imgUrl == 'assets/images/borsh.jpg') {
      final title = (result['title'] ?? result['titleRu'] ?? '').toString();
      final category = (result['category'] ?? '').toString();
      result['imageUrl'] = _getUniqueFoodImage(title, category, id);
    }

    return result;
  }

  // --- Өнімдер ---
  static Future<List<dynamic>> getProducts() async {
    List<dynamic> firebaseProducts = [];
    try {
      final snapshot = await _db.collection('products').get().timeout(const Duration(seconds: 4));
      firebaseProducts = snapshot.docs.map((d) => _enrichProduct(d.id, d.data())).toList();
    } catch (e) {
      print('Firebase products load error: $e');
    }
    // Добавляем mock-блюда (они всегда есть, с правильными категориями)
    final firebaseIds = firebaseProducts.map((p) => p['_id'].toString()).toSet();
    final mocks = mockRecipes
        .map((m) => _enrichProduct(m['_id'] as String, Map<String, dynamic>.from(m)))
        .where((m) => !firebaseIds.contains(m['_id'].toString()))
        .toList();
    return [...firebaseProducts, ...mocks];
  }

  static Future<Map<String, dynamic>> getProductById(String id) async {
    Map<String, dynamic> productData;
    if (id.startsWith('mock_')) {
      final mock = mockRecipes.firstWhere(
        (m) => m['_id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (mock.isEmpty) throw Exception('Табылмады');
      productData = Map<String, dynamic>.from(mock);
    } else {
      final doc = await _db.collection('products').doc(id).get();
      if (!doc.exists) throw Exception('Табылмады');
      productData = Map<String, dynamic>.from(doc.data()!);
    }

    try {
      final reviewsSnap = await _db.collection('products').doc(id).collection('reviews').get();
      if (reviewsSnap.docs.isNotEmpty) {
        double sum = 0;
        for (var doc in reviewsSnap.docs) {
          sum += (doc.data()['rating'] ?? 0.0).toDouble();
        }
        productData['rating'] = sum / reviewsSnap.docs.length;
        productData['reviewsCount'] = reviewsSnap.docs.length;
      }
    } catch (e) {
      print('Error fetching reviews for product: $e');
    }

    return _enrichProduct(id, productData);
  }

  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> product) async {
    final docRef = await _db.collection('products').add(product);
    return {'ok': true, 'productId': docRef.id};
  }

  static const String _geminiApiKey = 'AIzaSyDkQaYKuits8p-rC5PCmda7onytq-D_x7M';

  static Future<Map<String, dynamic>> searchProductsWithAI(String query) async {
    try {
      final allProducts = await getProducts();
      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        return {'ok': true, 'results': []};
      }

      // Подготавливаем облегченную версию рецептов для контекста ИИ
      final simplifiedProducts = allProducts.map((p) {
        return {
          'id': p['_id'].toString(),
          'title': (p['title'] ?? '').toString(),
          'titleRu': (p['titleRu'] ?? '').toString(),
          'titleKz': (p['titleKz'] ?? '').toString(),
          'category': (p['category'] ?? '').toString(),
          'description': (p['description'] ?? '').toString(),
        };
      }).toList();

      final prompt = '''
Пайдаланушы мына сұраныс бойынша тағам іздеп жатыр: "$query".
Біздің мәліметтер базасындағы тағамдар тізімі (JSON форматында):
${jsonEncode(simplifiedProducts)}

Тапсырма: Пайдаланушының сұранысына және оның астарлы мағынасына (мысалы, егер "сорпа" десе, барлық сорпаларды; "ет" десе, ет тағамдарын; "тәтті" немесе "десерт" десе, тәттілерді) ең сәйкес келетін 1-ден 8-ге дейінгі тағамдарды таңда. Тек нақты немесе синонимдік сәйкестіктерді таңда.
Жауап ретінде тек қана таңдалған тағамдардың ID-лері бар таза JSON массив қайтар, басқа ештеңе жазба (мысалы: ["mock_1", "mock_6"]). Егер мүлдем ештеңе сәйкес келмесе, бос массив [] қайтар.
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey'
      );
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textResponse = data['candidates']?[0]?['content']?[0]?['parts']?[0]?['text']?.toString() ?? '';
        final parsedIds = jsonDecode(textResponse.trim());
        if (parsedIds is List) {
          final idsSet = parsedIds.map((id) => id.toString()).toSet();
          final results = allProducts.where((p) => idsSet.contains(p['_id'].toString())).toList();
          if (results.isNotEmpty) {
            return {'ok': true, 'results': results, 'fromAi': true};
          }
        }
      }
    } catch (e) {
      print('Gemini AI Search Error: $e');
    }

    // Резервный поиск (Умный поиск по ключевым словам)
    final allProducts = await getProducts();
    final q = query.toLowerCase().trim();
    final keywords = q.split(RegExp(r'\s+')).where((kw) => kw.length > 1).toList();
    if (keywords.isEmpty) {
      keywords.add(q);
    }

    final scored = allProducts.map((p) {
      int score = 0;
      final title = (p['title'] ?? '').toString().toLowerCase();
      final titleRu = (p['titleRu'] ?? '').toString().toLowerCase();
      final titleKz = (p['titleKz'] ?? '').toString().toLowerCase();
      final desc = (p['description'] ?? '').toString().toLowerCase();
      final descRu = (p['descriptionRu'] ?? '').toString().toLowerCase();
      final descKz = (p['descriptionKz'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();

      for (var kw in keywords) {
        if (title.contains(kw) || titleRu.contains(kw) || titleKz.contains(kw)) {
          score += 10;
        }
        if (category.contains(kw)) {
          score += 5;
        }
        if (desc.contains(kw) || descRu.contains(kw) || descKz.contains(kw)) {
          score += 2;
        }
      }
      return {'product': p, 'score': score};
    }).where((item) => (item['score'] as int) > 0).toList();

    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final results = scored.map((item) => item['product']).toList();

    return {'ok': true, 'results': results, 'fromAi': false};
  }

  // --- Қолданушы ---
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) {
      final user = _auth.currentUser;
      final email = user?.email ?? 'user@example.com';
      final defaultData = {
        'name': 'Пайдаланушы',
        'surname': '',
        'email': email,
        'phone': '',
        'userId': userId,
      };
      await _db.collection('users').doc(userId).set(defaultData);
      return {'ok': true, 'user': defaultData};
    }
    return {'ok': true, 'user': {'userId': doc.id, ...?doc.data()}};
  }

  static Future<void> updateUserAddress(String userId, String address) async {
    await _db.collection('users').doc(userId).update({'deliveryAddress': address});
  }

  static Future<List<dynamic>> getRecommendedProducts(String userId) async {
    return getProducts();
  }

  static Future<List<dynamic>> getProductsByUserId(String userId) async {
    final snapshot = await _db.collection('products')
        .where('sellerId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((d) => _enrichProduct(d.id, d.data())).toList();
  }

  static Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
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
        .map((d) => _enrichProduct(d.id, d.data()))
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
          'productId': _enrichProduct(pDoc.id, pData),
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

  static Future<Map<String, dynamic>> checkoutCart(
    String userId,
    String deliveryType,
    String deliveryAddress,
    String paymentMethod,
    String cardNo,
  ) async {
    try {
      final cartSnapshot = await _db.collection('users').doc(userId).collection('cart').get();
      if (cartSnapshot.docs.isEmpty) {
        return {'ok': false, 'error': 'Себет бос'};
      }
      
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'ok': false, 'error': 'Пайдаланушы табылмады'};
      }
      final userData = userDoc.data()!;
      final userName = '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim();
      final userEmail = userData['email'] ?? '';
      final userPhone = userData['phone'] ?? '';
      
      final List<Map<String, dynamic>> resolvedItems = [];
      for (var doc in cartSnapshot.docs) {
        final cartData = doc.data();
        final productId = cartData['productId'];
        final quantity = cartData['quantity'] ?? 1;
        
        final pDoc = await getProductById(productId);
        resolvedItems.add({
          'productId': productId,
          'title': pDoc['title'] ?? pDoc['titleRu'] ?? '',
          'price': pDoc['price'] ?? 0,
          'quantity': quantity,
          'imageUrl': pDoc['imageUrl'] ?? '',
          'sellerId': pDoc['sellerId'] ?? 'guest',
        });
      }
      
      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (var item in resolvedItems) {
        final sellerId = item['sellerId'] as String;
        groups.putIfAbsent(sellerId, () => []).add(item);
      }
      
      for (var entry in groups.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;
        
        double sellerTotalPrice = 0;
        for (var item in sellerItems) {
          sellerTotalPrice += ((item['price'] as num).toDouble() * (item['quantity'] as num).toDouble());
        }
        
        final orderRef = _db.collection('orders').doc();
        final orderId = orderRef.id;
        
        final orderData = {
          'orderId': orderId,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'userPhone': userPhone,
          'deliveryAddress': deliveryAddress,
          'deliveryType': deliveryType,
          'items': sellerItems,
          'totalPrice': sellerTotalPrice,
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentMethod == 'Cash' ? 'pending' : 'confirmed',
          'orderStatus': 'accepted',
          'sellerId': sellerId,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await orderRef.set(orderData);
        
        if (userEmail.isNotEmpty) {
          EmailService.sendOrderInvoiceEmail(userEmail, orderData);
        }
      }
      
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }
      
      return {'ok': true};
    } catch (e) {
      print('Checkout error: $e');
      return {'ok': false, 'error': e.toString()};
    }
  }

  // --- Миграция базы данных (Астана, описание/шаги, цены) ---
  static Future<void> migrateProducts() async {
    try {
      final snapshot = await _db.collection('products').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        
        bool needsUpdate = false;
        final updates = <String, dynamic>{};
        
        // 1. Проверяем город (Астана)
        final location = data['location']?.toString() ?? '';
        if (location == 'Алматы' || location.isEmpty) {
          updates['location'] = 'Астана';
          needsUpdate = true;
        }
        
        // 2. Проверяем адрес доставки продавца
        final fullAddress = data['fullAddress']?.toString() ?? '';
        if (fullAddress.contains('Алматы') || fullAddress.isEmpty) {
          String newAddr = fullAddress.replaceAll('Алматы', 'Астана');
          if (newAddr.isEmpty) {
            newAddr = 'пр. Мангилик Ел, д. 28, Астана';
          }
          updates['fullAddress'] = newAddr;
          needsUpdate = true;
        }

        // 3. Исправляем цены в БД (чистые сотни)
        final price = data['price'];
        if (price != null) {
          final roundedPrice = ((price.toDouble() / 100).round() * 100).toInt();
          if (price != roundedPrice) {
            updates['price'] = roundedPrice;
            needsUpdate = true;
          }
        }
        
        // 4. Разделение Описание / Как приготовить (если они одинаковые)
        final descRu = data['descriptionRu']?.toString() ?? data['description']?.toString() ?? '';
        final stepsRuList = data['stepsRu'] is List ? List<dynamic>.from(data['stepsRu']) : <dynamic>[];
        
        if (stepsRuList.length == 1 && stepsRuList.first.toString().trim() == descRu.trim()) {
          final titleRu = data['titleRu']?.toString() ?? data['title']?.toString() ?? 'Блюдо';
          final titleKz = data['titleKz']?.toString() ?? 'Тағам';
          final titleEn = data['titleEn']?.toString() ?? 'Dish';
          
          final descEn = data['descriptionEn']?.toString() ?? '';
          final descKz = data['descriptionKz']?.toString() ?? '';
          
          final stepsRu = _splitStringToSteps(descRu);
          final stepsEn = _splitStringToSteps(descEn);
          final stepsKz = _splitStringToSteps(descKz);
          
          updates['description'] = 'Вкусное традиционное блюдо "$titleRu", приготовленное из свежих ингредиентов по классическому рецепту.';
          updates['descriptionRu'] = 'Вкусное традиционное блюдо "$titleRu", приготовленное из свежих ингредиентов по классическому рецепту.';
          updates['descriptionEn'] = 'A delicious traditional $titleEn prepared with fresh ingredients according to a classic recipe.';
          updates['descriptionKz'] = 'Классикалық рецепт бойынша жаңа піскен ингредиенттерден дайындалған дәмді "$titleKz" дәстүрлі тағамы.';
          
          updates['steps'] = stepsRu.isNotEmpty ? stepsRu : [descRu];
          updates['stepsRu'] = stepsRu.isNotEmpty ? stepsRu : [descRu];
          updates['stepsEn'] = stepsEn.isNotEmpty ? stepsEn : [descEn];
          updates['stepsKz'] = stepsKz.isNotEmpty ? stepsKz : [descKz];
          
          needsUpdate = true;
        }
        
        // 5. Исправляем дубликаты картинок в БД
        final imgUrl = (data['imageUrl'] ?? '').toString();
        if (imgUrl.isEmpty || 
            imgUrl == 'assets/images/national.jpg' || 
            imgUrl == 'assets/images/soup.jpg' || 
            imgUrl == 'assets/images/borsh.jpg') {
          final title = (data['title'] ?? data['titleRu'] ?? '').toString();
          final category = (data['category'] ?? '').toString();
          final newImg = _getUniqueFoodImage(title, category, id);
          if (imgUrl != newImg) {
            updates['imageUrl'] = newImg;
            needsUpdate = true;
          }
        }
        
        if (needsUpdate) {
          await _db.collection('products').doc(id).update(updates);
          print('Migrated product $id');
        }
      }
      print('Product migration complete.');
      
      // Gemini API is blocked, translations are pre-migrated statically.
      // _runAiTranslations(snapshot.docs);
    } catch (e) {
      print('Product migration error: $e');
    }
  }

  static Future<void> _runAiTranslations(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    try {
      final untranslated = docs.where((doc) {
        final data = doc.data();
        final titleKz = (data['titleKz'] ?? '').toString().toLowerCase();
        final descKz = (data['descriptionKz'] ?? '').toString().toLowerCase();
        
        final hasMachineTranslation = titleKz.contains('ыстық ыдыс') || 
                                     descKz.contains('ыстық ыдыс') ||
                                     titleKz.contains('батырыңыз') ||
                                     descKz.contains('батырыңыз');
                                     
        return data['isTranslatedByAI'] != true || hasMachineTranslation;
      }).toList();

      if (untranslated.isEmpty) {
        print('All products are already translated by Gemini.');
        return;
      }

      print('Starting Gemini batch translations for ${untranslated.length} products...');

      final batchSize = 5;
      for (int i = 0; i < untranslated.length; i += batchSize) {
        final endIdx = i + batchSize > untranslated.length ? untranslated.length : i + batchSize;
        final batch = untranslated.sublist(i, endIdx);
        
        final batchData = batch.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'titleEn': data['titleEn'] ?? '',
            'titleRu': data['titleRu'] ?? data['title'] ?? '',
            'descriptionEn': data['descriptionEn'] ?? '',
            'ingredientsEn': data['ingredientsEn'] ?? data['ingredients'] ?? [],
            'stepsEn': data['stepsEn'] ?? data['steps'] ?? [],
          };
        }).toList();

        final prompt = '''
You are a professional chef and translator fluent in English, Russian, and Kazakh.
Translate the following batch of ${batch.length} recipes into high-quality culinary Russian and Kazakh.
Make sure the Kazakh translations are natural and sound like authentic Kazakh recipe terms, NOT literal machine translations (e.g. do NOT translate "hot pot" as "ыстық ыдыс", use "бұқтырылған ет" or "сорпа/ыстық тағам" or appropriate term; do NOT translate "dip" as "батырыңыз" or "батыру", use "тұздық" or "соус"; translate cooking terms naturally).
For example, "Beans and Sausage Hotpot" should translate in Kazakh to something natural like "Бұршақ қосылған шұжық бұқтырмасы" or similar, NOT "Бұршақ және шұжық ыстық ыдыс".

Recipes to translate:
${jsonEncode(batchData)}

Return the translations in a JSON array matching the following schema exactly (without any markdown formatting or codeblocks):
[
  {
    "id": "recipe_id",
    "titleRu": "Natural Russian Title",
    "titleKz": "Натуралды қазақша атауы",
    "descriptionRu": "Natural Russian Description",
    "descriptionKz": "Натуралды қазақша сипаттамасы",
    "ingredientsRu": ["Ingredient 1 in RU", "Ingredient 2 in RU"],
    "ingredientsKz": ["Ingredient 1 in KZ", "Ingredient 2 in KZ"],
    "stepsRu": ["Step 1 in RU", "Step 2 in RU"],
    "stepsKz": ["Step 1 in KZ", "Step 2 in KZ"]
  }
]
''';

        print('Sending batch ${i ~/ batchSize + 1} to Gemini...');
        final translations = await _callGeminiBatch(prompt);
        if (translations != null && translations is List) {
          for (var t in translations) {
            if (t is Map) {
              final id = t['id']?.toString();
              if (id == null) continue;
              final origDoc = batch.firstWhere((doc) => doc.id == id);
              final origData = origDoc.data();

              final updates = <String, dynamic>{
                'titleRu': t['titleRu'] ?? origData['titleRu'],
                'titleKz': t['titleKz'] ?? origData['titleKz'],
                'descriptionRu': t['descriptionRu'] ?? origData['descriptionRu'],
                'descriptionKz': t['descriptionKz'] ?? origData['descriptionKz'],
                'ingredientsRu': t['ingredientsRu'] ?? origData['ingredientsRu'],
                'ingredientsKz': t['ingredientsKz'] ?? origData['ingredientsKz'],
                'stepsRu': t['stepsRu'] ?? origData['stepsRu'],
                'stepsKz': t['stepsKz'] ?? origData['stepsKz'],
                'isTranslatedByAI': true,
              };

              if (origData['title'] == null || origData['title'].toString().isEmpty || origData['title'] == origData['titleEn']) {
                updates['title'] = t['titleRu'];
              }
              if (origData['description'] == null || origData['description'].toString().isEmpty || origData['description'] == origData['descriptionEn']) {
                updates['description'] = t['descriptionRu'];
              }
              if (origData['ingredients'] == null || (origData['ingredients'] as List).isEmpty) {
                updates['ingredients'] = t['ingredientsRu'];
              }
              if (origData['steps'] == null || (origData['steps'] as List).isEmpty) {
                updates['steps'] = t['stepsRu'];
              }

              await _db.collection('products').doc(id).update(updates);
              print('  Updated product $id -> ${t['titleKz']}');
            }
          }
        }

        // Wait between batches to respect rate limits
        await Future.delayed(const Duration(seconds: 8));
      }
      print('Batch translation task completed.');
    } catch (e) {
      print('AI Batch Translation background task error: $e');
    }
  }

  static Future<dynamic> _callGeminiBatch(String prompt) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey'
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textResponse = data['candidates']?[0]?['content']?[0]?['parts']?[0]?['text']?.toString() ?? '';
        return jsonDecode(textResponse.trim());
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Gemini Batch API Call Error: $e');
    }
    return null;
  }

  static List<String> _splitStringToSteps(String text) {
    if (text.isEmpty) return [];
    var blocks = text.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (blocks.length <= 1) {
      blocks = text.split(RegExp(r'\.\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      blocks = blocks.map((s) => s.endsWith('.') ? s : '$s.').toList();
    }
    return blocks.where((s) => s.length > 5).toList();
  }

  static String _getUniqueFoodImage(String title, String category, String id) {
    final key = id.isNotEmpty ? id : title;
    final lockVal = key.hashCode.abs() % 10000;
    
    // Normalize query tag based on category
    String tag = 'food';
    final c = category.toLowerCase();
    if (c.contains('таң') || c.contains('завтрак') || c.contains('breakfast')) {
      tag = 'breakfast,pancake';
    } else if (c.contains('тәтті') || c.contains('десерт') || c.contains('dessert')) {
      tag = 'dessert,cake';
    } else if (c.contains('сусын') || c.contains('напит') || c.contains('drink') || c.contains('beverage')) {
      tag = 'beverage,juice';
    } else if (c.contains('кешкі') || c.contains('ужин') || c.contains('dinner') || c.contains('beef') || c.contains('meat')) {
      tag = 'steak,meat';
    } else if (c.contains('гарнир') || c.contains('side')) {
      tag = 'salad,rice';
    } else if (c.contains('түскі') || c.contains('обед') || c.contains('lunch') || c.contains('soup')) {
      tag = 'soup,curry';
    }
    
    return 'https://loremflickr.com/500/500/$tag?lock=$lockVal';
  }

  // --- Profile, Orders, Reviews, Ratings, Admin, and Image Upload Helpers ---

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return {};
    return doc.data()!;
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => {'userId': d.id, '_id': d.id, ...d.data()}).toList();
  }

  static Future<void> updateUserRole(String userId, bool isAdmin) async {
    await _db.collection('users').doc(userId).update({'isAdmin': isAdmin});
  }

  static Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    final snap = await _db.collection('orders').where('userId', isEqualTo: userId).get();
    final list = snap.docs.map((d) => d.data()).toList();
    list.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  static Future<List<Map<String, dynamic>>> getSellerOrders(String sellerId) async {
    final snap = await _db.collection('orders').where('sellerId', isEqualTo: sellerId).get();
    final list = snap.docs.map((d) => d.data()).toList();
    list.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'orderStatus': newStatus,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    final snap = await _db.collection('orders').get();
    final list = snap.docs.map((d) => d.data()).toList();
    list.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  static Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    final snap = await _db.collection('products').doc(productId).collection('reviews').get();
    final list = snap.docs.map((d) => {'_id': d.id, ...d.data()}).toList();
    list.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  static Future<void> addProductReview(String productId, String userId, String userName, double rating, String comment) async {
    if (productId.startsWith('mock_')) {
      final pDoc = await _db.collection('products').doc(productId).get();
      if (!pDoc.exists) {
        final mock = mockRecipes.firstWhere((m) => m['_id'] == productId, orElse: () => {});
        if (mock.isNotEmpty) {
          await _db.collection('products').doc(productId).set(Map<String, dynamic>.from(mock));
        }
      }
    }

    await _db.collection('products').doc(productId).collection('reviews').add({
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final reviewsSnap = await _db.collection('products').doc(productId).collection('reviews').get();
    double sum = 0;
    for (var doc in reviewsSnap.docs) {
      sum += (doc.data()['rating'] ?? 0.0).toDouble();
    }
    final avgRating = sum / reviewsSnap.docs.length;

    await _db.collection('products').doc(productId).update({
      'rating': avgRating,
      'reviewsCount': reviewsSnap.docs.length,
    });
  }

  static Future<double> getSellerRating(String sellerId) async {
    final allProducts = await getProducts();
    final sellerProducts = allProducts.where((p) => p['sellerId'] == sellerId).toList();
    if (sellerProducts.isEmpty) return 0.0;

    double sum = 0;
    int count = 0;
    for (var p in sellerProducts) {
      final rating = (p['rating'] ?? 0.0).toDouble();
      if (rating > 0) {
        sum += rating;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  static Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final ext = fileName.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    final docRef = await _db.collection('product_images').add({
      'data': dataUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return 'firestore_image:${docRef.id}';
  }
}

class EmailService {
  static const String _backendUrl = 'http://localhost:3001';

  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String html,
    String text = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/send-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'text': text,
          'html': html,
        }),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Email sending failed: $e');
      return false;
    }
  }

  static Future<void> sendOrderInvoiceEmail(String toEmail, Map<String, dynamic> order) async {
    final orderId = order['orderId'];
    final itemsList = order['items'] as List;
    final totalPrice = order['totalPrice'];
    final deliveryType = order['deliveryType'] == 'pickup' ? 'Самовывоз' : 'Доставка';

    String itemsHtml = '';
    for (var item in itemsList) {
      itemsHtml += '<li>${item["title"]} - ${item["quantity"]} шт. (${item["price"]} ₸)</li>';
    }

    final html = '''
      <h2>Рахмет! Сіздің тапсырысыңыз қабылданды.</h2>
      <p>Тапсырыс нөмірі: <strong>#$orderId</strong></p>
      <p>Алу түрі: <strong>$deliveryType</strong></p>
      <ul>$itemsHtml</ul>
      <p>Жалпы сомасы: <strong>$totalPrice ₸</strong></p>
      <p>Жақында біздің сатушы сізбен байланысады.</p>
    ''';

    await sendEmail(
      to: toEmail,
      subject: 'Тапсырыс қабылданды #$orderId',
      html: html,
      text: 'Сіздің тапсырысыңыз қабылданды #$orderId. Жалпы сомасы: $totalPrice ₸',
    );
  }

  static Future<void> sendLoginNotification(String toEmail, String userName) async {
    final html = '''
      <h2>Сәлеметсіз бе, $userName!</h2>
      <p>Сіз өзіңіздің CookPad / DiasCook аккаунтыңызға кірдіңіз.</p>
      <p>Егер бұл сіз болмасаңыз, құпия сөзіңізді тезірек ауыстырыңыз.</p>
    ''';

    await sendEmail(
      to: toEmail,
      subject: 'Аккаунтқа кіру туралы хабарлама',
      html: html,
      text: 'Сіз CookPad аккаунтыңызға сәтті кірдіңіз.',
    );
  }
}
