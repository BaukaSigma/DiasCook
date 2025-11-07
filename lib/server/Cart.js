// Cart.js
const mongoose = require('mongoose');

const CartSchema = new mongoose.Schema(
  {
    userId: { 
      type: String, 
      required: true,
    },
    productId: { 
      type: mongoose.Schema.Types.ObjectId, 
      required: true,
      ref: 'Product', 
    },
    quantity: { 
        type: Number, 
        required: true, 
        default: 1, 
        min: 1 
    },
  },
  { timestamps: true }
);

// Әр пайдаланушы бір тауарды себетке тек бір рет қоса алатынын қамтамасыз етеді
CartSchema.index({ userId: 1, productId: 1 }, { unique: true });

module.exports = mongoose.model('Cart', CartSchema);