const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    surname: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    password: { type: String, required: true, select: false },
    phone: { type: String, required: true },
    userId: { type: String, unique: true },
    isAdmin: { type: Boolean, default: false },
    deliveryAddress: { type: String, default: '' },
  },
  { timestamps: true }
);

UserSchema.pre('save', function (next) {
  if (!this.userId) {
    this.userId = this._id.toString();
  }
  next();
});

module.exports = mongoose.model('User', UserSchema);
