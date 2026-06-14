const fs = require('fs');
const data = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

console.log('--- Checking for placeholder URLs in database ---');
data.forEach(p => {
  const url = p.imageUrl || '';
  if (url.includes('soup.jpg') || url.includes('borsh.jpg') || url.includes('national.jpg') || !url) {
    console.log(`Product [${p.id}] "${p.titleRu}" / "${p.titleEn}" uses placeholder: "${url}"`);
  }
});
