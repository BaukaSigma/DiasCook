const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', 'mock_data.dart');
const content = fs.readFileSync(filePath, 'utf8');

// A simple regex to find mock recipe blocks
const recipeRegex = /\{\s*'_id':\s*'([^']*)'([\s\S]*?)\}/g;
let match;
const recipes = [];

while ((match = recipeRegex.exec(content)) !== null) {
  const id = match[1];
  const block = match[2];
  
  const titleMatch = block.match(/'title':\s*'([^']*)'/);
  const titleRuMatch = block.match(/'titleRu':\s*'([^']*)'/);
  const titleKzMatch = block.match(/'titleKz':\s*'([^']*)'/);
  const titleEnMatch = block.match(/'titleEn':\s*'([^']*)'/);
  const imageUrlMatch = block.match(/'imageUrl':\s*'([^']*)'/);
  const categoryMatch = block.match(/'category':\s*'([^']*)'/);
  
  recipes.push({
    id,
    title: titleMatch ? titleMatch[1] : '',
    titleRu: titleRuMatch ? titleRuMatch[1] : '',
    titleKz: titleKzMatch ? titleKzMatch[1] : '',
    titleEn: titleEnMatch ? titleEnMatch[1] : '',
    imageUrl: imageUrlMatch ? imageUrlMatch[1] : '',
    category: categoryMatch ? categoryMatch[1] : ''
  });
}

console.log(`Found ${recipes.length} mock recipes.`);

// Check for duplicate images
const imgCounts = {};
recipes.forEach(r => {
  if (r.imageUrl) {
    if (!imgCounts[r.imageUrl]) imgCounts[r.imageUrl] = [];
    imgCounts[r.imageUrl].push(r.id + ' (' + r.titleEn + ')');
  }
});

console.log('--- Duplicate images in mock data ---');
let dupCount = 0;
for (const [url, ids] of Object.entries(imgCounts)) {
  if (ids.length > 1) {
    console.log(`Image: ${url}`);
    console.log(`  Used by: ${ids.join(', ')}`);
    dupCount++;
  }
}
console.log(`Total duplicate images in mock data: ${dupCount}`);

console.log('\n--- All Mock Recipes (IDs & Titles) ---');
recipes.forEach(r => {
  console.log(`- ${r.id}: EN: "${r.titleEn}", RU: "${r.titleRu}", KZ: "${r.titleKz}", Image: "${r.imageUrl}"`);
});
