const https = require('https');

const projectId = 'diplom-b929a';
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
            let text = data.candidates[0].content.parts[0].text;
            
            // Clean markdown code blocks if present
            text = text.trim();
            if (text.startsWith('```')) {
              text = text.replace(/^```json\s*/i, '').replace(/```$/, '').trim();
            }
            
            resolve(JSON.parse(text));
          } catch (e) {
            reject(new Error(`Failed to parse Gemini response: ${e.message}. Body: ${responseBody}`));
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

// Helper to extract clean values from Firestore API format
function getVal(field) {
  if (!field) return null;
  if (field.stringValue !== undefined) return field.stringValue;
  if (field.arrayValue && field.arrayValue.values) {
    return field.arrayValue.values.map(v => v.stringValue || '');
  }
  return null;
}

async function run() {
  console.log('Fetching all products from Firestore...');
  const docs = await fetchAllProducts();
  console.log(`Found ${docs.length} products in database.`);

  const products = docs.map(doc => {
    const id = doc.name.split('/').pop();
    const f = doc.fields;
    return {
      id,
      titleEn: getVal(f.titleEn) || '',
      titleRu: getVal(f.titleRu) || getVal(f.title) || '',
      titleKz: getVal(f.titleKz) || '',
      descriptionEn: getVal(f.descriptionEn) || '',
      descriptionRu: getVal(f.descriptionRu) || getVal(f.description) || '',
      descriptionKz: getVal(f.descriptionKz) || '',
      ingredientsEn: getVal(f.ingredientsEn) || getVal(f.ingredients) || [],
      stepsEn: getVal(f.stepsEn) || getVal(f.steps) || []
    };
  });

  const batchSize = 5;
  for (let i = 0; i < products.length; i += batchSize) {
    const batch = products.slice(i, i + batchSize);
    console.log(`\nProcessing batch ${Math.floor(i / batchSize) + 1} of ${Math.ceil(products.length / batchSize)} (recipes ${i + 1} to ${Math.min(i + batchSize, products.length)})...`);
    
    const prompt = `
You are a professional chef, linguist, and translator fluent in English, Russian, and Kazakh.
Your task is to review and correct the translations of the following ${batch.length} recipes to ensure they sound natural, appetizing, and use professional culinary terminology in both Russian and Kazakh.

CRITICAL Kazakh Rules:
1. AVOID all literal machine translations.
2. "Hotpot" or "hot pot" must NOT be translated as "ыстық ыдыс" (which means hot container). Depending on the context, use "бұқтырма", "бұқтырылған ет" (stew), "ыстық сорпа/тағам" (hot soup/dish), or specific dish name.
3. "Dip" or "dipping sauce" must NOT be translated as "батырыңыз" or "батыру". Use "тұздық" or "соус".
4. "Dressing" must NOT be translated as "киіну" (clothing). Use "тұздық" or "соус".
5. "Casserole" must NOT be translated as "кастрөл". Use "бұқтырма" or "пеште пісірілген тағам".
6. "Crumble" must NOT be translated as "үгінді". Use "крамбл бәліші" or "десерті".
7. "Custard" must NOT be translated as "пісірілген крем". Use "заварной крем" or "сүтті-жұмыртқалы крем".
8. "Pie" must be translated as "бәліш", not "пирог" or "бәліш" incorrectly.
9. "Stew" must be translated as "бұқтырма" or "бұқтырылған тағам", not "бұқтыру".
10. Ensure the ingredients list and preparation steps are translated naturally, with correct cooking terms (e.g. "жақсылап араластырыңыз", "баяу отта пісіріңіз").

Recipes to review and correct:
${JSON.stringify(batch)}

Return the corrected recipes in a JSON array matching this schema exactly (do not output any markdown formatting or markdown wrappers like \`\`\`json):
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

    let success = false;
    let attempts = 0;
    while (!success && attempts < 3) {
      try {
        attempts++;
        const results = await callGemini(prompt);
        
        for (const t of results) {
          const orig = batch.find(p => p.id === t.id);
          if (!orig) continue;
          
          const updates = {
            titleRu: t.titleRu || orig.titleRu,
            titleKz: t.titleKz || orig.titleKz,
            descriptionRu: t.descriptionRu || orig.descriptionRu,
            descriptionKz: t.descriptionKz || orig.descriptionKz,
            ingredientsRu: t.ingredientsRu || orig.ingredientsRu,
            ingredientsKz: t.ingredientsKz || orig.ingredientsKz,
            stepsRu: t.stepsRu || orig.stepsRu,
            stepsKz: t.stepsKz || orig.stepsKz,
            title: t.titleRu || orig.titleRu,
            description: t.descriptionRu || orig.descriptionRu,
            ingredients: t.ingredientsRu || orig.ingredientsRu,
            steps: t.stepsRu || orig.stepsRu,
            isTranslatedByAI: true
          };
          
          await updateProduct(t.id, updates);
          console.log(`  -> Updated [${t.id}] to: "${updates.titleKz}" / "${updates.titleRu}"`);
        }
        success = true;
      } catch (err) {
        console.error(`  [Attempt ${attempts}] Failed:`, err.message);
        if (attempts < 3) {
          console.log('  Waiting 15 seconds before retrying...');
          await sleep(15000);
        } else {
          console.error('  Skipping this batch due to repeated failures.');
        }
      }
    }
    
    if (i + batchSize < products.length) {
      console.log('Waiting 8 seconds before the next batch to respect Gemini API rate limits...');
      await sleep(8000);
    }
  }

  console.log('\nAll products successfully processed, corrected, and updated in Firestore!');
}

run().catch(console.error);
