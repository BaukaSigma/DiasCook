// backend.js

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');

// AI баптаулары
require('dotenv').config();
const { GoogleGenAI } = require('@google/genai');

let ai = null;
try {
    if (process.env.GEMINI_API_KEY) {
        ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
        console.log('[AI] Gemini API ключі табылды, ИИ қосылды.');
    } else {
        console.warn('[AI] GEMINI_API_KEY табылмады, Mock ИИ қолданылуда.');
    }
} catch (e) {
    console.error('[AI] Gemini инициализация қатесі:', e);
}

// Модельдерді импорттау
const Product = require('./Product');
const Cart = require('./Cart');
const User = require('./User');
// Құпия сөзді қалпына келтіру логикасын импорттау
const {
    sendResetCode,
    verifyResetCode,
    resetPassword,
    validatePassword // Тіркеу үшін қажет
} = require('./forgot_password_handler');

const app = express();

const normalizeList = (value) => {
    if (!value) return [];
    if (Array.isArray(value)) {
        return value.map((item) => String(item).trim()).filter((item) => item.length > 0);
    }
    if (typeof value === 'string') {
        return value
            .split('\n')
            .map((item) => item.trim())
            .filter((item) => item.length > 0);
    }
    return [];
};

// Middleware
app.use(cors());
app.use(express.json());

const MONGO_URI = 'mongodb+srv://flutter1:d123456789i@cluster0.vyymexk.mongodb.net/menu_project?retryWrites=true&w=majority';
const PORT = process.env.PORT || 3001;

// MongoDB-ге қосылу
mongoose
    .connect(MONGO_URI, {})
    .then(() => {
        console.log('[MongoDB] қосылды:', MONGO_URI);
    })
    .catch((err) => {
        console.error('[MongoDB] қосылу қатесі:', err.message);
        console.warn('[Express] Жұмыс жалғасуда (тек email жіберу және т.б. MongoDB-сіз істейді)');
    })
    .finally(() => {
        app.listen(PORT, () => {
            console.log(`[Express] Сервер портта жұмыс істеп тұр ${PORT}`);
        });
    });

// Негізгі тексеру маршруты
app.get('/', (_req, res) => {
    res.json({
        ok: true,
        message: 'API ОК',
        time: new Date().toISOString(),
    });
});

// Барлық өнімдерді алу
app.get('/api/products', async (_req, res) => {
    try {
        const products = await Product.find({});
        res.status(200).json(products);
    } catch (e) {
        console.error('GET /api/products қатесі:', e);
        res.status(500).json({ error: 'Сервер қатесі.' });
    }
});

// Өнімді ID арқылы алу
app.get('/api/products/:id', async (req, res) => {
    try {
        const product = await Product.findById(req.params.id);
        if (!product) {
            return res.status(404).json({ error: 'Өнім табылмады.' });
        }
        res.status(200).json(product);
    } catch (e) {
        console.error('GET /api/products/:id қатесі:', e);
        res.status(500).json({ error: 'Сервер қатесі.' });
    }
});

