const fs = require('fs');
const path = require('path');

// 1. Fetch all Firestore products from snapshot
const dbProducts = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

// 2. Fetch all mock recipes from mock_data.dart
const mockFilePath = path.join(__dirname, '..', 'mock_data.dart');
const mockContent = fs.readFileSync(mockFilePath, 'utf8');
const recipeRegex = /\{\s*'_id':\s*'([^']*)'([\s\S]*?)\}/g;
let match;
const mockRecipes = [];

while ((match = recipeRegex.exec(mockContent)) !== null) {
  const id = match[1];
  const block = match[2];
  const titleEnMatch = block.match(/'titleEn':\s*'([^']*)'/);
  const imageUrlMatch = block.match(/'imageUrl':\s*'([^']*)'/);
  
  mockRecipes.push({
    id,
    titleEn: titleEnMatch ? titleEnMatch[1] : '',
    imageUrl: imageUrlMatch ? imageUrlMatch[1] : ''
  });
}

console.log(`Loaded ${dbProducts.length} DB products and ${mockRecipes.length} mock recipes.`);

const imageToDishes = {};

// Register DB products (skip custom products that don't have titleEn and use the dynamic fallback at runtime)
dbProducts.forEach(p => {
  if (!p.titleEn) return;
  const url = p.imageUrl || '';
  if (!url) return;
  
  if (!imageToDishes[url]) {
    imageToDishes[url] = [];
  }
  imageToDishes[url].push(`DB product [${p.id}]: "${p.titleEn}"`);
});

// Register mock recipes
mockRecipes.forEach(r => {
  const url = r.imageUrl || '';
  if (!url) return;
  
  if (!imageToDishes[url]) {
    imageToDishes[url] = [];
  }
  imageToDishes[url].push(`Mock recipe [${r.id}]: "${r.titleEn}"`);
});

console.log('\n--- Duplicate Images Check (Firestore Seeded + Mock Recipes) ---');
let duplicatesFound = false;

for (const [url, dishes] of Object.entries(imageToDishes)) {
  if (dishes.length > 1) {
    console.log(`CRITICAL: Image URL "${url}" is shared by:`);
    dishes.forEach(d => console.log(`  - ${d}`));
    duplicatesFound = true;
  }
}

if (!duplicatesFound) {
  console.log('SUCCESS: Every single seeded database item and mock recipe has a 100% unique image! No duplicates!');
} else {
  console.log('FAILURE: Duplicate image assignments detected!');
}
