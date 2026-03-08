const mongoose = require('mongoose');

const labTesterSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  labName: {
    type: String,
    required: true
  },
  licenseNumber: {
    type: String,
    required: true,
    unique: true
  },
  labAddress: {
    type: String,
    required: true
  },
  testsAvailable: [{
    testName: String,
    testCode: String,
    price: Number,
    duration: String
  }],
  operatingHours: {
    open: String,
    close: String
  },
  accreditations: [{
    type: String
  }],
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  }
});

module.exports = mongoose.model('LabTester', labTesterSchema);
