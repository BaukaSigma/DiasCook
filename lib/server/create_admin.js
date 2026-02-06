const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./User');

const MONGO =
  process.env.MONGO_URI ||
  'mongodb+srv://flutter1:d123456789i@cluster0.vyymexk.mongodb.net/menu_project?retryWrites=true&w=majority';

const ADMIN = {
  name: 'Әкімші',
  surname: 'Басқарушы',
  email: 'admin@mail.com',
  phone: '+7 777 000 00 00',
  password: 'Admin@2026',
  isAdmin: true,
};

async function run() {
  await mongoose.connect(MONGO, {});

  const existing = await User.findOne({ email: ADMIN.email }).select('+password');

  const hashed = await bcrypt.hash(ADMIN.password, 10);

  if (existing) {
    existing.name = ADMIN.name;
    existing.surname = ADMIN.surname;
    existing.phone = ADMIN.phone;
    existing.password = hashed;
    existing.isAdmin = true;
    await existing.save();
    console.log('[Admin] Жаңартылды:', ADMIN.email);
  } else {
    await User.create({
      name: ADMIN.name,
      surname: ADMIN.surname,
      email: ADMIN.email,
      phone: ADMIN.phone,
      password: hashed,
      isAdmin: true,
    });
    console.log('[Admin] Қосылды:', ADMIN.email);
  }

  await mongoose.disconnect();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
