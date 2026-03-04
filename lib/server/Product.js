const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, index: true },
    description: { type: String, default: '' },
    descriptionRu: { type: String, default: '' },
    ingredientsRu: { type: [String], default: [] },
    stepsRu: { type: [String], default: [] },
    imageUrl: { type: String, default: 'assets/images/soup.jpg' },
    category: { type: String, default: 'Басқа' },
    price: { type: Number, default: 0 },
    condition: { type: String, default: 'Жаңа' }, // Жаңа (New) немесе Қолданылған (Used)
    location: { type: String, default: 'Алматы' },
    sellerId: { type: String, default: 'admin' },
    sellerName: { type: String, default: '' },
    sellerLogo: { type: String, default: '' },
    ingredients: { type: [String], default: [] },
    steps: { type: [String], default: [] },
    videoUrl: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', ProductSchema);
