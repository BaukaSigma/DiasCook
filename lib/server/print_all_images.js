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
  const list = docs.map(doc => {
    const id = doc.name.split('/').pop();
    const f = doc.fields;
    return {
      id,
      titleEn: getVal(f.titleEn) || '',
      titleRu: getVal(f.titleRu) || getVal(f.title) || '',
      titleKz: getVal(f.titleKz) || '',
      imageUrl: getVal(f.imageUrl) || ''
    };
  });
  console.log(JSON.stringify(list, null, 2));
}

run().catch(console.error);
