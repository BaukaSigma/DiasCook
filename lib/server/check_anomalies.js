const fs = require('fs');
const data = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

console.log('--- Checking for anomalies ---');

const anomalies = [];

data.forEach(p => {
  if (!p.titleEn) return; // Skip custom user products
  
  const issues = [];
  
  // 1. Check for slashes in titles
  if (p.titleRu.includes('/') || p.titleKz.includes('/')) {
    issues.push('Contains slash /');
  }
  
  // 2. Check for English letters in Russian/Kazakh titles
  const enRegex = /[a-zA-Z]/;
  if (enRegex.test(p.titleRu)) {
    issues.push(`RU title contains English letters: "${p.titleRu}"`);
  }
  if (enRegex.test(p.titleKz)) {
    issues.push(`KZ title contains English letters: "${p.titleKz}"`);
  }
  
  // 3. Check for specific bad translation words
  if (p.titleKz.toLowerCase().includes('сыр') && !p.titleKz.toLowerCase().includes('сырник')) {
    // Note: сыр is cheese in Russian but in Kazakh it should be ірімшік
    issues.push(`KZ title contains "сыр" (should be "ірімшік"): "${p.titleKz}"`);
  }
  if (p.titleKz.toLowerCase().includes('пирог')) {
    issues.push(`KZ title contains "пирог" (should be "бәліш"): "${p.titleKz}"`);
  }
  if (p.titleKz.toLowerCase().includes('ыстық ыдыс')) {
    issues.push(`KZ title contains "ыстық ыдыс" (should be "бұқтырма"): "${p.titleKz}"`);
  }
  
  // 4. Check for parentheses or braces
  if (p.titleRu.includes('(') || p.titleRu.includes('[') || p.titleKz.includes('(') || p.titleKz.includes('[')) {
    issues.push('Contains parentheses/brackets');
  }
  
  if (issues.length > 0) {
    anomalies.push({
      titleEn: p.titleEn,
      titleRu: p.titleRu,
      titleKz: p.titleKz,
      issues
    });
  }
});

console.log(`Found ${anomalies.length} products with potential translation anomalies:`);
console.log(JSON.stringify(anomalies, null, 2));
