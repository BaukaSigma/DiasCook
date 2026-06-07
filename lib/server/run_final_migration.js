const https = require('https');

const projectId = 'diplom-b929a';

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Complete, premium, professional Kazakh & Russian translation map for all 100 seeded dishes from TheMealDB
const translationMap = {
  "Bean & Sausage Hotpot": {
    ru: "Тушеная фасоль с колбасками",
    kz: "Бұршақ қосылған шұжық бұқтырмасы"
  },
  "Beef Asado": {
    ru: "Говядина Асадо",
    kz: "Асадо сиыр еті"
  },
  "Avocado dip with new potatoes": {
    ru: "Дип из авокадо с молодым картофелем",
    kz: "Жаңа картоп қосылған авокадо тұздығы"
  },
  "Apple cake": {
    ru: "Яблочный пирог",
    kz: "Алма бәліші"
  },
  "Blueberry & lemon friands": {
    ru: "Кексы с черникой и лимоном",
    kz: "Көкжидек және лимон кекстері"
  },
  "Cashew Ghoriba Biscuits": {
    ru: "Печенье «Гориба» с кешью",
    kz: "Кешью қосылған «Гориба» печеньесі"
  },
  "Brie wrapped in prosciutto & brioche": {
    ru: "Бри в прошутто и бриоши",
    kz: "Прошутто мен бриошқа оралған бри ірімшігі"
  },
  "Burek": {
    ru: "Бурек",
    kz: "Бөрек"
  },
  "Beetroot & red cabbage sauerkraut": {
    ru: "Квашеная красная капуста со свеклой",
    kz: "Қызылша қосылған қызыл қырыққабат тұздамасы"
  },
  "Arroz con gambas y calamar": {
    ru: "Рис с креветками и кальмарами",
    kz: "Асшаян және кальмар қосылған күріш"
  },
  "Alfajores": {
    ru: "Печенье Альфахорес",
    kz: "Альфахорес печеньесі"
  },
  "Boterkoek (Dutch Butter Cake)": {
    ru: "Голландский масляный пирог",
    kz: "Голландиялық майлы бәліш (Ботеркоек)"
  },
  "Braised stuffed cabbage": {
    ru: "Тушеные голубцы",
    kz: "Бұқтырылған голубцы"
  },
  "Anzac biscuits": {
    ru: "Печенье Анзак",
    kz: "Анзак печеньесі"
  },
  "Breakfast Potatoes": {
    ru: "Картофель на завтрак",
    kz: "Таңғы асқа арналған картоп"
  },
  "Beef Lo Mein": {
    ru: "Говядина Ло Мейн",
    kz: "Сиыр еті Ло Мейн"
  },
  "Carbonada Criolla": {
    ru: "Аргентинское рагу в тыкве (Карбонада)",
    kz: "Асқабақтағы аргентиналық рагу (Карбонада)"
  },
  "Algerian Bouzgene Berber Bread with Roasted Pepper Sauce": {
    ru: "Алжирский берберский хлеб с соусом из печеного перца",
    kz: "Қуырылған бұрыш соусы қосылған алжирлік бербер наны"
  },
  "Battenberg Cake": {
    ru: "Торт Баттенберг",
    kz: "Баттенберг торты"
  },
  "Ayam Percik": {
    ru: "Курица Аям Перчик",
    kz: "Аям перчик тауық еті"
  },
  "Bigos (Hunters Stew)": {
    ru: "Охотничий бигос",
    kz: "Бигос (аңшылар бұқтырмасы)"
  },
  "Boulangère Potatoes": {
    ru: "Картофель Буланжер",
    kz: "Буланжер картобы"
  },
  "Callaloo Jamaican Style": {
    ru: "Каллалу по-ямайски",
    kz: "Ямайкалық каллалу"
  },
  "Beetroot latkes": {
    ru: "Свекольные драники (латкес)",
    kz: "Қызылшадан жасалған латкес (драники)"
  },
  "Borsch": {
    ru: "Борщ",
    kz: "Борщ"
  },
  "Cajun spiced fish tacos": {
    ru: "Рыбные тако по-каджунски",
    kz: "Каджун дәмдеуіштері қосылған балық такосы"
  },
  "Beef Bourguignon": {
    ru: "Говядина по-бургундски",
    kz: "Бургундша сиыр еті"
  },
  "Apricot & Turkish delight mess": {
    ru: "Абрикосовый десерт с лукумом",
    kz: "Өрік пен рахат-лукум қосылған десерт"
  },
  "Barbecue pork buns": {
    ru: "Булочки со свининой барбекю",
    kz: "Барбекю шошқа еті қосылған тоқаштар"
  },
  "Baklava with spiced nuts, ricotta & chocolate": {
    ru: "Пахлава с пряными орехами, рикоттой и шоколадом",
    kz: "Жаңғақ, рикотта және шоколад қосылған пахлава"
  },
  "Aubergine couscous salad": {
    ru: "Салат из кускуса с баклажанами",
    kz: "Баклажан қосылған кускус салаты"
  },
  "Apple & Blackberry Crumble": {
    ru: "Яблочно-ежевичный крамбл",
    kz: "Алма мен қара бүлдірген крамблы"
  },
  "Beef Banh Mi Bowls with Sriracha Mayo, Carrot & Pickled Cucumber": {
    ru: "Боул Бань Ми с говядиной и соусом Шрирача",
    kz: "Шрирача майонезі, сәбіз және маринадталған қияр қосылған сиыр еті Бань Ми боулы"
  },
  "Brun Lapskaus (Norwegian Beef Vegetable Stew)": {
    ru: "Норвежское рагу из говядины с овощами",
    kz: "Брун лапскаус (норвегиялық сиыр еті мен көкөніс бұқтырмасы)"
  },
  "Blackberry Fool": {
    ru: "Ежевичный крем-десерт (Фул)",
    kz: "Ежевика мен кілегей десерті (Фул)"
  },
  "Bread omelette": {
    ru: "Хлебный омлет",
    kz: "Нан омлеті"
  },
  "Arepa pelua": {
    ru: "Венесуэльская арепа Пелуа",
    kz: "Арепа пелуа"
  },
  "Banana Pancakes": {
    ru: "Банановые оладьи",
    kz: "Банан құймақтары"
  },
  "Air fryer patatas bravas": {
    ru: "Картофель Пататас Бравас в аэрогриле",
    kz: "Аэрогрильдегі пататас бравас"
  },
  "Asado": {
    ru: "Аргентинское асадо",
    kz: "Асадо"
  },
  "Bistek": {
    ru: "Филиппинский бифштекс",
    kz: "Бифштекс (филиппин стиліндегі)"
  },
  "Bryndzové Halušky": {
    ru: "Словацкие галушки с брынзой",
    kz: "Брынза қосылған словак галушкиі"
  },
  "Algerian Carrots": {
    ru: "Морковь по-алжирски",
    kz: "Алжирлік сәбіз"
  },
  "Beef stroganoff": {
    ru: "Бефстроганов",
    kz: "Бефстроганов"
  },
  "Braised Beef Chilli": {
    ru: "Тушеная острая говядина с чили",
    kz: "Чили қосылған бұқтырылған ащы сиыр еті"
  },
  "Brown Stew Chicken": {
    ru: "Курица, тушенная по-карибски",
    kz: "Кариб стилінде бұқтырылған тауық еті"
  },
  "Caribbean Tamarind balls": {
    ru: "Карибские шарики из тамаринда",
    kz: "Кариб тамаринд шарлары"
  },
  "Air Fryer Egg Rolls": {
    ru: "Спринг-роллы в аэрогриле",
    kz: "Аэрогрильдегі жұмыртқа орамдары"
  },
  "Beef Empanadas": {
    ru: "Эмпанадас с говядиной",
    kz: "Сиыр еті қосылған эмпанада бәліштері"
  },
  "Broccoli & Stilton soup": {
    ru: "Крем-суп из брокколи и сыра Стилтон",
    kz: "Брокколи және Стилтон ірімшік сорпасы"
  },
  "Baingan Bharta": {
    ru: "Индйиское пюре из баклажанов (Байнган Бхарта)",
    kz: "Баклажан пюресі (Байнган Бхарта)"
  },
  "Bakewell tart": {
    ru: "Английский пирог Бэйкуэлл",
    kz: "Бэйквелл бәліші"
  },
  "Cabbage Soup (Shchi)": {
    ru: "Щи из капусты",
    kz: "Қырыққабат сорпасы (Щи)"
  },
  "Canadian Butter Tarts": {
    ru: "Канадские масляные тарталетки",
    kz: "Канадалық май тарталеткалары"
  },
  "Apam balik": {
    ru: "Малайзийские блинчики Апам Балик",
    kz: "Апам балик (малайзиялық құймақтар)"
  },
  "Beef Wellington": {
    ru: "Говядина Веллингтон",
    kz: "Веллингтон сиыр еті"
  },
  "Beef Sunday Roast": {
    ru: "Воскресное жаркое из говядины",
    kz: "Жексенбілік сиыр етінен қуырылған ет"
  },
  "Apple Potato Mash (Hete bliksem)": {
    ru: "Картофельно-яблочное пюре",
    kz: "Алма-картоп пюресі (Хете бликсем)"
  },
  "Apple Potato Mash (Hete bliksem) ": {
    ru: "Картофельно-яблочное пюре",
    kz: "Алма-картоп пюресі (Хете бликсем)"
  },
  "Aubergine & hummus grills": {
    ru: "Баклажаны гриль с хумусом",
    kz: "Хумус қосылған баклажан грилі"
  },
  "BBQ Pork Sloppy Joes": {
    ru: "Сэндвич «Неряха Джо» со свининой барбекю",
    kz: "Барбекю шошқа етінен жасалған «Неряха Джо» сэндвичі"
  },
  "Beetroot pancakes": {
    ru: "Свекольные блины",
    kz: "Қызылша құймақтары"
  },
  "Beef Dumpling Stew": {
    ru: "Говядина тушеная с клецками",
    kz: "Тұшпара қосылған бұқтырылған сиыр еті"
  },
  "Arnhemse meisjes": {
    ru: "Печенье «Арнемские девочки»",
    kz: "«Арнемдік қыздар» голландиялық печеньесі"
  },
  "Budino Di Ricotta": {
    ru: "Итальянский пудинг из рикотты",
    kz: "Рикотта қосылған итальян пудингі"
  },
  "Bitterballen (Dutch meatballs)": {
    ru: "Голландские фрикадельки (Биттербаллен)",
    kz: "Голландиялық ет шарлары (Биттерболлен)"
  },
  "BeaverTails": {
    ru: "Канадские пончики «Бобровые хвосты»",
    kz: "Канадалық «Бивертейлз» пончиктері"
  },
  "Beef and Oyster pie": {
    ru: "Пирог с говядиной и устрицами",
    kz: "Сиыр еті мен устрица бәліші"
  },
  "Bigos (Polish hunter's stew)": {
    ru: "Польский бигос",
    kz: "Поляк бигосы (аңшы бұқтырмасы)"
  },
  "Arepa Pabellón": {
    ru: "Венесуэльская арепа Пабельон",
    kz: "Арепа Пабеллон"
  },
  "Authentic Norwegian Kransekake": {
    ru: "Норвежский праздничный торт",
    kz: "Дәстүрлі норвегиялық Крансекаке торты"
  },
  "Callaloo and SaltFish": {
    ru: "Каллалу с соленой рыбой",
    kz: "Каллало және тұздалған балық"
  },
  "Cassava pizza": {
    ru: "Пицца из маниоки",
    kz: "Маниоктан жасалған пицца"
  },
  "Bang bang prawn salad": {
    ru: "Салат с креветками Банг-Банг",
    kz: "Банг-Банг асшаян салаты"
  },
  "Beef pho": {
    ru: "Вьетнамский суп Фо с говядиной",
    kz: "Сиыр етінен жасалған вьетнамдық Фо сорпасы"
  },
  "Bread and Butter Pudding": {
    ru: "Английский хлебный пудинг с маслом",
    kz: "Нан мен сары май пудингі"
  },
  "Big Mac": {
    ru: "Биг Мак",
    kz: "Биг Мак"
  },
  "Algerian Kefta (Meatballs)": {
    ru: "Алжирская кефта (фрикадельки)",
    kz: "Алжирлік кефта (фрикаделькалар)"
  },
  "Chakchouka": {
    ru: "Шакшука",
    kz: "Шакшука"
  },
  "Chakchouka ": {
    ru: "Шакшука",
    kz: "Шакшука"
  },
  "Beef Brisket Pot Roast": {
    ru: "Запеченная говяжья грудинка",
    kz: "Пеште пісірілген сиыр еті"
  },
  "Carrot Cake": {
    ru: "Морковный торт",
    kz: "Сәбіз торты"
  },
  "Cevapi Sausages": {
    ru: "Балканские колбаски Чевапи",
    kz: "Чевапи балкан шұжықтары"
  },
  "Beef Caldereta": {
    ru: "Филиппинское рагу из говядины (Кальдерета)",
    kz: "Сиыр еті кальдеретасы"
  },
  "Baked salmon with fennel & tomatoes": {
    ru: "Запеченный лосось с фенхелем и помидорами",
    kz: "Фенхель және қызанақ қосылған пісірілген лосось"
  },
  "Baba Ghanoush": {
    ru: "Бабагануш (паста из баклажанов)",
    kz: "Бабагануш (баклажан пастасы)"
  },
  "Apple Frangipan Tart": {
    ru: "Яблочный тарт с франжипаном",
    kz: "Франжипан қосылған алма тарты"
  },
  "Blini Pancakes": {
    ru: "Русские блины",
    kz: "Құймақтар"
  },
  "Beef and Mustard Pie": {
    ru: "Пирог с говядиной и горчицей",
    kz: "Сиыр еті мен қыша бәліші"
  },
  "Adana kebab": {
    ru: "Турецкий Адана-кебаб",
    kz: "Адана кебабы"
  },
  "Ajo blanco": {
    ru: "Холодный суп Ахо Бланко",
    kz: "Ахо бланко суық сорпасы"
  },
  "Beef Mandi": {
    ru: "Йеменский плов с говядиной Манди",
    kz: "Манди сиыр еті"
  },
  "Beef Rendang": {
    ru: "Индонезийский ренданг из говядины",
    kz: "Ренданг сиыр еті"
  },
  "Beetroot Soup (Borscht)": {
    ru: "Борщ свекольный",
    kz: "Қызылша сорпасы (борщ)"
  },
  "Cacik": {
    ru: "Турецкий соус Джаджик",
    kz: "Джаджик соусы"
  },
  "Arroz al horno (baked rice)": {
    ru: "Испанский запеченный рис (Арроз аль хорно)",
    kz: "Пеште пісірілген испан күріші (Арроз аль хорно)"
  },
  "Beef Mechado": {
    ru: "Мечадо из говядины",
    kz: "Мечадо сиыр еті"
  },
  "Aussie Burgers": {
    ru: "Австралийские бургеры",
    kz: "Австралиялық бургерлер"
  },
  "Barramundi with Moroccan spices": {
    ru: "Рыба баррамунди с марокканскими специями",
    kz: "Марокко дәмдеуіштері қосылған баррамунди"
  },
  "Beef and Broccoli Stir-Fry": {
    ru: "Говядина с брокколи стир-фрай",
    kz: "Брокколи қосылған қуырылған сиыр еті"
  },
  "Algerian Flafla (Bell Pepper Salad)": {
    ru: "Алжирский салат из сладкого перца Флафла",
    kz: "Флафла (алжирлік тәтті бұрыш салаты)"
  },
  "Boxty Breakfast": {
    ru: "Ирландский завтрак Боксти",
    kz: "Боксти таңғы асы"
  }
};

