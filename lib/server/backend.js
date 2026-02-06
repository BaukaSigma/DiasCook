// backend.js

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');

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
    app.listen(PORT, () => {
      console.log(`[Express] Сервер портта жұмыс істеп тұр ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('[MongoDB] қосылу қатесі:', err.message);
    process.exit(1);
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
            }
        });

    } catch (e) {
        console.error('GET /api/user/:id ошибка:', e);
        res.status(500).json({ ok: false, error: 'Деректерді алу кезінде сервер қатесі.' });
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

// 6. Рецепт қосу
app.post('/api/admin/recipes', async (req, res) => {
    try {
        const {
            title,
            description,
            imageUrl,
            category,
            ingredients,
            steps,
            videoUrl,
        } = req.body;

        if (!title || !description) {
            return res.status(400).json({ ok: false, error: 'Атауы мен сипаттамасы міндетті.' });
        }

        const newRecipe = await Product.create({
            title: String(title).trim(),
            description: String(description).trim(),
            imageUrl: imageUrl ? String(imageUrl).trim() : undefined,
            category: category ? String(category).trim() : undefined,
            ingredients: normalizeList(ingredients),
            steps: normalizeList(steps),
            videoUrl: videoUrl ? String(videoUrl).trim() : '',
        });

        res.status(201).json({ ok: true, recipe: newRecipe });
    } catch (e) {
        console.error('POST /api/admin/recipes қатесі:', e);
        res.status(500).json({ ok: false, error: 'Сервер қатесі.' });
    }
});

// 7. Рецептті жаңарту
app.put('/api/admin/recipes/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            title,
            description,
            imageUrl,
            category,
            ingredients,
            steps,
            videoUrl,
        } = req.body;

        const update = {};
        if (title) update.title = String(title).trim();
        if (description) update.description = String(description).trim();
        if (imageUrl) update.imageUrl = String(imageUrl).trim();
        if (category) update.category = String(category).trim();
        if (typeof ingredients !== 'undefined') update.ingredients = normalizeList(ingredients);
        if (typeof steps !== 'undefined') update.steps = normalizeList(steps);
        if (typeof videoUrl !== 'undefined') update.videoUrl = String(videoUrl).trim();

        const updated = await Product.findByIdAndUpdate(id, update, { new: true });
        if (!updated) {
            return res.status(404).json({ ok: false, error: 'Рецепт табылмады.' });
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

        // Жалпы соманы есептеу
        const total = cartItems.reduce((sum, item) => sum + (item.quantity * item.productId.price), 0);

        // Flutter-ге ыңғайлы форматта қайтару
        const formattedItems = cartItems.map(item => ({
            _id: item._id, // Себет элементінің ID-і
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
