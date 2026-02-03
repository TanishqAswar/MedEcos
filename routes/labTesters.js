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
    const LabTester = require('../models/LabTester');
    const labTesterProfile = await LabTester.findById(req.params.id);
    
    if (!labTesterProfile) {
      return res.status(404).json({ error: 'Lab tester not found' });
    }
    
    // Ensure lab tester is updating their own profile
    if (labTesterProfile.userId.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Cannot update other lab tester profiles' });
    }
    
    const labTester = await LabTester.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    res.json(labTester);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
