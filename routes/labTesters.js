const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const LabTester = require('../models/LabTester');

// Get all lab testers
router.get('/', auth, async (req, res) => {
  try {
    const labTesters = await LabTester.find().populate('userId', 'name email phone address');
    res.json(labTesters);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get lab tester by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const labTester = await LabTester.findById(req.params.id).populate('userId', 'name email phone address');
    if (!labTester) {
      return res.status(404).json({ error: 'Lab tester not found' });
    }
    res.json(labTester);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update lab tester profile
router.put('/:id', auth, authorize('lab_tester'), async (req, res) => {
  try {
    const labTester = await LabTester.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!labTester) {
      return res.status(404).json({ error: 'Lab tester not found' });
    }
    res.json(labTester);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
