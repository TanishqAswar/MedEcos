const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  specialization: {
    type: String,
    required: true
  },
  qualifications: [{
    type: String
  }],
  experience: {
    type: Number,
    default: 0
  },
  licenseNumber: {
    type: String,
    required: true,
    unique: true
  },
  consultationFee: {
    type: Number,
    default: 0
  },
  availability: [{
    day: String,
    startTime: String,
    endTime: String
  }],
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  }
});

module.exports = mongoose.model('Doctor', doctorSchema);
