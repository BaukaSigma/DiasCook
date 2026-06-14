const fs = require('fs');
const data = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

const rawCats = {};
data.forEach(p => {
  const c = p.category || 'NO CATEGORY';
  rawCats[c] = (rawCats[c] || 0) + 1;
});

console.log('--- Raw Categories in Database ---');
console.log(JSON.stringify(rawCats, null, 2));
