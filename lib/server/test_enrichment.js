const fs = require('fs');

const products = JSON.parse(fs.readFileSync('products_snapshot.json', 'utf8'));

// The exact normalization map from lib/api.dart
const catNorm = {
  'таңертеңгілік': 'Таңғы астар',
  'таны ертенгилик': 'Таңғы астар',
  'тан ертенгiлiк': 'Таңғы астар',
  'тан ертенгилик': 'Таңғы астар',
  'таңғы астар': 'Таңғы астар',
  'breakfast': 'Таңғы астар',
  'завтрак': 'Таңғы астар',
  
  'тускi ас': 'Түскі ас',
  'тусkі ас': 'Түскі ас',
  'обед': 'Түскі ас',
  'lunch': 'Түскі ас',
  'chicken': 'Түскі ас',
  'pasta': 'Түскі ас',
  'seafood': 'Түскі ас',
  'vegetarian': 'Түскі ас',
  'vegan': 'Түскі ас',
  'starter': 'Түскі ас',
  'miscellaneous': 'Түскі ас',
  'тагамдар': 'Түскі ас',
  'закуски': 'Түскі ас',
  'snacks': 'Түскі ас',
  'алгашкы тагам': 'Түскі ас',
  'первые блюда': 'Түскі ас',
  'appetizer': 'Түскі ас',
  'appetizers': 'Түскі ас',
  'баска': 'Түскі ас',
  'другое': 'Түскі ас',
  'other': 'Түскі ас',
  
  'кешкi ас': 'Кешкі ас',
  'ужин': 'Кешкі ас',
  'dinner': 'Кешкі ас',
  'beef': 'Кешкі ас',
  'pork': 'Кешкі ас',
  'lamb': 'Кешкі ас',
  'goat': 'Кешкі ас',
  
  'татiлер': 'Тәттілер',
  'тәттілер': 'Тәттілер',
  'десерты': 'Тәттілер',
  'desserts': 'Тәттілер',
  'dessert': 'Тәттілер',
  
  'гарнир': 'Гарнир',
  'side dish': 'Гарнир',
  'side_dish': 'Гарнир',
  'side': 'Гарнир',
  
  'сусындар': 'Сусындар',
  'напитки': 'Сусындар',
  'beverage': 'Сусындар',
  'beverages': 'Сусындар'
};

const categoryCounts = {};

products.forEach(p => {
  const rawCat = p.category || '';
  const normalized = catNorm[rawCat.toLowerCase()] || 'UNMATCHED: ' + rawCat;
  
  categoryCounts[normalized] = (categoryCounts[normalized] || 0) + 1;
});

console.log('--- Simulated Category Counts after Enrichment ---');
console.log(JSON.stringify(categoryCounts, null, 2));
