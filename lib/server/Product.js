const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, index: true },
    sellerName: { type: String, required: true }, 
    price: { type: Number, required: true },     
    imageUrl: { type: String, default: 'assets/images/default.jpg' },
    description: { type: String, default: '' },  
    category: { type: String, default: 'Екінші тағамдар' }, 
    ingredients: { type: [String], default: [] }, 
    steps: { type: [String], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', ProductSchema);