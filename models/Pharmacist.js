const mongoose = require('mongoose');

const pharmacistSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  pharmacyName: {
    type: String,
    required: true
  },
  licenseNumber: {
    type: String,
    required: true,
    unique: true
  },
  pharmacyAddress: {
    type: String,
    required: true
  },
  operatingHours: {
    open: String,
    close: String
  },
  servicesOffered: [{
    type: String
  }],
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  }
});

module.exports = mongoose.model('Pharmacist', pharmacistSchema);
