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
  const counts = {
    empty: 0,
    national: 0,
    soup: 0,
    borsh: 0,
    weserv: 0,
    others: 0
  };
  
  const categories = {};
  
  for (const doc of docs) {
    const f = doc.fields;
    const imageUrl = getVal(f.imageUrl) || '';
    const category = getVal(f.category) || 'Unknown';
    
    if (!categories[category]) {
      categories[category] = 0;
    }
    categories[category]++;
    
    if (!imageUrl) {
      counts.empty++;
    } else if (imageUrl.includes('national.jpg')) {
      counts.national++;
    } else if (imageUrl.includes('soup.jpg')) {
      counts.soup++;
    } else if (imageUrl.includes('borsh.jpg')) {
      counts.borsh++;
    } else if (imageUrl.includes('weserv.nl')) {
      counts.weserv++;
    } else {
      counts.others++;
      console.log(`Other image: "${imageUrl}" for "${getVal(f.titleEn) || getVal(f.title)}"`);
    }
  }
  
  console.log('--- Database Image Stats ---');
  console.log(JSON.stringify(counts, null, 2));
  console.log('\n--- Categories Stats ---');
  console.log(JSON.stringify(categories, null, 2));
}

run().catch(console.error);
