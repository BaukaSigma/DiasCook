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



  static String normalizeAstanaAddress(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return 'ул. Кабанбай Батыра, д. 17, Астана';
    
    // If it contains Almaty Orbitas specifically:
    if (trimmed.contains('Орбита-2') || trimmed.contains('Орбита')) {
      trimmed = trimmed
          .replaceAll(RegExp(r'мкр\.\s*Орбита-?\d*,?\s*'), 'ул. Кабанбай Батыра, ')
          .replaceAll(RegExp(r'Орбита-?\d*,?\s*'), 'ул. Кабанбай Батыра, ');
    }
    
    trimmed = trimmed
        .replaceAll('Алматы', 'Астана')
        .replaceAll('алматы', 'Астана')
        .replaceAll('Almaty', 'Astana')
        .replaceAll('almaty', 'Astana');
        
    // Ensure "Астана" or "Astana" is in the address
    if (!trimmed.contains('Астана') && !trimmed.contains('Astana')) {
      trimmed = '$trimmed, Астана';
    }
    
    // Clean up any double spaces/commas
    trimmed = trimmed.replaceAll(RegExp(r',\s*,'), ',');
    return trimmed;
  }

  static List<String> cleanAndSplitCamelCase(String text) {
    if (text.isEmpty) return [];
    
    // Split camel case words stuck together, e.g. "соусСливочная" -> "соус\nСливочная"
    var cleaned = text.replaceAllMapped(RegExp(r'([а-яa-z])([А-ЯA-Z])'), (m) => '${m[1]}\n${m[2]}');
    cleaned = cleaned.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}\n${m[2]}');
    
    return cleaned
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<dynamic> _cleanList(List<dynamic>? raw) {
    if (raw == null) return [];
    final cleaned = <String>[];
    for (var item in raw) {
      final str = item.toString().trim();
      if (str.isEmpty) continue;
      final parts = cleanAndSplitCamelCase(str);
      cleaned.addAll(parts);
    }
    return cleaned;
  }

  // --- Хелпер: обогащение продукта (аватарка, адрес, категория) ---
  static Map<String, dynamic> _enrichProduct(String id, Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from({'_id': id, ...data});

    // Clean steps lists if they exist
    if (result['steps'] is List) {
      result['steps'] = _cleanList(result['steps']);
    }
    if (result['stepsRu'] is List) {
      result['stepsRu'] = _cleanList(result['stepsRu']);
    }
    if (result['stepsKz'] is List) {
      result['stepsKz'] = _cleanList(result['stepsKz']);
    }
    if (result['stepsEn'] is List) {
      result['stepsEn'] = _cleanList(result['stepsEn']);
    }

    // Clean ingredients lists if they exist
    if (result['ingredients'] is List) {
      result['ingredients'] = _cleanList(result['ingredients']);
    }
    if (result['ingredientsRu'] is List) {
      result['ingredientsRu'] = _cleanList(result['ingredientsRu']);
    }
    if (result['ingredientsKz'] is List) {
      result['ingredientsKz'] = _cleanList(result['ingredientsKz']);
    }
    if (result['ingredientsEn'] is List) {
      result['ingredientsEn'] = _cleanList(result['ingredientsEn']);
    }

    // Нормализуем категорию
    final rawCat = (result['category'] ?? '').toString();
    final normalized = _catNorm[rawCat.toLowerCase()];
    if (normalized != null) result['category'] = normalized;

    // Назначаем аватарки только для встроенных демо-продавцов.
    // Реальные пользователи не получают случайных лиц и отображаются с инициалами.
    final sellerId = (result['sellerId'] ?? '').toString();
    final logo = (result['sellerLogo'] ?? '').toString();
    
    final sId = sellerId.toLowerCase().trim();
    final sName = (result['sellerName'] ?? '').toString().toLowerCase().trim();
    
    if (logo.startsWith('firestore_image:') || logo.startsWith('data:')) {
      // Keep custom uploaded logo
    } else if (sId == 'gulzira' || sId == 'гүлзира' || sName.contains('гүлзира') || sName.contains('gulzira')) {
      result['sellerLogo'] = 'assets/images/avatar_gulzira.jpg';
    } else if (sId == 'nazgul' || sId == 'назгүл' || sName.contains('назгүл') || sName.contains('nazgul')) {
      result['sellerLogo'] = 'assets/images/avatar_nazgul.jpg';
    } else if (sId == 'zarina' || sId == 'зарина' || sName.contains('зарина') || sName.contains('zarina') || sId == 'seller_5' || sName.contains('гульнара') || sName.contains('gulnara')) {
      result['sellerLogo'] = 'assets/images/avatar_zarina.jpg';
    } else if (sId == 'madina' || sId == 'мәдина' || sName.contains('мәдина') || sName.contains('madina') || sId == 'seller_3' || sName.contains('мадина')) {
      result['sellerLogo'] = 'assets/images/avatar_madina.jpg';
    } else if (sId == 'aigerim' || sId == 'айгерім' || sName.contains('айгерім') || sName.contains('айгерим') || sId == 'seller_1' || sName.contains('aigerim')) {
      result['sellerLogo'] = 'assets/images/avatar_aigerim.jpg';
    } else if (sId == 'kamila' || sId == 'камила' || sName.contains('камила') || sName.contains('kamila')) {
      result['sellerLogo'] = 'https://images.unsplash.com/photo-1554151228-14d9def656e4?w=150&h=150&fit=crop';
    } else if (sId == 'arman' || sId == 'арман' || sName.contains('арман') || sName.contains('arman') || sId == 'seller_2' || sName.contains('данияр') || sName.contains('daniyar')) {
      result['sellerLogo'] = 'assets/images/avatar_arman.jpg';
    } else if (sId == 'chef_erkebulan' || sId == 'шеф еркебұлан' || sName.contains('еркебұлан') || sName.contains('еркебулан') || sId == 'seller_4' || sName.contains('бакытжан') || sName.contains('bakytzhan') || sName.contains('бақытжан')) {
      result['sellerLogo'] = 'assets/images/avatar_erkebulan.jpg';
    } else if (sId == 'dias' || sId == 'диас' || sName.contains('диас') || sName.contains('dias')) {
      result['sellerLogo'] = 'https://images.unsplash.com/photo-1547425260-76bcad5ce729?w=150&h=150&fit=crop';
    } else if (sId == 'rustem' || sId == 'рүстем' || sName.contains('рүстем') || sName.contains('рустем') || sName.contains('rustem')) {
      result['sellerLogo'] = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop';
    } else if (sId == 'jandos' || sId == 'жандос' || sName.contains('жандос') || sName.contains('jandos')) {
      result['sellerLogo'] = 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&h=150&fit=crop';
    } else if (sId == 'bagdat' || sId == 'бағдат' || sName.contains('бағдат') || sName.contains('багдат') || sName.contains('bagdat')) {
      result['sellerLogo'] = 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&h=150&fit=crop';
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

  static Map<String, dynamic> _enrichUserData(String id, Map<String, dynamic> data) {
    final updated = Map<String, dynamic>.from(data);
    final sId = id.toLowerCase().trim();
    final sName = '${updated['name'] ?? ''} ${updated['surname'] ?? ''}'.toLowerCase().trim();
    final logo = (updated['sellerLogo'] ?? '').toString();

    // Map default seller logos (female vs male)
    if (logo.startsWith('firestore_image:') || logo.startsWith('data:')) {
      // Keep custom uploaded logo
    } else if (sId == 'gulzira' || sId == 'гүлзира' || sName.contains('гүлзира') || sName.contains('gulzira')) {
      updated['sellerLogo'] = 'assets/images/avatar_gulzira.jpg';
    } else if (sId == 'nazgul' || sId == 'назгүл' || sName.contains('назгүл') || sName.contains('nazgul')) {
      updated['sellerLogo'] = 'assets/images/avatar_nazgul.jpg';
    } else if (sId == 'zarina' || sId == 'зарина' || sName.contains('зарина') || sName.contains('zarina') || sId == 'seller_5' || sName.contains('гульнара') || sName.contains('gulnara')) {
      updated['sellerLogo'] = 'assets/images/avatar_zarina.jpg';
    } else if (sId == 'madina' || sId == 'мәдина' || sName.contains('мәдина') || sName.contains('madina') || sId == 'seller_3' || sName.contains('мадина')) {
      updated['sellerLogo'] = 'assets/images/avatar_madina.jpg';
    } else if (sId == 'aigerim' || sId == 'айгерім' || sName.contains('айгерім') || sName.contains('айгерим') || sId == 'seller_1' || sName.contains('aigerim')) {
      updated['sellerLogo'] = 'assets/images/avatar_aigerim.jpg';
    } else if (sId == 'kamila' || sId == 'камила' || sName.contains('камила') || sName.contains('kamila')) {
      updated['sellerLogo'] = 'https://images.unsplash.com/photo-1554151228-14d9def656e4?w=150&h=150&fit=crop';
    } else if (sId == 'arman' || sId == 'арман' || sName.contains('арман') || sName.contains('arman') || sId == 'seller_2' || sName.contains('данияр') || sName.contains('daniyar')) {
      updated['sellerLogo'] = 'assets/images/avatar_arman.jpg';
    } else if (sId == 'chef_erkebulan' || sId == 'шеф еркебұлан' || sName.contains('еркебұлан') || sName.contains('еркебулан') || sId == 'seller_4' || sName.contains('бакытжан') || sName.contains('bakytzhan') || sName.contains('бақытжан')) {
      updated['sellerLogo'] = 'assets/images/avatar_erkebulan.jpg';
    } else if (sId == 'dias' || sId == 'диас' || sName.contains('диас') || sName.contains('dias')) {
      updated['sellerLogo'] = 'https://images.unsplash.com/photo-1547425260-76bcad5ce729?w=150&h=150&fit=crop';
    } else if (sId == 'rustem' || sId == 'рүстем' || sName.contains('рүстем') || sName.contains('рустем') || sName.contains('rustem')) {
      updated['sellerLogo'] = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop';
    } else if (sId == 'jandos' || sId == 'жандос' || sName.contains('жандос') || sName.contains('jandos')) {
      updated['sellerLogo'] = 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&h=150&fit=crop';
    } else if (sId == 'bagdat' || sId == 'бағдат' || sName.contains('бағдат') || sName.contains('багдат') || sName.contains('bagdat')) {
      updated['sellerLogo'] = 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&h=150&fit=crop';
    }

    if (updated.containsKey('deliveryAddress')) {
      updated['deliveryAddress'] = normalizeAstanaAddress(updated['deliveryAddress']?.toString() ?? '');
    }
    if (updated.containsKey('address')) {
      updated['address'] = normalizeAstanaAddress(updated['address']?.toString() ?? '');
    }
    return updated;
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
      return {'ok': true, 'user': _enrichUserData(userId, defaultData)};
    }
    return {'ok': true, 'user': {'userId': doc.id, ..._enrichUserData(doc.id, doc.data()!)}};
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
          'titleRu': pDoc['titleRu'] ?? pDoc['title'] ?? '',
          'titleKz': pDoc['titleKz'] ?? pDoc['title'] ?? '',
          'titleEn': pDoc['titleEn'] ?? pDoc['title'] ?? '',
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
    return _enrichUserData(userId, doc.data()!);
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => {'userId': d.id, '_id': d.id, ..._enrichUserData(d.id, d.data())}).toList();
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
