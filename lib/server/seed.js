const mongoose = require('mongoose');
const Product = require('./Product'); 

const MONGO = 
  process.env.MONGO_URI || 'mongodb+srv://flutter1:d123456789i@cluster0.vyymexk.mongodb.net/menu_project?retryWrites=true&w=majority';

async function run() {
  await mongoose.connect(MONGO, {});

  console.log('--- Очистка старых данных (Product) ---');
  await Product.deleteMany({});

  console.log('--- Добавление новых товаров (Product) ---');
  await Product.insertMany([
    {
      title: 'Қуырдақ (сиыр еті)', 
      sellerName: 'Дананың үй тағамдары',
      price: 3500, 
      imageUrl: 'assets/images/kuirdak.jpg', 
      description: 'Жаңа сойылған сиыр етінен және картоптан жасалған дәстүрлі қуырдақ. Үлкен порция.',
      category: 'Екінші тағамдар',
    },
    {
      title: 'Бауырсақтар',
      sellerName: 'Әжеден дәмді',
      price: 1200, 
      imageUrl: 'assets/images/baursak.jpg', 
      description: 'Мерекелік дастарханға арналған жұмсақ, майға піскен бауырсақтар. 1 кг.',
      category: 'Десерттер',
    },
    {
      title: 'Манты (буымен пісірілген)', 
      sellerName: 'Mami’s Homemade',
      price: 2800, 
      imageUrl: 'assets/images/manty.jpg', 
      description: 'Үй фаршынан дайындалған шырынды манты. 10 дана.',
      category: 'Екінші тағамдар',
    },
    {
      title: 'Борщ (классикалық)',
      sellerName: 'Орыс тағамдары',
      price: 1800, 
      imageUrl: 'assets/images/borsh.jpg', 
      description: 'Свежий, наваристый борщ со сметаной. Классический рецепт.',
      category: 'Бірінші тағамдар',
    },
  ]);

  console.log('--- Сидинг аяқталды ---');
  await mongoose.disconnect();
}

run().catch(err => console.error(err));