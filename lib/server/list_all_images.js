const fs = require('fs');
const data = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

const imageCounts = {};
data.forEach(p => {
  const url = p.imageUrl || 'NO IMAGE';
  imageCounts[url] = (imageCounts[url] || 0) + 1;
});

// Sort by count descending
const sorted = Object.entries(imageCounts).sort((a, b) => b[1] - a[1]);

console.log('--- Image URLs and their Counts ---');
sorted.slice(0, 15).forEach(([url, count]) => {
  console.log(`${count} x "${url}"`);
});
