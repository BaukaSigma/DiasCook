// seed_marketplace.js — Тек тамақ/рецепт тауарлары (DummyJSON Recipes API)
const mongoose = require('mongoose');
const Product = require('./Product');

const MONGO =
    process.env.MONGO_URI ||
    'mongodb+srv://flutter1:d123456789i@cluster0.vyymexk.mongodb.net/menu_project?retryWrites=true&w=majority';

// Қазақстандық қалалар
const LOCATIONS = ['Алматы', 'Астана', 'Шымкент', 'Қарағанды', 'Ақтөбе', 'Тараз', 'Павлодар', 'Өскемен'];

// Тамақ ресторандар / сатушылар
const FOOD_SELLERS = [
    { name: 'BurgerKing KZ', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Burger_King_2020.svg/480px-Burger_King_2020.svg.png' },
    { name: 'KFC Kazakhstan', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/b/bf/KFC_logo.svg/480px-KFC_logo.svg.png' },
    { name: 'Pizza Hut', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d2/Pizza_Hut_logo.svg/480px-Pizza_Hut_logo.svg.png' },
    { name: 'Subway KZ', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Subway_2016_logo.svg/480px-Subway_2016_logo.svg.png' },
    { name: 'Dodo Pizza', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Dodo_Pizza_logo.svg/480px-Dodo_Pizza_logo.svg.png' },
    { name: 'Мәдени Дастархан', logo: '' },
    { name: 'Алматы Кухні', logo: '' },
    { name: 'Шеф Yel', logo: '' },
    { name: 'Home Cook KZ', logo: '' },
    { name: 'Baza Kitchen', logo: '' },
];

// Категориялар → қаза тіліне
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

const LABEL_INGREDIENTS = '\u0421\u043e\u0441\u0442\u0430\u0432:';
const LABEL_CUISINE = '\u041a\u0443\u0445\u043d\u044f:';
const LABEL_DIFFICULTY = '\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c:';
const LABEL_TIME = '\u0412\u0440\u0435\u043c\u044f \u043f\u0440\u0438\u0433\u043e\u0442\u043e\u0432\u043b\u0435\u043d\u0438\u044f:';
const LABEL_PREP = '\u041f\u043e\u0434\u0433\u043e\u0442\u043e\u0432\u043a\u0430';
const LABEL_COOK = '\u0413\u043e\u0442\u043e\u0432\u043a\u0430';
const LABEL_MIN = '\u043c\u0438\u043d.';
const LABEL_SERVINGS = '\u041f\u043e\u0440\u0446\u0438\u0439:';
const LABEL_CALORIES = '\u041a\u043a\u0430\u043b/\u043f\u043e\u0440\u0446\u0438\u044f:';
const LABEL_TAGS = '\u0422\u0435\u0433\u0438:';
const LABEL_STEPS = '\u041f\u0440\u0438\u0433\u043e\u0442\u043e\u0432\u043b\u0435\u043d\u0438\u0435:';

const TRANSLATE_TO_RU = process.env.TRANSLATE_TO_RU === "1";
const TRANSLATE_ENDPOINT = process.env.TRANSLATE_API_URL || "https://translate.googleapis.com/translate_a/single";
const translateCache = new Map();

const translateToRu = async (text) => {
    if (!TRANSLATE_TO_RU) return text;
    const source = String(text || "");
    if (!source.trim()) return source;
    if (translateCache.has(source)) return translateCache.get(source);
    try {
        const url = `${TRANSLATE_ENDPOINT}?client=gtx&sl=auto&tl=ru&dt=t&q=${encodeURIComponent(source)}`;
        const res = await fetch(url);
        const data = await res.json();
        const translated = Array.isArray(data) && Array.isArray(data[0])
            ? data[0].map((chunk) => chunk[0]).join("")
            : source;
        translateCache.set(source, translated);
        return translated;
    } catch (_) {
        return source;
    }
};

const translateListToRu = async (list) => {
    if (!TRANSLATE_TO_RU) return [];
    if (!Array.isArray(list) || list.length == 0) return [];
    const joined = list.join("\n");
    const translated = await translateToRu(joined);
    return String(translated)
        .split("\n")
        .map((item) => item.trim())
        .filter((item) => item.length > 0);
};

const DIFFICULTY_MAP = {
    Easy: '\u041b\u0435\u0433\u043a\u043e',
    Medium: '\u0421\u0440\u0435\u0434\u043d\u0435',
    Hard: '\u0421\u043b\u043e\u0436\u043d\u043e',
};

const translateDifficulty = (value) => {
    if (!value) return "";
    const text = String(value).trim();
    return DIFFICULTY_MAP[text] || text;
};

const normalizeList = (value) => {
    if (!value) return [];
    if (Array.isArray(value)) {
        return value
            .map((item) => String(item).trim())
            .filter((item) => item.length > 0);
    }
    const single = String(value).trim();
    return single ? [single] : [];
};

const buildRecipeDescription = (recipe, ingredients, steps, tags) => {
    const blocks = [];

    if (ingredients.length > 0) {
        blocks.push(`${LABEL_INGREDIENTS} ${ingredients.join(', ')}`);
    }

    const meta = [];
    if (recipe.cuisine) meta.push(`${LABEL_CUISINE} ${String(recipe.cuisine)}`);
    if (recipe.difficulty) meta.push(`${LABEL_DIFFICULTY} ${translateDifficulty(recipe.difficulty)}`);

    const prepTime = Number(recipe.prepTimeMinutes) || 0;
    const cookTime = Number(recipe.cookTimeMinutes) || 0;
    if (prepTime || cookTime) {
        const timeParts = [];
        if (prepTime) timeParts.push(`${LABEL_PREP} ${prepTime} ${LABEL_MIN}`);
        if (cookTime) timeParts.push(`${LABEL_COOK} ${cookTime} ${LABEL_MIN}`);
        meta.push(`${LABEL_TIME} ${timeParts.join(', ')}`);
    }

    if (recipe.servings) meta.push(`${LABEL_SERVINGS} ${recipe.servings}`);
    if (recipe.caloriesPerServing) meta.push(`${LABEL_CALORIES} ${recipe.caloriesPerServing}`);
    if (tags.length > 0) meta.push(`${LABEL_TAGS} ${tags.join(', ')}`);

    if (meta.length > 0) {
        blocks.push(meta.join(' | '));
    }

    if (steps.length > 0) {
        blocks.push(`${LABEL_STEPS} ${steps.join(' ')}`);
    }

    return blocks.join('\n');
};

async function seed() {
    await mongoose.connect(MONGO);
    console.log('--- MongoDB-ге қосылды ---');

    console.log('Ескі тауарларды өшіруде...');
    await Product.deleteMany({});
    console.log('Өшірілді.');

    // DummyJSON-нан рецепттер жүктеу (max 100 per request, limit=50 skip=0 + skip=50)
    const urls = [
        'https://dummyjson.com/recipes?limit=50&skip=0',
        'https://dummyjson.com/recipes?limit=50&skip=50',
    ];

    let allRecipes = [];
    for (const url of urls) {
        const res = await fetch(url);
        const data = await res.json();
        allRecipes = allRecipes.concat(data.recipes || []);
    }
    console.log(`DummyJSON-нан 500 рецепт жүктелді.`);

    // 500 тауарға дейін көбейту (рецепттерді қайталай отырып)
    const products = [];
    for (let i = 0; i < 500; i++) {
        const recipe = allRecipes[i % allRecipes.length];
        const seller = randItem(FOOD_SELLERS);
        const location = randItem(LOCATIONS);

        // Бағаны теңгеде генерациялау (300 ₸ - 12000 ₸)
        const basePrice = Math.floor(Math.random() * 11700) + 300;
        const priceRounded = Math.round(basePrice / 100) * 100;

        // Категорияны аудару
        const mealTypes = recipe.mealType || [];
        const mainType = mealTypes[0] ? mealTypes[0].toLowerCase() : 'snack';
        const category = MEAL_TYPE_MAP[mainType] || 'Тағамдар';

        // Тауар атауы: егер бірдей болмас үшін нөмір қосу
        const titleSuffix = i < allRecipes.length ? '' : ` (${Math.floor(i / allRecipes.length) + 1})`;

        const ingredients = normalizeList(recipe.ingredients);
        const steps = normalizeList(recipe.instructions);
        const tags = normalizeList(recipe.tags);
        const description = buildRecipeDescription(recipe, ingredients, steps, tags);

        const ingredientsRu = await translateListToRu(ingredients);
        const stepsRu = await translateListToRu(steps);
        const tagsRu = await translateListToRu(tags);
        const descriptionRu = ingredientsRu.length || stepsRu.length || tagsRu.length
            ? buildRecipeDescription(recipe, ingredientsRu, stepsRu, tagsRu)
            : '';


        products.push({
            title: `${recipe.name}${titleSuffix}`,
            description,
            imageUrl: recipe.image || 'assets/images/soup.jpg',
            category,
            price: priceRounded,
            condition: 'Жаңа',   // тамақ — жаңа
            location,
            sellerId: seller.name.toLowerCase().replace(/\s/g, '_'),
            sellerName: seller.name,
            sellerLogo: seller.logo,
            ingredients,
            steps,
            ingredientsRu,
            stepsRu,
            descriptionRu,
        });
    }

    console.log('Дерекқорға сақтауда...');
    await Product.insertMany(products);
    console.log(`✅ Сәтті аяқталды: ${products.length} тауар қосылды!`);
    process.exit(0);
}

seed().catch(err => {
    console.error('❌ Қате:', err);
    process.exit(1);
});
