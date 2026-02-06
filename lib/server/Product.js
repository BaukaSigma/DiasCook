const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, index: true },
    description: { type: String, default: '' },
    imageUrl: { type: String, default: 'assets/images/soup.jpg' },
    category: { type: String, default: 'Екінші тағамдар' },
    ingredients: { type: [String], default: [] },
    steps: { type: [String], default: [] },
    videoUrl: { type: String, default: '' },

    // Legacy fields kept for compatibility with older data.
    sellerName: { type: String, default: '' },
    price: { type: Number, default: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', ProductSchema);
