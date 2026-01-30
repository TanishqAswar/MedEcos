const mongoose = require('mongoose');

const labTestSchema = new mongoose.Schema({
  patient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  doctor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor'
  },
  labTester: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LabTester',
    required: true
  },
  testName: {
    type: String,
    required: true
  },
  testCode: String,
  scheduledDate: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: ['scheduled', 'sample-collected', 'in-progress', 'completed', 'cancelled'],
    default: 'scheduled'
  },
  results: {
    findings: String,
    reportUrl: String,
    completedDate: Date
  },
  price: Number,
  notes: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('LabTest', labTestSchema);
