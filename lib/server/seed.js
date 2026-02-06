const mongoose = require('mongoose');
const Product = require('./Product');

const MONGO =
  process.env.MONGO_URI ||
  'mongodb+srv://flutter1:d123456789i@cluster0.vyymexk.mongodb.net/menu_project?retryWrites=true&w=majority';

const VIDEO_URL = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

async function run() {
  await mongoose.connect(MONGO, {});

  console.log('--- Деректерді тазалау (Product) ---');
  await Product.deleteMany({});

  console.log('--- Жаңа рецепттерді қосу ---');
  await Product.insertMany([
    // Бірінші тағамдар (3)
    {
      title: 'Борщ',
      imageUrl: 'assets/images/borsh.jpg',
      description: 'Қызылшадан дайындалатын қою сорпа.',
      category: 'Бірінші тағамдар',
      ingredients: ['Сиыр еті', 'Қызылша', 'Сәбіз', 'Картоп', 'Қырыққабат', 'Дәмдеуіштер'],
      steps: [
        'Етті қайнатып сорпа жасаңыз.',
        'Көкөністерді қуырып алыңыз.',
        'Бәрін сорпаға қосып, дайын болғанша қайнатыңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Том Ям',
      imageUrl: 'assets/images/tomyam.png',
      description: 'Ащы-қышқыл азиялық сорпа.',
      category: 'Бірінші тағамдар',
      ingredients: ['Асшаян', 'Лемонграсс', 'Саңырауқұлақ', 'Кокос сүті', 'Чили'],
      steps: [
        'Сорпаны қайнатып, дәмдеуіштерді қосыңыз.',
        'Асшаян мен саңырауқұлақты салыңыз.',
        'Кокос сүтін құйып, бірнеше минут пісіріңіз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Көкөніс сорпасы',
      imageUrl: 'assets/images/soup.jpg',
      description: 'Жеңіл әрі пайдалы көкөніс сорпасы.',
      category: 'Бірінші тағамдар',
      ingredients: ['Картоп', 'Сәбіз', 'Пияз', 'Болгар бұрышы', 'Дәмдеуіштер'],
      steps: [
        'Көкөністерді тураңыз.',
        'Суға салып, баяу отта пісіріңіз.',
        'Дәмдеуіштерді қосып, дайын болғанша қайнатыңыз.',
      ],
      videoUrl: VIDEO_URL,
    },

    // Екінші тағамдар (3)
    {
      title: 'Қуырдақ',
      imageUrl: 'assets/images/kuirdak.jpg',
      description: 'Қуырылған ет пен картоптан дайындалатын ұлттық тағам.',
      category: 'Екінші тағамдар',
      ingredients: ['Сиыр еті', 'Картоп', 'Пияз', 'Тұз', 'Бұрыш', 'Өсімдік майы'],
      steps: [
        'Етті текшелеп тураңыз.',
        'Қазанда майды қыздырып, етті қуырыңыз.',
        'Картоп пен пиязды қосып, дайын болғанша пісіріңіз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Манты',
      imageUrl: 'assets/images/manty.jpg',
      description: 'Буға пісірілетін шырынды тағам.',
      category: 'Екінші тағамдар',
      ingredients: ['Ұн', 'Су', 'Тұз', 'Ет фаршы', 'Пияз'],
      steps: [
        'Қамыр илеп, жұқалап жайыңыз.',
        'Фаршты дайындаңыз.',
        'Мантыны орап, буға пісіріңіз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Болоньезе пастасы',
      imageUrl: 'assets/images/boloneze.jpg',
      description: 'Томатты тұздықпен дайындалатын италиялық паста.',
      category: 'Екінші тағамдар',
      ingredients: ['Паста', 'Фарш', 'Томат соусы', 'Пияз', 'Сарымсақ'],
      steps: [
        'Пастаны қайнатып алыңыз.',
        'Фаршты пиязбен қуырып, томат соусын қосыңыз.',
        'Пастамен араластырып, дайын күйде ұсыныңыз.',
      ],
      videoUrl: VIDEO_URL,
    },

    // Десерттер (3)
    {
      title: 'Бауырсақ',
      imageUrl: 'assets/images/baursak.jpg',
      description: 'Майға қуырылған жұмсақ тәтті тағам.',
      category: 'Десерттер',
      ingredients: ['Ұн', 'Сүт', 'Ашытқы', 'Қант', 'Тұз', 'Май'],
      steps: [
        'Қамыр илеп, жылы жерге қойыңыз.',
        'Қамыр көтерілген соң, бөліктерге бөліңіз.',
        'Майда алтын түске дейін қуырыңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Құймақ',
      imageUrl: 'https://picsum.photos/seed/quymaq/600/400',
      description: 'Жұмсақ әрі тәтті құймақ.',
      category: 'Десерттер',
      ingredients: ['Ұн', 'Сүт', 'Жұмыртқа', 'Қант', 'Сары май'],
      steps: [
        'Қамырды араластырыңыз.',
        'Табаға май жағып, құймақ пісіріңіз.',
        'Бал немесе тосаппен бірге ұсыныңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Бал қосылған крем',
      imageUrl: 'assets/images/dessert.jpg',
      description: 'Жеңіл әрі нәзік тәтті крем.',
      category: 'Десерттер',
      ingredients: ['Кілегей', 'Бал', 'Ваниль', 'Жеміс'],
      steps: [
        'Кілегейді көпіртіңіз.',
        'Бал мен ванильді қосыңыз.',
        'Жемістермен безендіріңіз.',
      ],
      videoUrl: VIDEO_URL,
    },

    // Салаттар (3)
    {
      title: 'Грек салаты',
      imageUrl: 'assets/images/shrimp_pasta.jpg',
      description: 'Көкөніс пен ірімшіктен жасалған салат.',
      category: 'Салаттар',
      ingredients: ['Қызанақ', 'Қияр', 'Зәйтүн', 'Ірімшік', 'Зәйтүн майы'],
      steps: [
        'Көкөністерді тураңыз.',
        'Ірімшікті қосыңыз.',
        'Зәйтүн майымен араластырыңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Көкөніс салаты',
      imageUrl: 'assets/images/ceremony.jpg',
      description: 'Жеңіл әрі дәруменге бай салат.',
      category: 'Салаттар',
      ingredients: ['Қияр', 'Қызанақ', 'Қырыққабат', 'Жасыл пияз', 'Тұз'],
      steps: [
        'Көкөністерді тураңыз.',
        'Тұз қосып, араластырыңыз.',
        'Салқын күйде ұсыныңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Тауық салаты',
      imageUrl: 'assets/images/pasta.jpg',
      description: 'Тауық еті қосылған дәмді салат.',
      category: 'Салаттар',
      ingredients: ['Тауық еті', 'Қияр', 'Жүгері', 'Майонез', 'Тұз'],
      steps: [
        'Тауық етін пісіріп, тураңыз.',
        'Қалған ингредиенттермен араластырыңыз.',
        'Салқын күйде ұсыныңыз.',
      ],
      videoUrl: VIDEO_URL,
    },

    // Ұлттық тағамдар (3)
    {
      title: 'Бешбармақ',
      imageUrl: 'assets/images/national.jpg',
      description: 'Ұлттық ет тағамы.',
      category: 'Ұлттық',
      ingredients: ['Ет', 'Қамыр', 'Пияз', 'Тұз', 'Бұрыш'],
      steps: [
        'Етті қайнатып, сорпа жасаңыз.',
        'Қамыр жайып, пісіріңіз.',
        'Етпен бірге табаққа салыңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Қазы-қарта',
      imageUrl: 'https://picsum.photos/seed/qazy/600/400',
      description: 'Ұлттық шұжық түрі.',
      category: 'Ұлттық',
      ingredients: ['Жылқы еті', 'Ішек', 'Тұз', 'Дәмдеуіштер'],
      steps: [
        'Етті тұздап, ішекке салыңыз.',
        'Қайнату немесе қақтау арқылы дайындаңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
    {
      title: 'Құрт көже',
      imageUrl: 'https://picsum.photos/seed/qurt/600/400',
      description: 'Ұлттық сүт тағамынан жасалатын көже.',
      category: 'Ұлттық',
      ingredients: ['Құрт', 'Су', 'Тұз', 'Жасыл пияз'],
      steps: [
        'Құртты жылы суға езіңіз.',
        'Тұз қосып, қайнатыңыз.',
        'Жасыл пиязбен ұсыныңыз.',
      ],
      videoUrl: VIDEO_URL,
    },
  ]);

  console.log('--- Сидинг аяқталды ---');
  await mongoose.disconnect();
}

run().catch((err) => console.error(err));
