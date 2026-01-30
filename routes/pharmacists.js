const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const Pharmacist = require('../models/Pharmacist');

// Get all pharmacists
router.get('/', auth, async (req, res) => {
  try {
    const pharmacists = await Pharmacist.find().populate('userId', 'name email phone address');
    res.json(pharmacists);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get pharmacist by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const pharmacist = await Pharmacist.findById(req.params.id).populate('userId', 'name email phone address');
    if (!pharmacist) {
      return res.status(404).json({ error: 'Pharmacist not found' });
    }
    res.json(pharmacist);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update pharmacist profile
router.put('/:id', auth, authorize('pharmacist'), async (req, res) => {
  try {
    const pharmacist = await Pharmacist.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!pharmacist) {
      return res.status(404).json({ error: 'Pharmacist not found' });
    }
    res.json(pharmacist);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
