const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const Appointment = require('../models/Appointment');

// Create appointment
router.post('/', auth, authorize('patient'), async (req, res) => {
  try {
    const appointment = new Appointment(req.body);
    await appointment.save();
    res.status(201).json(appointment);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all appointments (filtered by user type)
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

    const appointments = await Appointment.find(query)
      .populate({
        path: 'patient',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'doctor',
        populate: { path: 'userId', select: 'name email phone' }
      });
    res.json(appointments);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update appointment status
router.put('/:id', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }
    res.json(appointment);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete appointment
router.delete('/:id', auth, authorize('patient'), async (req, res) => {
  try {
    const appointment = await Appointment.findByIdAndDelete(req.params.id);
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }
    res.json({ message: 'Appointment cancelled' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
