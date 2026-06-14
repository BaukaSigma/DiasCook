const fs = require('fs');

const data = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

console.log(`Total products: ${data.length}`);

const missingKz = data.filter(p => !p.titleKz);
console.log(`Products missing titleKz: ${missingKz.length}`);

const missingRu = data.filter(p => !p.titleRu);
console.log(`Products missing titleRu: ${missingRu.length}`);

console.log('\n--- Sample of 15 products ---');
data.slice(0, 15).forEach((p, idx) => {
  console.log(`${idx + 1}. EN: "${p.titleEn}" | RU: "${p.titleRu}" | KZ: "${p.titleKz}"`);
});

// Check for duplicate image URLs
const imageMap = {};
data.forEach(p => {
  if (p.imageUrl) {
    if (!imageMap[p.imageUrl]) {
      imageMap[p.imageUrl] = [];
    }
    imageMap[p.imageUrl].push(p.titleEn || p.titleRu);
  }
});

console.log('\n--- Duplicate Images Check ---');
let duplicatesCount = 0;
for (const [url, titles] of Object.entries(imageMap)) {
  if (titles.length > 1) {
    console.log(`Image "${url}" is shared by: ${JSON.stringify(titles)}`);
    duplicatesCount += titles.length - 1;
  }
}
console.log(`Total duplicate image assignments: ${duplicatesCount}`);