// ML Рекомендациялар: Пайдаланушының талғамына байланысты (Корзина + Лайктар)
app.get('/api/products/recommended/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const allProducts = await Product.find({});

        // 1. Егер қонақ (guest) болса, соңғы (кездейсоқ) 20 тауар
        if (userId === 'guest' || !userId) {
            const shuffled = allProducts.sort(() => 0.5 - Math.random());
            return res.status(200).json(shuffled.slice(0, 20));
        }

        // 2. Пайдаланушының тарихын жинау
        const cartItems = await Cart.find({ userId }).populate('productId');
        const favItems = await Favorite.find({ userId }).populate('productId');

        const interactedProducts = [
            ...cartItems.map(c => c.productId),
            ...favItems.map(f => f.productId)
        ].filter(p => p != null); // Тауар жойылып кеткен жағдайды алдын алу

        // 3. Егер тарих бос болса, кездейсоқ тауар қалтарымыз
        if (interactedProducts.length === 0) {
            const shuffled = allProducts.sort(() => 0.5 - Math.random());
            return res.status(200).json(shuffled.slice(0, 20));
        }

        // 4. Пайдаланушы нені ұнататынын талдау (Категориялар және Сөздер)
        const categories = {};
        const titles = [];

        interactedProducts.forEach(p => {
            if (p.category) {
                categories[p.category] = (categories[p.category] || 0) + 1;
            }
            if (p.title) {
                titles.push(p.title);
            }
        });

        // Ең танымал категорияларды табу
        const sortedCategories = Object.keys(categories).sort((a, b) => categories[b] - categories[a]);
        const topCategories = sortedCategories.slice(0, 3); // Үздік 3 категория

        // 5. ИИ арқылы ұсыныстар (Егер API кілті болса)
        if (ai) {
            try {
                const prompt = `Пайдаланушы мынадай категорияларды ұнатады: ${topCategories.join(', ')}. 
Ол бұған дейін мына тауарларды қараған/алған: ${titles.slice(0, 10).join(', ')}.
Біздің база: ${JSON.stringify(allProducts.map(p => ({ id: p._id.toString(), title: p.title, category: p.category })))}
Тапсырма: Осы қолданушыға ең қисынды 20 ұсыныс жаса. 
Жауап ТЕК валидті JSON массив ID-лерден тұрсын. ["id1", "id2"]`;

                const response = await ai.models.generateContent({
                    model: 'gemini-2.5-flash',
                    contents: prompt,
                    config: { responseMimeType: "application/json" }
                });

                let aiResult = JSON.parse(response.text);
                if (Array.isArray(aiResult) && aiResult.length > 0) {
                    let recommended = allProducts.filter(p => aiResult.includes(p._id.toString()));
                    return res.status(200).json(recommended);
                }
            } catch (geminiEx) {
                console.error("ML Gemini Error:", geminiEx);
                // Қате болса - Mock-қа түсу
            }
        }

        // 6. Mock AI (Егер кілт жоқ болса немесе Gemini істемесе)
        // Үздік категорияларға жататын тауарларды іздейміз
        let recommendedProducts = allProducts.filter(p => topCategories.includes(p.category));

        // Оларға қоса тағы кездейсоқ тауарлар (жаңалық үшін)
        const others = allProducts.filter(p => !topCategories.includes(p.category));
        const randomDocs = others.sort(() => 0.5 - Math.random()).slice(0, 5);

        recommendedProducts = [...recommendedProducts, ...randomDocs];
        // Өзіне өзін қайталамас үшін уникалды етіп қалдыру
        const uniqueRecs = Array.from(new Set(recommendedProducts.map(p => p._id.toString())))
            .map(id => recommendedProducts.find(p => p._id.toString() === id));

        // Егер тауар көп болса, жай 20 тауар қайтарамыз араластырып
        const finalShuffled = uniqueRecs.sort(() => 0.5 - Math.random()).slice(0, 20);

        res.status(200).json(finalShuffled);
    } catch (e) {
        console.error('GET /api/products/recommended қатесі:', e);
        res.status(500).json({ error: 'Сервер қатесі.' });
    }
});

