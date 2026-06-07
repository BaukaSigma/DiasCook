import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mock_data.dart';
import 'dart:convert';
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

    // Если нет аватарки продавца — генерируем deterministic фото по sellerId/sellerName
    final logo = (result['sellerLogo'] ?? '').toString();
    final needsReplacement = logo.isEmpty
        || logo.contains('pravatar.cc')
        || logo.contains('randomuser.me')
        || (!logo.startsWith('http') && !logo.startsWith('assets/') && !logo.startsWith('data:'));
    if (needsReplacement) {
      final nameLower = (result['sellerName'] ?? result['sellerId'] ?? 'user').toString().toLowerCase();
      
      if (nameLower.contains('данияр') || 
          nameLower.contains('бақытжан') || 
          nameLower.contains('бакытжан') || 
          nameLower.contains('арман') || 
          nameLower.contains('еркебұлан') ||
          nameLower.contains('еркебулан') ||
          nameLower.contains('seller_2') || 
          nameLower.contains('seller_4') ||
          nameLower.contains('chef')) {
        // Мужские аватарки
        const males = [
          'assets/images/avatar_arman.jpg',
          'assets/images/avatar_erkebulan.jpg',
        ];
        final idx = nameLower.codeUnits.fold(0, (a, b) => a + b) % males.length;
        result['sellerLogo'] = males[idx];
      } else {
        // Женские аватарки
        if (nameLower.contains('гүлзира') || nameLower.contains('гульзира')) {
          result['sellerLogo'] = 'assets/images/avatar_gulzira.jpg';
        } else if (nameLower.contains('назгүл') || nameLower.contains('назгул')) {
          result['sellerLogo'] = 'assets/images/avatar_nazgul.jpg';
        } else if (nameLower.contains('зарина')) {
          result['sellerLogo'] = 'assets/images/avatar_zarina.jpg';
        } else if (nameLower.contains('мәдина') || nameLower.contains('мадина')) {
          result['sellerLogo'] = 'assets/images/avatar_madina.jpg';
        } else if (nameLower.contains('айгерім') || nameLower.contains('айгерим')) {
          result['sellerLogo'] = 'assets/images/avatar_aigerim.jpg';
        } else {
          const females = [
            'assets/images/avatar_gulzira.jpg',
            'assets/images/avatar_nazgul.jpg',
            'assets/images/avatar_zarina.jpg',
            'assets/images/avatar_madina.jpg',
            'assets/images/avatar_aigerim.jpg',
          ];
          final idx = nameLower.codeUnits.fold(0, (a, b) => a + b) % females.length;
          result['sellerLogo'] = females[idx];
        }
      }
    }
    // Если адрес пустой — ставим Астана
    final loc = (result['location'] ?? '').toString();
    if (loc.isEmpty) result['location'] = 'Астана';

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
    // Mock product?
    if (id.startsWith('mock_')) {
      final mock = mockRecipes.firstWhere(
        (m) => m['_id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (mock.isNotEmpty) return _enrichProduct(id, Map<String, dynamic>.from(mock));
    }
    final doc = await _db.collection('products').doc(id).get();
    if (!doc.exists) throw Exception('Табылмады');
    return _enrichProduct(doc.id, doc.data()!);
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

  static Future<Map<String, dynamic>> checkoutCart(String userId) async {
    // Просто очищаем корзину
    final cartRef = _db.collection('users').doc(userId).collection('cart');
    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    return {'ok': true};
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
      
      // Start AI translations in background so we don't block startup
      _runAiTranslations(snapshot.docs);
    } catch (e) {
      print('Product migration error: $e');
    }
  }

  static Future<void> _runAiTranslations(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    try {
      int translatedCount = 0;
      for (var doc in docs) {
        final data = doc.data();
        final id = doc.id;
        
        if (data['isTranslatedByAI'] != true) {
          print('Translating product $id ($translatedCount/5) with Gemini in background...');
          final translations = await translateRecipeWithGemini(data);
          if (translations != null) {
            final updates = <String, dynamic>{
              'titleRu': translations['titleRu'] ?? data['titleRu'],
              'titleKz': translations['titleKz'] ?? data['titleKz'],
              'descriptionRu': translations['descriptionRu'] ?? data['descriptionRu'],
              'descriptionKz': translations['descriptionKz'] ?? data['descriptionKz'],
              'ingredientsRu': translations['ingredientsRu'] ?? data['ingredientsRu'],
              'ingredientsKz': translations['ingredientsKz'] ?? data['ingredientsKz'],
              'stepsRu': translations['stepsRu'] ?? data['stepsRu'],
              'stepsKz': translations['stepsKz'] ?? data['stepsKz'],
              'isTranslatedByAI': true,
            };
            
            if (data['title'] == null || data['title'].toString().isEmpty) {
              updates['title'] = translations['titleRu'];
            }
            if (data['description'] == null || data['description'].toString().isEmpty) {
              updates['description'] = translations['descriptionRu'];
            }
            if (data['ingredients'] == null || (data['ingredients'] as List).isEmpty) {
              updates['ingredients'] = translations['ingredientsRu'];
            }
            if (data['steps'] == null || (data['steps'] as List).isEmpty) {
              updates['steps'] = translations['stepsRu'];
            }
            
            await _db.collection('products').doc(id).update(updates);
            print('Successfully translated product $id');
            translatedCount++;
            if (translatedCount >= 5) {
              break;
            }
          }
        }
      }
    } catch (e) {
      print('AI Translation background task error: $e');
    }
  }

  static Future<Map<String, dynamic>?> translateRecipeWithGemini(Map<String, dynamic> recipe) async {
    try {
      final titleRu = recipe['titleRu'] ?? recipe['title'] ?? '';
      final titleKz = recipe['titleKz'] ?? '';
      final titleEn = recipe['titleEn'] ?? '';
      
      final descriptionRu = recipe['descriptionRu'] ?? recipe['description'] ?? '';
      final descriptionKz = recipe['descriptionKz'] ?? '';
      final descriptionEn = recipe['descriptionEn'] ?? '';
      
      final ingredients = recipe['ingredients'] is List ? List<dynamic>.from(recipe['ingredients']) : [];
      final ingredientsRu = recipe['ingredientsRu'] is List ? List<dynamic>.from(recipe['ingredientsRu']) : ingredients;
      final ingredientsEn = recipe['ingredientsEn'] is List ? List<dynamic>.from(recipe['ingredientsEn']) : [];
      
      final steps = recipe['steps'] is List ? List<dynamic>.from(recipe['steps']) : [];
      final stepsRu = recipe['stepsRu'] is List ? List<dynamic>.from(recipe['stepsRu']) : steps;
      final stepsEn = recipe['stepsEn'] is List ? List<dynamic>.from(recipe['stepsEn']) : [];

      final prompt = '''
You are a professional chef and translator fluent in English, Russian, and Kazakh.
Translate the following recipe details into high-quality culinary Russian and Kazakh.
Make sure the Kazakh translations are natural and sound like authentic Kazakh recipe terms, NOT literal machine translations (e.g. do NOT translate "hot pot" as "ыстық ыдыс", use "бұқтырылған ет" or "ыстық тағам"; do NOT translate "dip" as "батырыңыз", use "тұздық" or appropriate culinary term; translate cooking terms naturally).

Current Recipe Details:
- Title (EN): $titleEn
- Title (RU): $titleRu
- Title (KZ): $titleKz
- Description (EN): $descriptionEn
- Description (RU): $descriptionRu
- Description (KZ): $descriptionKz
- Ingredients (EN): ${ingredientsEn.join(', ')}
- Ingredients (RU): ${ingredientsRu.join(', ')}
- Steps (EN): ${stepsEn.join(' | ')}
- Steps (RU): ${stepsRu.join(' | ')}

Return the translations in a clean JSON format matching the following schema exactly (without any markdown codeblock formatting, just raw JSON string):
{
  "titleRu": "Natural Russian Title",
  "titleKz": "Натуралды қазақша атауы",
  "descriptionRu": "Natural Russian Description",
  "descriptionKz": "Натуралды қазақша сипаттамасы",
  "ingredientsRu": ["Ingredient 1 in RU", "Ingredient 2 in RU"],
  "ingredientsKz": ["Ingredient 1 in KZ", "Ingredient 2 in KZ"],
  "stepsRu": ["Step 1 in RU", "Step 2 in RU"],
  "stepsKz": ["Step 1 in KZ", "Step 2 in KZ"]
}
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textResponse = data['candidates']?[0]?['content']?[0]?['parts']?[0]?['text']?.toString() ?? '';
        final parsed = jsonDecode(textResponse.trim());
        if (parsed is Map<String, dynamic>) {
          return parsed;
        }
      }
    } catch (e) {
      print('Gemini Recipe Translation Error: $e');
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

  static const List<String> _fallbackFoodImages = [
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1496412705862-c00dbd556d45?w=500&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=500&auto=format&fit=crop',
  ];

  static String _getUniqueFoodImage(String title, String category, String id) {
    final t = title.toLowerCase();

    if (t.contains('палау') || t.contains('плов')) {
      return 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?w=500&auto=format&fit=crop';
    }
    if (t.contains('бешбармақ') || t.contains('бешбармак') || t.contains('беш')) {
      return 'https://images.unsplash.com/photo-1608897013039-887f2118cd57?w=500&auto=format&fit=crop';
    }
    if (t.contains('манты') || t.contains('manti')) {
      return 'assets/images/manty.jpg';
    }
    if (t.contains('бауырсақ') || t.contains('баурсак')) {
      return 'assets/images/baursak.jpg';
    }
    if (t.contains('қуырдақ') || t.contains('куырдак')) {
      return 'assets/images/kuirdak.jpg';
    }
    if (t.contains('самса')) {
      return 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500&auto=format&fit=crop';
    }
    if (t.contains('шашлык') || t.contains('кәуап') || t.contains('кавап')) {
      return 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=500&auto=format&fit=crop';
    }

    if (t.contains('борщ')) {
      return 'assets/images/borsh.jpg';
    }
    if (t.contains('солянка')) {
      return 'https://images.unsplash.com/photo-1547592180-85f173990554?w=500&auto=format&fit=crop';
    }
    if (t.contains('асқабақ') || t.contains('тыкв')) {
      return 'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=500&auto=format&fit=crop';
    }
    if (t.contains('уха') || t.contains('балық сорпасы') || t.contains('семга')) {
      return 'assets/images/tomyam.png';
    }
    if (t.contains('кеспе') || t.contains('лапша') || t.contains('суп') || t.contains('сорпа')) {
      return 'assets/images/soup.jpg';
    }

    if (t.contains('омлет') || t.contains('жұмыртқа') || t.contains('яйц')) {
      return 'https://images.unsplash.com/photo-1494597564530-871f2b93ac55?w=500&auto=format&fit=crop';
    }
    if (t.contains('сұлы') || t.contains('овсянка') || t.contains('каша')) {
      return 'https://images.unsplash.com/photo-1517881917430-e70dfb3610aa?w=500&auto=format&fit=crop';
    }
    if (t.contains('сырник')) {
      return 'https://images.unsplash.com/photo-1598214886806-c87b2a370944?w=500&auto=format&fit=crop';
    }
    if (t.contains('блин') || t.contains('блины') || t.contains('қаймақты блин')) {
      return 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500&auto=format&fit=crop';
    }

    if (t.contains('стейк') || t.contains('beef steak') || t.contains('рибай')) {
      return 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=500&auto=format&fit=crop';
    }
    if (t.contains('веллингтон') || t.contains('wellington')) {
      return 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop';
    }
    if (t.contains('цезарь') || t.contains('caesar')) {
      return 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=500&auto=format&fit=crop';
    }
    if (t.contains('грек') || t.contains('greek')) {
      return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop';
    }
    if (t.contains('брускетта') || t.contains('bruschetta')) {
      return 'https://images.unsplash.com/photo-1572656631137-7935297eff55?w=500&auto=format&fit=crop';
    }
    if (t.contains('хумус') || t.contains('hummus')) {
      return 'https://images.unsplash.com/photo-1577906096429-f73df2c3e273?w=500&auto=format&fit=crop';
    }
    if (t.contains('пюре') || t.contains('картоп')) {
      return 'https://images.unsplash.com/photo-1621841957884-1210fe19d66d?w=500&auto=format&fit=crop';
    }
    if (t.contains('гречка')) {
      return 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500&auto=format&fit=crop';
    }
    if (t.contains('рис') || t.contains('күріш')) {
      return 'https://images.unsplash.com/photo-1516685018646-549198525c1b?w=500&auto=format&fit=crop';
    }
    if (t.contains('карбонара') || t.contains('паста') || t.contains('pasta') || t.contains('спагетти')) {
      return 'assets/images/pasta.jpg';
    }

    if (t.contains('шоколад') || t.contains('торт') || t.contains('cake') || t.contains('пирог')) {
      if (t.contains('бал') || t.contains('мед') || t.contains('медовик')) {
        return 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500&auto=format&fit=crop';
      }
      return 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop';
    }
    if (t.contains('чизкейк') || t.contains('cheesecake')) {
      return 'https://images.unsplash.com/photo-1524351199679-46cddf530c04?w=500&auto=format&fit=crop';
    }
    if (t.contains('тирамису') || t.contains('tiramisu')) {
      return 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=500&auto=format&fit=crop';
    }
    if (t.contains('пахлава') || t.contains('baklava')) {
      return 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=500&auto=format&fit=crop';
    }

    if (t.contains('шырын') || t.contains('сок') || t.contains('апельсин')) {
      return 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=500&auto=format&fit=crop';
    }
    if (t.contains('смузи') || t.contains('smoothie')) {
      return 'https://images.unsplash.com/photo-1553530979-7ee52a2670c4?w=500&auto=format&fit=crop';
    }
    if (t.contains('чай') || t.contains('шай') || t.contains('tea')) {
      return 'assets/images/ceremony.jpg';
    }

    final c = category.toLowerCase();
    if (c.contains('таң') || c.contains('завтрак') || c.contains('breakfast')) {
      return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=500&auto=format&fit=crop';
    }
    if (c.contains('тәтті') || c.contains('десерт') || c.contains('dessert')) {
      return 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=500&auto=format&fit=crop';
    }
    if (c.contains('сусын') || c.contains('напит') || c.contains('drink') || c.contains('beverage')) {
      return 'https://images.unsplash.com/photo-1553530979-7ee52a2670c4?w=500&auto=format&fit=crop';
    }

    int hash = 0;
    final key = id.isNotEmpty ? id : title;
    for (int i = 0; i < key.length; i++) {
      hash += key.codeUnitAt(i);
    }
    return _fallbackFoodImages[hash % _fallbackFoodImages.length];
  }
}
