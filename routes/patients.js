const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const Patient = require('../models/Patient');

// Get all patients (doctors only)
router.get('/', auth, authorize('doctor'), async (req, res) => {
  try {
    const patients = await Patient.find().populate('userId', 'name email phone address');
    res.json(patients);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get patient by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const patient = await Patient.findById(req.params.id).populate('userId', 'name email phone address');
    if (!patient) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    res.json(patient);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update patient profile
router.put('/:id', auth, authorize('patient'), async (req, res) => {
  try {
    const Patient = require('../models/Patient');
    const patientProfile = await Patient.findById(req.params.id);
    
    if (!patientProfile) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    
    // Ensure patient is updating their own profile
    if (patientProfile.userId.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Cannot update other patient profiles' });
    }
    
    const patient = await Patient.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    res.json(patient);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
