const mongoose = require('mongoose');

const FavoriteSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true },
    productId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'Product', 
      required: true 
    },
  },
  { timestamps: true }
);

// Бір қолданушы бір тауарға тек бір рет лайк баса алады
FavoriteSchema.index({ userId: 1, productId: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', FavoriteSchema);