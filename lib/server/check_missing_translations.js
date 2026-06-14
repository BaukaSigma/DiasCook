const fs = require('fs');
const path = require('path');

// Read products snapshot
const products = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

// Extract translationMap from run_final_migration.js
const migrationContent = fs.readFileSync('run_final_migration.js', 'utf8');
const mapStartIndex = migrationContent.indexOf('const translationMap = {');
const mapEndIndex = migrationContent.indexOf('};', mapStartIndex);
const mapText = migrationContent.substring(mapStartIndex, mapEndIndex + 2);

// Evaluate the map safely
let translationMap = {};
eval(mapText.replace('const translationMap =', 'translationMap ='));

console.log(`Loaded ${Object.keys(translationMap).length} keys from translationMap.`);

let missingCount = 0;
products.forEach(p => {
  if (!p.titleEn) return; // Skip user custom products
  
  const title = p.titleEn.trim();
  if (!translationMap[title] && !translationMap[title + ' ']) {
    console.log(`Missing translation for seeded product: "${title}" (ID: ${p.id})`);
    missingCount++;
  }
});

console.log(`Total missing translations: ${missingCount}`);
