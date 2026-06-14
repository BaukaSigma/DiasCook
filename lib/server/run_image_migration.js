const https = require('https');
const fs = require('fs');
const projectId = 'diplom-b929a';

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Complete translation dictionary from run_final_migration.js
const migrationContent = fs.readFileSync('run_final_migration.js', 'utf8');
const mapStartIndex = migrationContent.indexOf('const translationMap = {');
const mapEndIndex = migrationContent.indexOf('};', mapStartIndex);
const mapText = migrationContent.substring(mapStartIndex, mapEndIndex + 2);
let translationMap = {};
eval(mapText.replace('const translationMap =', 'translationMap ='));

function replaceKzWords(text) {
  if (!text) return '';
  let res = text;
  
  // Replace cheese terms
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сырлары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшіктері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сырлар([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшіктер$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сыры([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшігі$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сыр([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшік$2');
  
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сырлары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшіктері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сырлар([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшіктер$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сыры([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшігі$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сыр([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшік$2');

  // Replace pie terms
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])пирогтары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1бәліштері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])пирогы([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1бәліші$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])пирог([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1бәліш$2');
  
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Пирогтары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Бәліштері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Пирогы([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Бәліші$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Пирог([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Бәліш$2');

  // Replace machine-translation terms
  res = res.replace(/ыстық ыдыс/gi, 'бұқтырма');
  res = res.replace(/ыстық ыдысты/gi, 'бұқтырманы');
  res = res.replace(/ыстық ыдысқа/gi, 'бұқтырмаға');
  res = res.replace(/ыстық ыдыстың/gi, 'бұқтырманың');
  
  res = res.replace(/батырыңыз/gi, 'тұздық соусы');
  res = res.replace(/батыру соусы/gi, 'тұздық соусы');
  res = res.replace(/батыруға арналған/gi, 'тұздыққа арналған');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])батыру([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1тұздық$2');
  
  res = res.replace(/киіну/gi, 'тұздық');
  res = res.replace(/киімі/gi, 'тұздығы');
  res = res.replace(/салат киімі/gi, 'салат соусы');
  
  res = res.replace(/грави/gi, 'тұздық');
  res = res.replace(/грейви/gi, 'тұздық');
  res = res.replace(/кастрөл/gi, 'бұқтырма');
  res = res.replace(/үгінді/gi, 'десерт');

  return res;
}

// 131 completely unique database-only Unsplash food/drink/dessert image IDs (zero overlap with mock recipes)
const unsplashIds = [
  "1546069901-ba9599a7e63c","1565299624946-b28f40a0ae38","1484723091739-30a097e8f929","1482049016688-2d3e1b311543","1473093295043-cdd812d0e601","1565958011703-44f9829ba187","1512621776951-a57141f2eefd","1504674900247-0877df9cc836","1498837167922-ddd27525d352","1490645935967-10de6ba17061","1555939594-58d7cb561ad1","1496412705862-c00dbd556d45","1504754524776-8f4f37790ca0","1476224203421-9ac39bcb3327","1455619452474-d2be8b1e70cd","1467003909585-2f8a72700288","1478145046317-39f10e56b5e9","1481931098730-318b6f776db0","1485962398705-ef6a13c41e8f","1493770348161-366563df1f1a","1506084868230-bb9d95c24759","1511690656952-34342bb7c2f2","1513104890138-7c749659a591","1515003848601-5264b39a4b5f","1528279027-68f0d7fce9f1","1534080391025-0967e9ae1369","1543353071-10c8ba85a904","1551183053-bf91a1d81141","1551818255-e6e10975bc17","1560684352-8497838a2229","1560806887-1e4cd0b6cbd6","1562967914-608f82629710","1563379091339-03b21ab4a4f8","1564834744159-ff0ea418473a","1565299585323-38d6b0865b47","1568901346375-23c9450c58cd","1569058242253-92a9c755a0ec","1574484284002-953d99140831","1579751626657-72bc17010498","1586190848861-99aa4a171e90","1589302168068-9646c2e9d511","1590947132387-155cc02f3212","1592417817098-8f3d6eb19675","1594212699903-ec8a3eca50f5","1598515214211-89d3c73ae83b","1603052875302-d376b7c0638a","1604382354936-07c5d9983bd3","1604908176997-125f25cc6f3d","1606787366850-de6330128bfc","1607532941433-304659e8198a","1615228939096-9ead6c74008e","1615485290382-441e4d049cb5","1615937657715-3736788865de","1617343252151-7ef7f1636d13","1618228373030-90bd67999652","1618449808021-1758e704835a","1621510456681-23a23cfb5f57","1622979135225-d2ba269cf1ac","1624462966581-bc6d768cbce5","1625860228530-77a8b7c768ec","1626804475315-86532454b5df","1627308595229-7830a5c91f9f","1628294895520-a1908b1a4570","1631451095765-2c91616fc9e6","1632778149955-e80f8ceca2e8","1639744169720-6d421de72f91","1645112411341-6c4fd023714a","1701579231349-d7459c41031a","1707343843437-caacff5cfa74","1505253716362-afaea1d3d1af","1505576399279-565b52d4ac71","1508736893-c462710aa2cb","1514326640560-7d063ef2aed5","1514516345957-556ca7d90a29","1518492104633-130d0cc84637","1529042410759-befb1204b468","1534422298391-e4f8c172dddb","1534790566855-4cb788d389ec","1535141192574-5d4897c13636","1536304997881-a372c179924b","1538443313030-f42657ab9d80","1539136788836-3ecf56167776","1541014741259-df5395b7c765","1541532713592-79a0317b6b77","1541832676-9b763b0239ab","1542826438-bd32f43d626f","1543339308-43e59d6b73a6","1543362906-acfc16c67564","1543363136-a5ea4db7ba93","1547496502-affa22d38842","1548840410-f67431a34e7a","1548943487-a2e4e43b4853","1550547660-d9450f859349","1551024506-0bccd828d307","1551024601-bec78aea704b","1551248429-4093e7284b61","1558985250-27a406d64cb3","1559925393-8be0ec4767c8","1560781290-7dc94c0f8f4f","1560963689-a29aa700cf9d","1561758033-d89a9ad46330","1562007908-17c6768b2c88","1562059390-a761a0847685","1562059392-a761a0847686","1562547909-ca62df30e84c","1563729784474-d7bdb3d09995","1564013799919-ab600027ffc6","1569718212165-3a8278d5f624","1571091718767-18b5b1457add","1572490122747-3968b75cc699","1574169208507-84376144848b","1576618148400-f54bed99fcfd","1505253716362","1505576399279","1514326640560","1514516345957","1529042410759","1534422298391","1534790566855","1535141192574","1536304997881","1538443313030","1539136788836","1541014741259","1541532713592","1569718212165","1571091718767","1572490122747","1574169208507","1576618148400","1578985545062"
];

function fetchAllProducts() {
  return new Promise((resolve, reject) => {
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products?pageSize=150`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const json = JSON.parse(data);
            resolve(json.documents || []);
          } catch (e) {
            reject(e);
          }
        } else {
          reject(new Error(`Firestore returned status ${res.statusCode}. Body: ${data}`));
        }
      });
    }).on('error', reject);
  });
}

function updateProduct(productId, updates) {
  return new Promise((resolve, reject) => {
    const fields = {};
    const fieldPaths = [];
    
    for (const [key, val] of Object.entries(updates)) {
      fieldPaths.push(`updateMask.fieldPaths=${key}`);
      if (typeof val === 'string') {
        fields[key] = { stringValue: val };
      } else if (typeof val === 'boolean') {
        fields[key] = { booleanValue: val };
      } else if (typeof val === 'number') {
        fields[key] = { integerValue: val.toString() };
      } else if (Array.isArray(val)) {
        fields[key] = {
          arrayValue: {
            values: val.map(item => ({ stringValue: item.toString() }))
          }
        };
      }
    }
    
    const queryParams = fieldPaths.join('&');
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products/${productId}?${queryParams}`;
    
    const requestData = JSON.stringify({ fields });
    
    const req = https.request(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestData)
      }
    }, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(responseBody));
        } else {
          reject(new Error(`Failed to update ${productId}. Status: ${res.statusCode}. Body: ${responseBody}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(requestData);
    req.end();
  });
}

// Helper to extract values
function getVal(field) {
  if (!field) return null;
  if (field.stringValue !== undefined) return field.stringValue;
  if (field.integerValue !== undefined) return parseInt(field.integerValue, 10);
  if (field.booleanValue !== undefined) return field.booleanValue;
  if (field.arrayValue && field.arrayValue.values) {
    return field.arrayValue.values.map(v => v.stringValue || '');
  }
  return null;
}

// Normalization function matching English category to standard Kazakh category
function getKzCategory(englishCategory) {
  const ec = (englishCategory || '').toLowerCase().trim();
  
  if (ec.includes('breakfast') || ec.includes('завтрак') || ec.includes('таңертеңгілік') || ec.includes('таңғы астар')) {
    return 'Таңғы астар';
  }
  if (ec.includes('beef') || ec.includes('pork') || ec.includes('lamb') || ec.includes('goat') || ec.includes('dinner') || ec.includes('ужин') || ec.includes('кешкi ас') || ec.includes('кешкі ас')) {
    return 'Кешкі ас';
  }
  if (ec.includes('dessert') || ec.includes('desserts') || ec.includes('десерты') || ec.includes('тәттілер')) {
    return 'Тәттілер';
  }
  if (ec.includes('side') || ec.includes('side dish') || ec.includes('side_dish') || ec.includes('гарнир')) {
    return 'Гарнир';
  }
  if (ec.includes('beverage') || ec.includes('beverages') || ec.includes('напитки') || ec.includes('сусындар')) {
    return 'Сусындар';
  }
  // All other categories (lunch, seafood, chicken, starter, miscellaneous, etc.) map to 'Түскі ас'
  return 'Түскі ас';
}

async function run() {
  console.log('Fetching all products from Firestore...');
  const docs = await fetchAllProducts();
  console.log(`Found ${docs.length} products total.`);

  let seededCount = 0;
  let customCount = 0;
  
  for (const doc of docs) {
    const id = doc.name.split('/').pop();
    const f = doc.fields;
    
    const titleEnRaw = getVal(f.titleEn) || '';
    const titleEn = titleEnRaw.trim();
    
    // Check if it's a custom/user-added product (they don't have titleEn)
    if (!titleEn) {
      console.log(`Skipping image assignment for custom user product: "${getVal(f.title) || 'No Name'}" (ID: ${id})`);
      customCount++;
      continue;
    }
    
    const trans = translationMap[titleEn];
    if (!trans) {
      console.log(`WARNING: No translation mapped for seeded product: "${titleEn}" (ID: ${id})`);
      continue;
    }
    
    const titleRu = trans.ru;
    const titleKz = trans.kz;
    
    const descriptionRu = `Вкусное традиционное блюдо "${titleRu}", приготовленное из свежих ингредиентов по классическому рецепту.`;
    const descriptionKz = `Классикалық рецепт бойынша жаңа піскен ингредиенттерден дайындалған дәмді "${titleKz}" дәстүрлі тағамы.`;
    const descriptionEn = `A delicious traditional ${titleEn} prepared with fresh ingredients according to a classic recipe.`;
    
    // Get ingredients and steps lists
    const ingredientsKz = getVal(f.ingredientsKz) || [];
    const stepsKz = getVal(f.stepsKz) || [];
    const ingredientsRu = getVal(f.ingredientsRu) || getVal(f.ingredients) || [];
    const stepsRu = getVal(f.stepsRu) || getVal(f.steps) || [];
    
    // Clean ingredients and steps lists in Kazakh
    const cleanedIngredientsKz = ingredientsKz.map(item => replaceKzWords(item));
    const cleanedStepsKz = stepsKz.map(item => replaceKzWords(item));
    const cleanedIngredientsRu = ingredientsRu.map(item => replaceKzWords(item));
    const cleanedStepsRu = stepsRu.map(item => replaceKzWords(item));
    
    // Get correct Kazakh category
    const rawCategory = getVal(f.category) || 'Lunch';
    const kzCategory = getKzCategory(rawCategory);
    
    // Get unique Unsplash image URL (no photo- prefix duplicates)
    const unsplashId = unsplashIds[seededCount % unsplashIds.length];
    const uniqueImageUrl = `https://images.unsplash.com/photo-${unsplashId}?w=500&auto=format&fit=crop`;
    
    const updates = {
      title: titleRu,
      titleRu: titleRu,
      titleKz: titleKz,
      titleEn: titleEn,
      description: descriptionRu,
      descriptionRu: descriptionRu,
      descriptionKz: descriptionKz,
      descriptionEn: descriptionEn,
      ingredientsKz: cleanedIngredientsKz,
      stepsKz: cleanedStepsKz,
      ingredientsRu: cleanedIngredientsRu,
      stepsRu: cleanedStepsRu,
      category: kzCategory,
      imageUrl: uniqueImageUrl,
      isTranslatedByAI: true
    };
    
    try {
      await updateProduct(id, updates);
      console.log(`Updated seeded [${id}] -> "${titleKz}" / "${titleRu}" | Cat: "${kzCategory}" | Image: "${uniqueImageUrl}"`);
      seededCount++;
      await sleep(100); // Small delay
    } catch (err) {
      console.error(`Error updating seeded [${id}]:`, err.message);
    }
  }
  
  console.log(`\nSuccessfully migrated ${seededCount} seeded products and skipped ${customCount} custom user products!`);
}

run().catch(console.error);
