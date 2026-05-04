const admin = require('firebase-admin');
const fs = require('fs');

// 1. ВСТАВЬ СВОЙ ФАЙЛ КЛЮЧА ИЗ FIREBASE: Project Settings -> Service Accounts -> Generate new private key
// Сохрани его как serviceAccountKey.json в эту же папку.
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 100 сгенерированных рецептов (мы можем использовать тот же mock_data.dart, предварительно сконвертировав его в JSON)
// Если у тебя еще работает seed_marketplace.js для Mongo, мы можем просто вытянуть данные оттуда.

async function seedFirebase() {
  console.log("Seeding Firebase Firestore with products...");
  // TODO: Здесь мы загрузим 100 рецептов, когда ты дашь добро и создашь базу
  console.log("Done!");
}

seedFirebase().catch(console.error);
