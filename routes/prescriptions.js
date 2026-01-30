const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const Prescription = require('../models/Prescription');

// Create prescription (doctors only)
router.post('/', auth, authorize('doctor'), async (req, res) => {
  try {
    const prescription = new Prescription(req.body);
    await prescription.save();
    res.status(201).json(prescription);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get prescriptions (filtered by user type)
router.get('/', auth, async (req, res) => {
  try {
    let query = {};
    if (req.user.userType === 'patient') {
      const Patient = require('../models/Patient');
      const patient = await Patient.findOne({ userId: req.userId });
      query.patient = patient._id;
    } else if (req.user.userType === 'doctor') {
      const Doctor = require('../models/Doctor');
      const doctor = await Doctor.findOne({ userId: req.userId });
      query.doctor = doctor._id;
    }

    const prescriptions = await Prescription.find(query)
      .populate({
        path: 'patient',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'doctor',
        populate: { path: 'userId', select: 'name email phone' }
      });
    res.json(prescriptions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get prescription by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const prescription = await Prescription.findById(req.params.id)
      .populate({
        path: 'patient',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'doctor',
        populate: { path: 'userId', select: 'name email phone' }
      });
    if (!prescription) {
      return res.status(404).json({ error: 'Prescription not found' });
    }
    res.json(prescription);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update prescription status
router.put('/:id', auth, authorize('doctor', 'pharmacist'), async (req, res) => {
  try {
    const prescription = await Prescription.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!prescription) {
      return res.status(404).json({ error: 'Prescription not found' });
    }
    res.json(prescription);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