function replaceKzWords(text) {
  if (!text) return '';
  let res = text;
  
  // Replace cheese terms
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сырлары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшіктері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сырлар([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшіктер$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сыры([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшігі$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])сыр([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1ірімшік$2');
  
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сырлары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшіктері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сырлар([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшіктер$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сыры([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшігі$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Сыр([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Ірімшік$2');

  // Replace pie terms
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])пирогтары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1бәліштері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])пирогы([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1бәліші$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])пирог([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1бәліш$2');
  
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Пирогтары([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Бәліштері$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Пирогы([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Бәліші$2');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])Пирог([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1Бәліш$2');

  // Replace machine-translation terms
  res = res.replace(/ыстық ыдыс/gi, 'бұқтырма');
  res = res.replace(/ыстық ыдысты/gi, 'бұқтырманы');
  res = res.replace(/ыстық ыдысқа/gi, 'бұқтырмаға');
  res = res.replace(/ыстық ыдыстың/gi, 'бұқтырманың');
  
  res = res.replace(/батырыңыз/gi, 'тұздық соусы');
  res = res.replace(/батыру соусы/gi, 'тұздық соусы');
  res = res.replace(/батыруға арналған/gi, 'тұздыққа арналған');
  res = res.replace(/(^|[^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ])батыру([^а-яА-ЯёЁӘәІіҢңҒғҮүҰұҚқӨөҺһ]|$)/g, '$1тұздық$2');
  
  res = res.replace(/киіну/gi, 'тұздық');
  res = res.replace(/киімі/gi, 'тұздығы');
  res = res.replace(/салат киімі/gi, 'салат соусы');
  
  res = res.replace(/грави/gi, 'тұздық');
  res = res.replace(/грейви/gi, 'тұздық');
  res = res.replace(/кастрөл/gi, 'бұқтырма');
  res = res.replace(/үгінді/gi, 'десерт');

  return res;
}

function fetchAllProducts() {
  return new Promise((resolve, reject) => {
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products?pageSize=150`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const json = JSON.parse(data);
            resolve(json.documents || []);
          } catch (e) {
            reject(e);
          }
        } else {
          reject(new Error(`Firestore returned status ${res.statusCode}. Body: ${data}`));
        }
      });
    }).on('error', reject);
  });
}

function updateProduct(productId, updates) {
  return new Promise((resolve, reject) => {
    const fields = {};
    const fieldPaths = [];
    
    for (const [key, val] of Object.entries(updates)) {
      fieldPaths.push(`updateMask.fieldPaths=${key}`);
      if (typeof val === 'string') {
        fields[key] = { stringValue: val };
      } else if (typeof val === 'boolean') {
        fields[key] = { booleanValue: val };
      } else if (Array.isArray(val)) {
        fields[key] = {
          arrayValue: {
            values: val.map(item => ({ stringValue: item.toString() }))
          }
        };
      }
    }
    
    const queryParams = fieldPaths.join('&');
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/products/${productId}?${queryParams}`;
    
    const requestData = JSON.stringify({ fields });
    
    const req = https.request(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestData)
      }
    }, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(responseBody));
        } else {
          reject(new Error(`Failed to update ${productId}. Status: ${res.statusCode}. Body: ${responseBody}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(requestData);
    req.end();
  });
}

// Helper to extract values
function getVal(field) {
  if (!field) return null;
  if (field.stringValue !== undefined) return field.stringValue;
  if (field.arrayValue && field.arrayValue.values) {
    return field.arrayValue.values.map(v => v.stringValue || '');
  }
  return null;
}

async function run() {
  console.log('Fetching all products from Firestore...');
  const docs = await fetchAllProducts();
  console.log(`Found ${docs.length} products total.`);

  let updatedCount = 0;
  
  for (const doc of docs) {
    const id = doc.name.split('/').pop();
    const f = doc.fields;
    
    const titleEnRaw = getVal(f.titleEn) || '';
    const titleEn = titleEnRaw.trim();
    
    if (!titleEn) {
      console.log(`Skipping non-seeded/custom product: ${id}`);
      continue;
    }
    
    const trans = translationMap[titleEn];
    if (!trans) {
      console.log(`No translation mapped for: "${titleEn}" (ID: ${id})`);
      continue;
    }
    
    const titleRu = trans.ru;
    const titleKz = trans.kz;
    
    const descriptionRu = `Вкусное традиционное блюдо "${titleRu}", приготовленное из свежих ингредиентов по классическому рецепту.`;
    const descriptionKz = `Классикалық рецепт бойынша жаңа піскен ингредиенттерден дайындалған дәмді "${titleKz}" дәстүрлі тағамы.`;
    
    // Get ingredients and steps lists
    const ingredientsKz = getVal(f.ingredientsKz) || [];
    const stepsKz = getVal(f.stepsKz) || [];
    
    // Clean ingredients and steps in Kazakh
    const cleanedIngredientsKz = ingredientsKz.map(item => replaceKzWords(item));
    const cleanedStepsKz = stepsKz.map(item => replaceKzWords(item));
    
    const updates = {
      title: titleRu,
      titleRu: titleRu,
      titleKz: titleKz,
      description: descriptionRu,
      descriptionRu: descriptionRu,
      descriptionKz: descriptionKz,
      ingredientsKz: cleanedIngredientsKz,
      stepsKz: cleanedStepsKz,
      isTranslatedByAI: true
    };
    
    try {
      await updateProduct(id, updates);
      console.log(`Updated [${id}] -> "${titleKz}" / "${titleRu}"`);
      updatedCount++;
      await sleep(100); // Small delay
    } catch (err) {
      console.error(`Error updating [${id}]:`, err.message);
    }
  }
  
  console.log(`\nSuccessfully updated ${updatedCount} products in Firestore!`);
}

run().catch(console.error);
