const https = require('https');
const fs = require('fs');
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
  if (field.integerValue !== undefined) return parseInt(field.integerValue, 10);
  if (field.booleanValue !== undefined) return field.booleanValue;
  if (field.arrayValue && field.arrayValue.values) {
    return field.arrayValue.values.map(v => v.stringValue || '');
  }
  return null;
}

async function run() {
  const docs = await fetchAllProducts();
  const products = [];
  
  for (const doc of docs) {
    const id = doc.name.split('/').pop();
    const f = doc.fields;
    
    const p = { id };
    for (const key of Object.keys(f)) {
      p[key] = getVal(f[key]);
    }
    
    products.push(p);
  }
  
  fs.writeFileSync('products_snapshot.json', JSON.stringify(products, null, 2), 'utf8');
  console.log(`Saved ${products.length} products to products_snapshot.json`);
}

run().catch(console.error);