// Қарапайым пайдаланушылар үшін тауар қосу
app.post('/api/products/add', async (req, res) => {
    try {
        const {
            title,
            description,
            imageUrl,
            category,
            price,
            condition,
            location,
            sellerId,
        } = req.body;

        if (!title) {
            return res.status(400).json({ ok: false, error: 'Атауы міндетті.' });
        }

        const newProduct = await Product.create({
            title: String(title).trim(),
            description: description ? String(description).trim() : '',
            imageUrl: imageUrl ? String(imageUrl).trim() : undefined,
            category: category ? String(category).trim() : undefined,
            price: price ? Number(price) : 0,
            condition: condition ? String(condition).trim() : 'Жаңа',
            location: location ? String(location).trim() : 'Алматы',
            sellerId: sellerId ? String(sellerId).trim() : 'guest',
        });

        res.status(201).json({ ok: true, product: newProduct });
    } catch (e) {
        console.error('POST /api/products/add қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// ИИ арқылы тауар іздеу (Нақты Gemini немесе Mock)
app.post('/api/products/ai-search', async (req, res) => {
    try {
        const { query } = req.body;
        if (!query) {
            return res.status(400).json({ ok: false, error: 'Сұрау бос болмауы керек.' });
        }

        // Барлық тауарларды алу
        const allProducts = await Product.find({});
        let recommendations = [];
        let aiMessage = '';

        if (ai) {
            // Реальный Gemini
            try {
                // Контекст үшін тек қажет мәліметтерді аламыз (id, title, category, price)
                const simplifiedProducts = allProducts.map(p => ({
                    id: p._id.toString(),
                    title: p.title,
                    category: p.category,
                    price: p.price
                }));

                const prompt = `Пайдаланушы келесіні іздейді: "${query}". 
Біздің мәліметтер базасындағы тауарлар (JSON форматында):
${JSON.stringify(simplifiedProducts)}

Тапсырма: Жоғарыдағы тізімнен осы сұрауға ең сәйкес келетін 1-ден 5-ке дейінгі тауарларды таңда. 
Жауап ретінде ТЕК қана таңдалған тауарлардың ID-лері бар валидті JSON массив қайтар, басқа ештеңе жазба. Егер ештеңе сәйкес келмесе, бос массив [] қайтар. Мысал: ["64abc123...", "64abc124..."]`;

                const response = await ai.models.generateContent({
                    model: 'gemini-2.5-flash',
                    contents: prompt,
                    config: {
                        responseMimeType: "application/json",
                    }
                });

                let aiResult = [];
                try {
                    aiResult = JSON.parse(response.text);
                } catch (e) {
                    console.error("Failed to parse AI response:", response.text);
                }

                if (Array.isArray(aiResult) && aiResult.length > 0) {
                    recommendations = allProducts.filter(p => aiResult.includes(p._id.toString()));
                }

                aiMessage = `ИИ (Gemini) сіздің "${query}" сұрауыңыз бойынша мына тауарларды тапты:`;

                if (recommendations.length === 0) {
                    // Егер Gemini ештеңе таппаса, кездейсоқ тауарлар
                    const shuffled = allProducts.sort(() => 0.5 - Math.random());
                    recommendations = shuffled.slice(0, 3);
                    aiMessage = `ИИ нақты сәйкестік таппады, бірақ мына тауарлар ұнауы мүмкін:`;
                }

            } catch (geminiError) {
                console.error("Gemini запрос қатесі:", geminiError);
                // Gemini қате берсе, мок жүйеге өтеді
                aiMessage = 'Gemini сұрауы орындалмады, стандартты іздеуге көшуде.';
                const lowerQuery = query.toLowerCase();
                recommendations = allProducts.filter(p =>
                    p.title.toLowerCase().includes(lowerQuery) ||
                    (p.category && p.category.toLowerCase().includes(lowerQuery))
                ).slice(0, 5);
                if (recommendations.length === 0) {
                    recommendations = allProducts.slice(0, 3);
                }
            }
        } else {
            // Mock AI Logic (Егер API кілті болмаса)
            const lowerQuery = query.toLowerCase();
            recommendations = allProducts.filter(p =>
                p.title.toLowerCase().includes(lowerQuery) ||
                (p.description && p.description.toLowerCase().includes(lowerQuery)) ||
                (p.category && p.category.toLowerCase().includes(lowerQuery))
            );

            if (recommendations.length === 0) {
                const shuffled = allProducts.sort(() => 0.5 - Math.random());
                recommendations = shuffled.slice(0, 3);
            } else {
                recommendations = recommendations.slice(0, 5);
            }
            aiMessage = `(Mock ИИ) "${query}" сұрауы бойынша мына тауарлар табылды:`;
        }

        res.status(200).json({
            ok: true,
            message: aiMessage,
            products: recommendations
        });
    } catch (e) {
        console.error('POST /api/products/ai-search қатесі:', e);
        res.status(500).json({ ok: false, error: 'ИИ Сервер қатесі.' });
    }
});



// ====================================================
// ҚОЛДАНУШЫ (USER) ЖӘНЕ АВТОРИЗАЦИЯ ENDPOINTS
// ====================================================

// 1. Тіркелу
app.post('/api/register', async (req, res) => {
    try {
        const { name, surname, email, phone, password } = req.body;

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ ok: false, error: 'Бұл email тіркелген.' });
        }

        if (!validatePassword(password)) {
            return res.status(400).json({
                ok: false,
                error: 'Құпия сөз кемінде 8 таңбадан тұруы керек және бір үлкен әріп, бір кіші әріп, бір сан және бір арнайы символ болуы керек.'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = new User({
            name,
            surname,
            email,
            phone,
            password: hashedPassword,
            isAdmin: false,
        });
        await newUser.save();

        res.status(201).json({
            ok: true,
            message: 'Пайдаланушы сәтті тіркелді!',
            userId: newUser.userId,
        });
    } catch (e) {
        console.error('POST /api/register қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 2. Кіру
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            return res.status(400).json({ ok: false, error: 'Дұрыс емес email немесе құпия сөз.' });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(400).json({ ok: false, error: 'Дұрыс емес email немесе құпия сөз.' });
        }

        res.status(200).json({
            ok: true,
            message: 'Сәтті кірді!',
            userId: user.userId,
            isAdmin: user.isAdmin === true,
            user: {
                userId: user.userId,
                name: user.name,
                surname: user.surname,
                email: user.email,
                phone: user.phone,
                isAdmin: user.isAdmin === true,
            }
        });
    } catch (e) {
        console.error('POST /api/login қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 3. Профиль деректерін алу (profile.dart үшін)
app.get('/api/user/:id', async (req, res) => { // ⬅️ Убедитесь, что здесь 'user' (единственное число)
    try {
        const userId = req.params.id;

        // Находим пользователя по userId и исключаем пароль (-password)
        const user = await User.findOne({ userId }).select('-password');

        if (!user) {
            return res.status(404).json({ ok: false, error: 'Пользователь не найден.' });
        }

        // Отправляем данные аккаунта в Flutter. 
        // Важно, чтобы данные были вложены в ключ 'user' (как было в предыдущем шаге).
        res.status(200).json({
            ok: true,
            user: {
                userId: user.userId,
                name: user.name,
                surname: user.surname,
                email: user.email,
                phone: user.phone,
                isAdmin: user.isAdmin === true,
                deliveryAddress: user.deliveryAddress || '',
            }
        });

    } catch (e) {
        console.error('GET /api/user/:id ошибка:', e);
        res.status(500).json({ ok: false, error: 'Деректерді алу кезінде сервер қатесі.' });
    }
});

// Жеткізу мекенжайын жаңарту
app.put('/api/user/:id/address', async (req, res) => {
    try {
        const { deliveryAddress } = req.body;
        const user = await User.findOne({ userId: req.params.id });
        if (!user) return res.status(404).json({ ok: false, error: 'Пайдаланушы табылмады.' });
        user.deliveryAddress = deliveryAddress || '';
        await user.save();
        res.json({ ok: true, deliveryAddress: user.deliveryAddress });
    } catch (e) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

// ====================================================
// ADMIN ENDPOINTS
// ====================================================

// 1. Барлық пайдаланушыларды алу
app.get('/api/admin/users', async (_req, res) => {
    try {
        const users = await User.find({}).select('-password');
        res.status(200).json({ ok: true, users });
    } catch (e) {
        console.error('GET /api/admin/users қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 2. Пайдаланушы қосу
app.post('/api/admin/users', async (req, res) => {
    try {
        const { name, surname, email, phone, password, isAdmin } = req.body;

        if (!name || !surname || !email || !phone || !password) {
            return res.status(400).json({ ok: false, error: 'Барлық өрістерді толтырыңыз.' });
        }

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ ok: false, error: 'Бұл email тіркелген.' });
        }

        if (!validatePassword(password)) {
            return res.status(400).json({
                ok: false,
                error: 'Құпиясөз кемінде 8 таңбадан тұруы керек (үлкен/кіші әріп, сан және арнайы символ).'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = await User.create({
            name: String(name).trim(),
            surname: String(surname).trim(),
            email: String(email).trim(),
            phone: String(phone).trim(),
            password: hashedPassword,
            isAdmin: isAdmin === true,
        });
        const safeUser = await User.findById(newUser._id).select('-password');

        res.status(201).json({ ok: true, user: safeUser });
    } catch (e) {
        console.error('POST /api/admin/users қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 3. Пайдаланушыны жаңарту
app.put('/api/admin/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, surname, email, phone, password, isAdmin } = req.body;

        let user = await User.findOne({ userId: id }).select('+password');
        if (!user) {
            user = await User.findById(id).select('+password');
        }
        if (!user) {
            return res.status(404).json({ ok: false, error: 'Пайдаланушы табылмады.' });
        }

        if (email && email !== user.email) {
            const emailExists = await User.findOne({ email });
            if (emailExists) {
                return res.status(400).json({ ok: false, error: 'Бұл email тіркелген.' });
            }
            user.email = String(email).trim();
        }

        if (name) user.name = String(name).trim();
        if (surname) user.surname = String(surname).trim();
        if (phone) user.phone = String(phone).trim();

        if (typeof isAdmin !== 'undefined') {
            user.isAdmin = isAdmin === true;
        }

        if (password) {
            if (!validatePassword(password)) {
                return res.status(400).json({
                    ok: false,
                    error: 'Құпиясөз кемінде 8 таңбадан тұруы керек (үлкен/кіші әріп, сан және арнайы символ).'
                });
            }
            user.password = await bcrypt.hash(password, 10);
        }

        await user.save();
        const safeUser = await User.findById(user._id).select('-password');

        res.status(200).json({ ok: true, user: safeUser });
    } catch (e) {
        console.error('PUT /api/admin/users/:id қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 4. Пайдаланушыны жою
app.delete('/api/admin/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        let user = await User.findOne({ userId: id });
        if (!user) {
            user = await User.findById(id);
        }
        if (!user) {
            return res.status(404).json({ ok: false, error: 'Пайдаланушы табылмады.' });
        }

        await user.deleteOne();
        res.status(200).json({ ok: true });
    } catch (e) {
        console.error('DELETE /api/admin/users/:id қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 5. Барлық рецепттерді алу (әкімші үшін)
app.get('/api/admin/recipes', async (_req, res) => {
    try {
        const recipes = await Product.find({});
        res.status(200).json({ ok: true, recipes });
    } catch (e) {
        console.error('GET /api/admin/recipes қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 6. Тауар қосу (Add Product)
app.post('/api/admin/recipes', async (req, res) => {
    try {
        const {
            title,
            description,
            imageUrl,
            category,
            price,
            condition,
            location,
            sellerId,
        } = req.body;

        if (!title) {
            return res.status(400).json({ ok: false, error: 'Атауы міндетті.' });
        }

        const newRecipe = await Product.create({
            title: String(title).trim(),
            description: description ? String(description).trim() : '',
            imageUrl: imageUrl ? String(imageUrl).trim() : undefined,
            category: category ? String(category).trim() : undefined,
            price: price ? Number(price) : 0,
            condition: condition ? String(condition).trim() : 'Жаңа',
            location: location ? String(location).trim() : 'Алматы',
            sellerId: sellerId ? String(sellerId).trim() : 'admin',
        });

        res.status(201).json({ ok: true, recipe: newRecipe });
    } catch (e) {
        console.error('POST /api/admin/recipes қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 7. Тауарды жаңарту (Update Product)
app.put('/api/admin/recipes/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            title,
            description,
            imageUrl,
            category,
            price,
            condition,
            location,
            sellerId,
        } = req.body;

        const update = {};
        if (title) update.title = String(title).trim();
        if (typeof description !== 'undefined') update.description = String(description).trim();
        if (imageUrl) update.imageUrl = String(imageUrl).trim();
        if (category) update.category = String(category).trim();
        if (typeof price !== 'undefined') update.price = Number(price);
        if (condition) update.condition = String(condition).trim();
        if (location) update.location = String(location).trim();
        if (sellerId) update.sellerId = String(sellerId).trim();

        const updated = await Product.findByIdAndUpdate(id, update, { new: true });
        if (!updated) {
            return res.status(404).json({ ok: false, error: 'Тауар табылмады.' });
        }

        res.status(200).json({ ok: true, recipe: updated });
    } catch (e) {
        console.error('PUT /api/admin/recipes/:id қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 8. Рецептті жою
app.delete('/api/admin/recipes/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const deleted = await Product.findByIdAndDelete(id);
        if (!deleted) {
            return res.status(404).json({ ok: false, error: 'Рецепт табылмады.' });
        }
        res.status(200).json({ ok: true });
    } catch (e) {
        console.error('DELETE /api/admin/recipes/:id қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// ====================================================
// СЕБЕТ (CART) ENDPOINTS
// ====================================================

// 1. Себет мазмұнын алу (userId бойынша)
app.get('/api/cart/:userId', async (req, res) => {
    try {
        const { userId } = req.params;

        const cartItems = await Cart.find({ userId }).populate('productId');

        // Жалпы соманы есептеу (тауар жойылған болса абай болу керек)
        const total = cartItems.reduce((sum, item) => {
            if (item.productId && typeof item.productId.price === 'number') {
                return sum + (item.quantity * item.productId.price);
            }
            return sum;
        }, 0);

        // Flutter-ге ыңғайлы форматта қайтару
        const formattedItems = cartItems
            .filter(item => item.productId != null) // Тек бар тауарларды қалдыру
            .map(item => ({
                _id: item._id,
                productId: item.productId._id,
                title: item.productId.title,
                imageUrl: item.productId.imageUrl,
                price: item.productId.price,
                quantity: item.quantity,
                subtotal: item.quantity * item.productId.price,
            }));

        res.status(200).json({ ok: true, items: formattedItems, total });
    } catch (e) {
        console.error('GET /api/cart/:userId қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});


// 2. Тауарды себетке қосу
app.post('/api/cart/add', async (req, res) => {
    try {
        const { userId, productId } = req.body;

        // Тауардың бар-жоғын тексеру
        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({ ok: false, error: 'Тауар табылмады.' });
        }

        // Себеттегі элементті табу немесе жаңасын құру
        let cartItem = await Cart.findOne({ userId, productId });

        if (cartItem) {
            // Егер бар болса, санын көбейту
            cartItem.quantity += 1;
            await cartItem.save();
            return res.status(200).json({ ok: true, message: 'Тауар себеттегі саны жаңартылды.' });
        } else {
            // Егер жоқ болса, жаңасын қосу
            cartItem = new Cart({ userId, productId, quantity: 1 });
            await cartItem.save();
            return res.status(200).json({ ok: true, message: 'Тауар себетке қосылды.' });
        }
    } catch (e) {
        console.error('POST /api/cart/add қатесі:', e);
        if (e.code === 11000) { // MongoDB duplicate key error (userId, productId index)
            return res.status(400).json({ ok: false, error: 'Тауар себетте бар. Санын өзгертіңіз.' });
        }
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 3. Себеттегі тауардың санын өзгерту
app.put('/api/cart/update', async (req, res) => {
    try {
        const { userId, productId, quantity } = req.body;

        if (quantity < 1) {
            return res.status(400).json({ ok: false, error: 'Сан 1-ден кем болмауы керек.' });
        }

        const cartItem = await Cart.findOne({ userId, productId });

        if (!cartItem) {
            return res.status(404).json({ ok: false, error: 'Себеттегі тауар табылмады.' });
        }

        cartItem.quantity = quantity;
        await cartItem.save();

        res.status(200).json({ ok: true, message: 'Тауар саны сәтті өзгертілді.' });
    } catch (e) {
        console.error('PUT /api/cart/update қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 4. Себеттен тауарды жою
app.delete('/api/cart/remove', async (req, res) => {
    try {
        const { userId, productId } = req.body; // DELETE-те body арқылы деректерді алу

        const result = await Cart.deleteOne({ userId, productId });

        if (result.deletedCount === 0) {
            return res.status(404).json({ ok: false, error: 'Себеттегі тауар табылмады.' });
        }

        res.status(200).json({ ok: true, message: 'Тауар себеттен сәтті жойылды.' });
    } catch (e) {
        console.error('DELETE /api/cart/remove қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 5. Сатып алу (Checkout)
app.post('/api/cart/checkout', async (req, res) => {
    try {
        const { userId } = req.body;

        // 1. Себет мазмұнын алу (тапсырыс жасау үшін)
        const cartItems = await Cart.find({ userId });

        if (cartItems.length === 0) {
            return res.status(400).json({ ok: false, error: 'Себет бос.' });
        }

        // 2. Тапсырыс жасау (бұл жерде "Order" моделіне сақтау керек)
        // ⚠️ Ескерту: "Order" моделі жоқ, сондықтан тек тазалауды орындаймыз.

        // 3. Себетті тазалау
        await Cart.deleteMany({ userId });

        res.status(200).json({ ok: true, message: '✅ Тапсырысыңыз қабылданды! Себет тазаланды.' });
    } catch (e) {
        console.error('POST /api/cart/checkout қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

const emailTransporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'disaisa01@gmail.com',
        pass: 'oyfjcgjtbkzifiyf'
    }
});

// Email жіберу маршруты
app.post('/api/send-email', async (req, res) => {
    try {
        const { to, subject, text, html } = req.body;
        if (!to || !subject) {
            return res.status(400).json({ ok: false, error: 'to және subject өрістері қажет.' });
        }
        await emailTransporter.sendMail({
            from: 'disaisa01@gmail.com',
            to,
            subject,
            text: text || '',
            html: html || ''
        });
        res.status(200).json({ ok: true, message: 'Email сәтті жіберілді.' });
    } catch (e) {
        console.error('POST /api/send-email қатесі:', e);
        res.status(500).json({ ok: false, error: e.message || 'Email жіберу сәтсіз аяқталды.' });
    }
});

// ====================================================
// ҚҰПИЯ СӨЗДІ ҚАЛПЫНА КЕЛТІРУ ENDPOINTS
// ====================================================

// 1. Код жіберу
app.post('/api/forgot-password/send-code', async (req, res) => {
    try {
        const { email } = req.body;
        const result = await sendResetCode(email);
        res.status(result.status).json(result);
    } catch (e) {
        console.error('POST /api/forgot-password/send-code қатесі:', e);
        res.status(500).json({ ok: false, error: e.message || 'Сервер қатесі.' });
    }
});

// 2. Кодты тексеру
app.post('/api/forgot-password/verify-code', (req, res) => {
    try {
        const { email, code } = req.body;
        const result = verifyResetCode(email, code);
        res.status(result.status).json(result);
    } catch (e) {
        console.error('POST /api/forgot-password/verify-code қатесі:', e);
        res.status(500).json({ ok: false, error: e.message || 'Сервер қатесі.' });
    }
});

// 3. Құпия сөзді жаңарту
app.post('/api/forgot-password/reset', async (req, res) => {
    try {
        const { email, newPassword } = req.body;
        const result = await resetPassword(email, newPassword);
        res.status(result.status).json(result);
    } catch (e) {
        console.error('POST /api/forgot-password/reset қатесі:', e);
        res.status(500).json({ ok: false, error: e.message || 'Сервер қатесі.' });
    }
});

const Favorite = require('./Favorites');

// Лайкты қосу немесе жою (Toggle)
app.post('/api/favorites/toggle', async (req, res) => {
    try {
        const { userId, productId } = req.body;
        const exists = await Favorite.findOne({ userId, productId });

        if (exists) {
            await Favorite.deleteOne({ userId, productId });
            return res.json({ ok: true, isLiked: false, message: 'Жойылды' });
        } else {
            await Favorite.create({ userId, productId });
            return res.json({ ok: true, isLiked: true, message: 'Қосылды' });
        }
    } catch (e) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

// Қолданушының барлық лайктарын алу
app.get('/api/favorites/:userId', async (req, res) => {
    try {
        const favs = await Favorite.find({ userId: req.params.userId }).populate('productId');
        // Тек тауарлар тізімін қайтару
        const products = favs.map(f => f.productId).filter(p => p != null);
        res.json(products);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});
