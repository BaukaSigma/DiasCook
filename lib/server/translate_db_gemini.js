const admin = require('firebase-admin');
const https = require('https');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const apiKey = 'AIzaSyDkQaYKuits8p-rC5PCmda7onytq-D_x7M';

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

function callGemini(prompt) {
  return new Promise((resolve, reject) => {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    
    const requestData = JSON.stringify({
      contents: [
        {
          parts: [
            { text: prompt }
          ]
        }
      ],
      generationConfig: {
        responseMimeType: 'application/json'
      }
    });

    const req = https.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestData)
      }
    }, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const data = JSON.parse(responseBody);
            const text = data.candidates[0].content.parts[0].text;
            resolve(JSON.parse(text.trim()));
          } catch (e) {
            reject(new Error(`Failed to parse response: ${e.message}. Body: ${responseBody}`));
          }
        } else {
          reject(new Error(`Gemini API returned status ${res.statusCode}. Body: ${responseBody}`));
        }
      });
    });

    req.on('error', reject);
    req.write(requestData);
    req.end();
  });
}

async function run() {
  console.log('Fetching all products from Firestore...');
  const snapshot = await db.collection('products').get();
  console.log(`Found ${snapshot.size} products total.`);

  const products = [];
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    products.push({ id: doc.id, data });
  });

  console.log(`Starting translation for ${products.length} products...`);

  const batchSize = 5;
  for (let i = 0; i < products.length; i += batchSize) {
    const batch = products.slice(i, i + batchSize);
    
    const batchDataForAi = batch.map(p => ({
      id: p.id,
      titleEn: p.data.titleEn || '',
      titleRu: p.data.titleRu || p.data.title || '',
      descriptionEn: p.data.descriptionEn || '',
      ingredientsEn: p.data.ingredientsEn || p.data.ingredients || [],
      stepsEn: p.data.stepsEn || p.data.steps || []
    }));

    const prompt = `
You are a professional chef and translator fluent in English, Russian, and Kazakh.
Translate the following batch of ${batch.length} recipes into high-quality culinary Russian and Kazakh.
Make sure the Kazakh translations are natural and sound like authentic Kazakh recipe terms, NOT literal machine translations (e.g. do NOT translate "hot pot" as "ыстық ыдыс", use "бұқтырылған ет" or "сорпа/ыстық тағам" or appropriate term; do NOT translate "dip" as "батырыңыз" or "батыру", use "тұздық" or "соус"; translate cooking terms naturally).
For example, "Beans and Sausage Hotpot" should translate in Kazakh to something natural like "Бұршақ қосылған шұжық бұқтырмасы" or similar, NOT "Бұршақ және шұжық ыстық ыдыс".

Recipes to translate:
${JSON.stringify(batchDataForAi)}

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
`;

    console.log(`Sending batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(products.length / batchSize)} to Gemini...`);
    
    let success = false;
    let attempts = 0;
    while (!success && attempts < 3) {
      try {
        attempts++;
        const translations = await callGemini(prompt);
        
        for (const t of translations) {
          const docRef = db.collection('products').doc(t.id);
          const orig = products.find(p => p.id === t.id);
          if (!orig) continue;

          const updates = {
            titleRu: t.titleRu || orig.data.titleRu,
            titleKz: t.titleKz || orig.data.titleKz,
            descriptionRu: t.descriptionRu || orig.data.descriptionRu,
            descriptionKz: t.descriptionKz || orig.data.descriptionKz,
            ingredientsRu: t.ingredientsRu || orig.data.ingredientsRu,
            ingredientsKz: t.ingredientsKz || orig.data.ingredientsKz,
            stepsRu: t.stepsRu || orig.data.stepsRu,
            stepsKz: t.stepsKz || orig.data.stepsKz,
            isTranslatedByAI: true
          };

          if (!orig.data.title || orig.data.title === orig.data.titleEn) {
            updates.title = t.titleRu;
          }
          if (!orig.data.description || orig.data.description === orig.data.descriptionEn) {
            updates.description = t.descriptionRu;
          }
          if (!orig.data.ingredients || orig.data.ingredients.length === 0) {
            updates.ingredients = t.ingredientsRu;
          }
          if (!orig.data.steps || orig.data.steps.length === 0) {
            updates.steps = t.stepsRu;
          }

          await docRef.update(updates);
          console.log(`  Updated product ${t.id} -> ${updates.titleKz}`);
        }
        
        success = true;
      } catch (e) {
        console.error(`  Attempt ${attempts} failed: ${e.message}`);
        if (attempts < 3) {
          console.log('  Waiting 15 seconds before retry...');
          await sleep(15000);
        } else {
          console.error('  Batch failed completely. Skipping...');
        }
      }
    }

    if (i + batchSize < products.length) {
      console.log('Waiting 8 seconds before next batch to respect rate limits...');
      await sleep(8000);
    }
  }

  console.log('All products successfully translated with Gemini!');
  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
