const admin = require('firebase-admin');
const https = require('https');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const addresses = [
  "пр. Кабанбай Батыра, д. 17, кв. 42",
  "пр. Туран, д. 24, кв. 10",
  "ул. Кенесары, д. 40, кв. 8",
  "пр. Республики, д. 15, кв. 105",
  "ул. Сарайшык, д. 5, кв. 12",
  "ул. Сыганак, д. 10, кв. 3",
  "ул. Кунаева, д. 12, кв. 45",
  "пр. Мангилик Ел, д. 28, кв. 22",
  "ул. Достык, д. 18, кв. 7",
  "ул. Ташенова, д. 9, кв. 54"
];

function splitToSteps(text) {
  if (!text) return [];
  let blocks = text.split(/\r?\n/).map(s => s.trim()).filter(s => s.length > 0);
  if (blocks.length <= 1) {
    blocks = text.split(/\.\s+/).map(s => s.trim()).filter(s => s.length > 0).map(s => s.endsWith('.') ? s : s + '.');
  }
  return blocks.filter(s => s.length > 5);
}

const sellers = [
  { id: 'seller_1', name: 'Айгерим А.', logo: 'https://i.pravatar.cc/150?u=seller1', instagram: 'aigerim_cakes', phone: '+7 701 111 2233' },
  { id: 'seller_2', name: 'Данияр К.', logo: 'https://i.pravatar.cc/150?u=seller2', instagram: 'daniyar_chef', phone: '+7 702 333 4455' },
  { id: 'seller_3', name: 'Мадина М.', logo: 'https://i.pravatar.cc/150?u=seller3', instagram: 'madina_kitchen', phone: '+7 707 555 6677' },
  { id: 'seller_4', name: 'Бакытжан О.', logo: 'https://i.pravatar.cc/150?u=seller4', instagram: 'bakyt_food', phone: '+7 747 777 8899' },
  { id: 'seller_5', name: 'Гульнара С.', logo: 'https://i.pravatar.cc/150?u=seller5', instagram: 'gulya_meals', phone: '+7 701 999 0011' }
];

function fetchMealsByLetter(letter) {
  return new Promise((resolve, reject) => {
    https.get(`https://www.themealdb.com/api/json/v1/1/search.php?f=${letter}`, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve(JSON.parse(data).meals || []));
    }).on('error', reject);
  });
}

function translateText(text, targetLang) {
  if (!text) return Promise.resolve('');
  text = text.substring(0, 800); // Prevent URL too long
  return new Promise((resolve) => {
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          let translated = '';
          if (parsed && parsed[0]) {
            parsed[0].forEach(item => {
              if (item[0]) translated += item[0];
            });
          }
          resolve(translated || text);
        } catch (e) {
          resolve(text);
        }
      });
    }).on('error', () => resolve(text));
  });
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function deleteCollection(collectionPath, batchSize) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(batchSize);
  return new Promise((resolve, reject) => { deleteQueryBatch(query, resolve).catch(reject); });
}

async function deleteQueryBatch(query, resolve) {
  const snapshot = await query.get();
  if (snapshot.size === 0) { resolve(); return; }
  const batch = db.batch();
  snapshot.docs.forEach((doc) => { batch.delete(doc.ref); });
  await batch.commit();
  process.nextTick(() => { deleteQueryBatch(query, resolve); });
}

async function seed() {
  console.log('Cleaning collection...');
  await deleteCollection('products', 20);
  
  console.log('Fetching from TheMealDB API to gather 100 unique meals...');
  let allMeals = [];
  const letters = 'abcdefghijklmnopqrstuvwxyz'.split('');
  
  for (const letter of letters) {
    const meals = await fetchMealsByLetter(letter);
    allMeals = allMeals.concat(meals);
    if (allMeals.length >= 100) break;
  }
  
  const uniqueMealsMap = new Map();
  for (const meal of allMeals) {
    if (!uniqueMealsMap.has(meal.idMeal)) {
      uniqueMealsMap.set(meal.idMeal, meal);
    }
  }
  const apiMeals = Array.from(uniqueMealsMap.values()).slice(0, 100);
  
  console.log(`Fetched ${apiMeals.length} unique meals. Starting translation & upload (this will take ~1-2 minutes)...`);

  for (let i = 0; i < apiMeals.length; i++) {
    const meal = apiMeals[i];
    const seller = sellers[i % sellers.length];
    const address = addresses[i % addresses.length];

    const ingredientsEn = [];
    for (let j = 1; j <= 20; j++) {
      const ing = meal[`strIngredient${j}`];
      if (ing && ing.trim()) ingredientsEn.push(ing);
    }

    const titleEn = meal.strMeal;
    const descEn = meal.strInstructions;
    const joinedIngEn = ingredientsEn.join(' | ');

    // Translate to Russian
    const titleRu = await translateText(titleEn, 'ru');
    const descRu = await translateText(descEn, 'ru');
    const joinedIngRu = await translateText(joinedIngEn, 'ru');
    const ingredientsRu = joinedIngRu.split('|').map(s => s.trim());

    // Translate to Kazakh
    const titleKz = await translateText(titleEn, 'kk'); // 'kk' is Kazakh in Google Translate
    const descKz = await translateText(descEn, 'kk');
    const joinedIngKz = await translateText(joinedIngEn, 'kk');
    const ingredientsKz = joinedIngKz.split('|').map(s => s.trim());

    // Proxy for CORS
    const imageUrl = `https://images.weserv.nl/?url=${encodeURIComponent(meal.strMealThumb)}`;

    const finalDescEn = `A delicious traditional ${titleEn} prepared with fresh ingredients according to a classic recipe.`;
    const finalDescRu = `Вкусное традиционное блюдо "${titleRu}", приготовленное из свежих ингредиентов по классическому рецепту.`;
    const finalDescKz = `Классикалық рецепт бойынша жаңа піскен ингредиенттерден дайындалған дәмді "${titleKz}" дәстүрлі тағамы.`;

    const stepsEn = splitToSteps(descEn);
    const stepsRu = splitToSteps(descRu);
    const stepsKz = splitToSteps(descKz);

    await db.collection('products').add({
      title: titleRu, // default fallback to Ru since local focus
      titleRu: titleRu, 
      titleEn: titleEn,
      titleKz: titleKz,
      description: finalDescRu,
      descriptionRu: finalDescRu,
      descriptionEn: finalDescEn,
      descriptionKz: finalDescKz,
      price: 1500 + ((Math.random() * 50) | 0) * 100,
      category: meal.strCategory || 'Түскі ас',
      imageUrl: imageUrl,
      sellerId: seller.id,
      sellerName: seller.name,
      sellerLogo: seller.logo,
      sellerInstagram: seller.instagram,
      sellerPhone: seller.phone,
      location: "Астана",
      fullAddress: `${address}, Астана`,
      ingredients: ingredientsRu,
      ingredientsRu: ingredientsRu,
      ingredientsEn: ingredientsEn,
      ingredientsKz: ingredientsKz,
      steps: stepsRu.length > 0 ? stepsRu : [descRu],
      stepsRu: stepsRu.length > 0 ? stepsRu : [descRu],
      stepsEn: stepsEn.length > 0 ? stepsEn : [descEn],
      stepsKz: stepsKz.length > 0 ? stepsKz : [descKz],
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    process.stdout.write(`\rProcessed ${i + 1}/100 dishes...`);
    await sleep(200); // Small delay to prevent API rate limiting
  }
  console.log('\nSuccessfully seeded and translated 100 unique dishes!');
  process.exit();
}
seed().catch(err => { console.error(err); process.exit(1); });
