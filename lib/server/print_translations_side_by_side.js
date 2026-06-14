const fs = require('fs');

const migrationContent = fs.readFileSync('run_final_migration.js', 'utf8');
const mapStartIndex = migrationContent.indexOf('const translationMap = {');
const mapEndIndex = migrationContent.indexOf('};', mapStartIndex);
const mapText = migrationContent.substring(mapStartIndex, mapEndIndex + 2);

let translationMap = {};
eval(mapText.replace('const translationMap =', 'translationMap ='));

console.log('--- Translation Map Verification ---');
const entries = Object.entries(translationMap);
entries.forEach(([en, trans], idx) => {
  console.log(`${idx + 1}. EN: "${en}"`);
  console.log(`   RU: "${trans.ru}"`);
  console.log(`   KZ: "${trans.kz}"`);
  console.log('------------------------------');
});
