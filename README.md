# DIAS — CookPad (Рецепттер әлемі)

Мобильное приложение на Flutter для каталога/маркетплейса еды и рецептов с рекомендациями и ИИ‑поиском. Клиент работает с Node.js API, которое хранит данные в MongoDB и умеет выдавать рекомендации.

## Возможности

- Регистрация, вход, гостевой режим
- Восстановление пароля по email
- Лента товаров/рецептов с карточками и изображениями
- Поиск по категориям и названию
- ИИ‑поиск (Gemini при наличии ключа, иначе mock)
- Рекомендации на основе корзины и избранного
- Избранное
- Корзина: изменение количества, удаление, checkout
- Профиль: данные пользователя, адрес доставки, добавление товара
- Админ‑панель: пользователи и рецепты/товары (CRUD)

## Технологии

- Flutter, Dart `^3.9.2`
- Node.js + Express
- MongoDB + Mongoose
- Google Gemini (опционально, для AI‑поиска и рекомендаций)
- Nodemailer (сброс пароля)
- cached_network_image, http

## Структура проекта

- `lib/` — Flutter‑клиент и экраны
- `lib/api.dart` — слой API для клиента
- `lib/server/` — Node.js backend (Express, модели, сиды)
- `assets/images/` — локальные изображения
- `test/` — Flutter‑тесты

## Установка

1. Установите Flutter и зависимости проекта.

```bash
flutter pub get
```

2. Установите Node‑зависимости в корне (нужны для Gemini).

```bash
npm install
```

3. Установите Node‑зависимости для backend.

```bash
cd lib/server
npm install
```

## Настройка окружения

1. `lib/server/.env`:

```bash
GEMINI_API_KEY=...
```

2. MongoDB:

- В `lib/server/backend.js` используется захардкоженный `MONGO_URI`. При необходимости замените на свой.
- Скрипты `seed.js`, `seed_marketplace.js`, `create_admin.js` читают `MONGO_URI` из переменной окружения (если задана).

## Запуск

1. Запустите backend.

```bash
cd lib/server
npm start
```

2. Укажите базовый URL для мобильного клиента:

- `lib/api.dart`
- `lib/login.dart`
- `lib/registration.dart`
- `lib/forgot_password.dart`

Примеры базового URL:

- Android emulator: `http://10.0.2.2:3001/api`
- iOS simulator: `http://127.0.0.1:3001/api`
- Физическое устройство: `http://<LAN_IP>:3001/api`

3. Запустите приложение.

```bash
flutter run
```

## Сиды и данные

- `node seed.js` — добавляет примерные рецепты
- `node seed_marketplace.js` — загружает рецепты из DummyJSON и создает ~500 товаров
- `node create_admin.js` — создает/обновляет администратора

Админ по умолчанию (из `create_admin.js`):

- email: `admin@mail.com`
- пароль: `Admin@2026`

## API (кратко)

- `GET /api/products`
- `GET /api/products/:id`
- `GET /api/products/recommended/:userId`
- `POST /api/products/add`
- `POST /api/products/ai-search`
- `POST /api/register`
- `POST /api/login`
- `GET /api/user/:id`
- `PUT /api/user/:id/address`
- `GET /api/favorites/:userId`
- `POST /api/favorites/toggle`
- `GET /api/cart/:userId`
- `POST /api/cart/add`
- `PUT /api/cart/update`
- `DELETE /api/cart/remove`
- `POST /api/cart/checkout`
- `POST /api/forgot-password/send-code`
- `POST /api/forgot-password/verify-code`
- `POST /api/forgot-password/reset`
- `GET /api/admin/users`
- `POST /api/admin/users`
- `PUT /api/admin/users/:id`
- `DELETE /api/admin/users/:id`
- `GET /api/admin/recipes`
- `POST /api/admin/recipes`
- `PUT /api/admin/recipes/:id`
- `DELETE /api/admin/recipes/:id`

## Тесты

- `flutter test` — Flutter‑тесты в `test/`
- `npm test` — Jest (если добавите JS‑тесты в `lib/server/tests`)

## Известные ограничения

- В `ForgotPasswordScreen` используется endpoint `.../reset-password`, а backend ожидает `.../reset`.
- В `forgot_password_handler.js` захардкожены gmail‑учетка и app‑password. Рекомендуется вынести в `.env`.
- В backend нет чтения `MONGO_URI` из `.env` (используется строка в `backend.js`).
- Для AI‑поиска и рекомендаций без `GEMINI_API_KEY` используется mock‑логика.
- Модель `Product` используется и для товаров, и для рецептов (поля `ingredients`, `steps`, `videoUrl` пишутся без схемы).
