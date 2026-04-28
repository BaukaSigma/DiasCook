// seed_marketplace.js — Тек тамақ/рецепт тауарлары (DummyJSON & TheMealDB)
const mongoose = require('mongoose');
const Product = require('./Product');

const MONGO =
    process.env.MONGO_URI ||
    'mongodb+srv://flutter1:d123456789i@cluster0.vyymexk.mongodb.net/menu_project?retryWrites=true&w=majority';

// Қазақстандық қалалар
const LOCATIONS = ['Алматы', 'Астана', 'Шымкент', 'Қарағанды', 'Ақтөбе', 'Тараз', 'Павлодар', 'Өскемен'];

// Тамақ ресторандар / сатушылар
const FOOD_SELLERS = [
    { name: 'Айгерім', logo: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop' },
    { name: 'Диас', logo: 'https://images.unsplash.com/photo-1547425260-76bcad5ce729?w=150&h=150&fit=crop' },
    { name: 'Гүлзира', logo: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop' },
    { name: 'Рүстем', logo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop' },
    { name: 'Камила', logo: 'https://images.unsplash.com/photo-1554151228-14d9def656e4?w=150&h=150&fit=crop' },
    { name: 'Арман', logo: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop' },
    { name: 'Шеф Еркебұлан', logo: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150&h=150&fit=crop' },
    { name: 'Мәдина', logo: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&h=150&fit=crop' },
    { name: 'Жандос', logo: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&h=150&fit=crop' },
    { name: 'Бағдат', logo: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&h=150&fit=crop' },
];

const MEAL_TYPE_MAP = {
    'breakfast': 'Таң ертеңгілік',
    'lunch': 'Түскі ас',
    'dinner': 'Кешкі ас',
    'snack': 'Тағамдар',
    'appetizer': 'Алғашқы тағам',
    'dessert': 'Тәттілер',
    'side-dish': 'Гарнир',
    'beverage': 'Сусындар',
};

function randItem(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

const TRANSLATE_ENDPOINT = "https://translate.googleapis.com/translate_a/single";
const translateCache = new Map();

const translate = async (text, targetLang) => {
    const source = String(text || "").trim();
    if (!source) return source;
    const cacheKey = `${targetLang}:${source}`;
    if (translateCache.has(cacheKey)) return translateCache.get(cacheKey);
    try {
        const url = `${TRANSLATE_ENDPOINT}?client=gtx&sl=auto&tl=${targetLang}&dt=t&q=${encodeURIComponent(source)}`;
        const res = await fetch(url);
        const data = await res.json();
        const translated = Array.isArray(data) && Array.isArray(data[0])
            ? data[0].map((chunk) => chunk[0]).join("")
            : source;
        translateCache.set(cacheKey, translated);
        return translated;
    } catch (_) {
        return source;
    }
};

const translateList = async (list, targetLang) => {
    if (!Array.isArray(list) || list.length === 0) return [];
    const joined = list.join("\n");
    const translated = await translate(joined, targetLang);
    return String(translated || "")
        .split("\n")
        .map((item) => item.trim())
        .filter((item) => item.length > 0);
};

const buildRecipeDescription = (labels, ingredients, steps) => {
    const blocks = [];
    if (ingredients.length > 0) blocks.push(`${labels.ingredients} ${ingredients.join(', ')}`);
    if (steps.length > 0) blocks.push(`${labels.steps} ${steps.join(' ')}`);
    return blocks.join('\n');
};

async function seed() {
    await mongoose.connect(MONGO);
    console.log('--- MongoDB-ге қосылды ---');

    console.log('Тауарларды тазалау...');
    await Product.deleteMany({});

    console.log('Рецепттер жинау (100 дана)...');
    let allRecipes = [];
    
    // DummyJSON
    try {
        const res = await fetch('https://dummyjson.com/recipes?limit=50');
        const data = await res.json();
        allRecipes = allRecipes.concat(data.recipes || []);
        const res2 = await fetch('https://dummyjson.com/recipes?limit=50&skip=50');
        const data2 = await res2.json();
        allRecipes = allRecipes.concat(data2.recipes || []);
    } catch (e) { console.error('DummyJSON error:', e); }

    // TheMealDB
    const categories = ['Beef', 'Chicken', 'Seafood', 'Vegetarian', 'Pasta', 'Dessert'];
    for (const cat of categories) {
        if (allRecipes.length >= 100) break;
        try {
            const res = await fetch(`https://www.themealdb.com/api/json/v1/1/filter.php?c=${cat}`);
            const data = await res.json();
            if (data.meals) {
                for (const m of data.meals.slice(0, 10)) {
                    const detailRes = await fetch(`https://www.themealdb.com/api/json/v1/1/lookup.php?i=${m.idMeal}`);
                    const detailData = await detailRes.json();
                    const full = detailData.meals[0];
                    const ingredients = [];
                    for (let i = 1; i <= 20; i++) {
                        if (full[`strIngredient${i}`]?.trim()) ingredients.push(full[`strIngredient${i}`]);
                    }
                    allRecipes.push({
                        name: full.strMeal,
                        image: full.strMealThumb,
                        ingredients: ingredients,
                        instructions: full.strInstructions ? [full.strInstructions] : [],
                        mealType: [full.strCategory]
                    });
                }
            }
        } catch(e) {}
    }

    console.log(`Жиналған рецепттер саны: ${allRecipes.length}`);

    const products = [];
    const targetCount = Math.min(100, allRecipes.length);

    for (let i = 0; i < targetCount; i++) {
        const recipe = allRecipes[i];
        const seller = randItem(FOOD_SELLERS);
        const location = randItem(LOCATIONS);
        const price = (Math.floor(Math.random() * 100) + 10) * 100; // 1000 - 11000

        const category = MEAL_TYPE_MAP[(recipe.mealType[0] || '').toLowerCase()] || 'Тағамдар';

        // Переводы
        console.log(`[${i+1}/${targetCount}] Перевод: ${recipe.name}`);
        const titleRu = await translate(recipe.name, 'ru');
        const titleKz = await translate(recipe.name, 'kk');
        
        const ingRu = await translateList(recipe.ingredients, 'ru');
        const ingKz = await translateList(recipe.ingredients, 'kk');
        
        const stepsRu = await translateList(recipe.instructions, 'ru');
        const stepsKz = await translateList(recipe.instructions, 'kk');

        const descRu = buildRecipeDescription({ ingredients: 'Состав:', steps: 'Приготовление:' }, ingRu, stepsRu);
        const descKz = buildRecipeDescription({ ingredients: 'Құрамы:', steps: 'Дайындалуы:' }, ingKz, stepsKz);

        products.push({
            title: titleKz || recipe.name, // По умолчанию КЗ заголовок
            titleRu: titleRu,
            description: buildRecipeDescription({ ingredients: 'Ingredients:', steps: 'Steps:' }, recipe.ingredients, recipe.instructions),
            descriptionRu: descRu,
            descriptionKz: descKz,
            imageUrl: recipe.image,
            category: category,
            price: price,
            location: location,
            sellerId: seller.name.toLowerCase(),
            sellerName: seller.name,
            sellerLogo: seller.logo,
            ingredients: recipe.ingredients,
            ingredientsRu: ingRu,
            ingredientsKz: ingKz,
            steps: recipe.instructions,
            stepsRu: stepsRu,
            stepsKz: stepsKz
        });

        // Slow down to avoid block
        await new Promise(r => setTimeout(r, 150));
    }

    await Product.insertMany(products);
    console.log(`✅ ${products.length} рецепт қосылды!`);
    process.exit(0);
}

seed().catch(err => { console.error(err); process.exit(1); });
