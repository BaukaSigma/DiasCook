const https = require('https');
const projectId = 'diplom-b929a';

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

function getVal(field) {
  if (!field) return null;
  if (field.stringValue !== undefined) return field.stringValue;
  return null;
}

async function run() {
  const docs = await fetchAllProducts();
  const imageCounts = {};
  
  for (const doc of docs) {
    const id = doc.name.split('/').pop();
    const f = doc.fields;
    const imageUrl = getVal(f.imageUrl) || '';
    const titleEn = getVal(f.titleEn) || getVal(f.title) || '';
    
    if (imageUrl) {
      if (!imageCounts[imageUrl]) {
        imageCounts[imageUrl] = [];
      }
      imageCounts[imageUrl].push({ id, titleEn });
    }
  }
  
  console.log('--- DUPLICATE IMAGES ---');
  let duplicateCount = 0;
  for (const [url, products] of Object.entries(imageCounts)) {
    if (products.length > 1) {
      console.log(`Image URL: ${url}`);
      console.log(`Used by ${products.length} products:`);
      products.forEach(p => console.log(`  - ID: ${p.id}, Title: "${p.titleEn}"`));
      duplicateCount++;
    }
  }
  console.log(`Total duplicate image URLs found: ${duplicateCount}`);
}

run().catch(console.error);
