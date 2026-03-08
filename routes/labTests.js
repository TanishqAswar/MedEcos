const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const LabTest = require('../models/LabTest');

// Create lab test
router.post('/', auth, authorize('doctor', 'patient'), async (req, res) => {
  try {
    const labTest = new LabTest(req.body);
    await labTest.save();
    res.status(201).json(labTest);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get lab tests (filtered by user type)
router.get('/', auth, async (req, res) => {
  try {
    let query = {};
    if (req.user.userType === 'patient') {
      const Patient = require('../models/Patient');
      const patient = await Patient.findOne({ userId: req.userId });
      if (!patient) {
        return res.status(404).json({ error: 'Patient profile not found' });
      }
      query.patient = patient._id;
    } else if (req.user.userType === 'doctor') {
      const Doctor = require('../models/Doctor');
      const doctor = await Doctor.findOne({ userId: req.userId });
      if (!doctor) {
        return res.status(404).json({ error: 'Doctor profile not found' });
      }
      query.doctor = doctor._id;
    } else if (req.user.userType === 'lab_tester') {
      const LabTester = require('../models/LabTester');
      const labTester = await LabTester.findOne({ userId: req.userId });
      if (!labTester) {
        return res.status(404).json({ error: 'Lab tester profile not found' });
      }
      query.labTester = labTester._id;
    }

    const labTests = await LabTest.find(query)
      .populate({
        path: 'patient',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'doctor',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'labTester',
        populate: { path: 'userId', select: 'name email phone' }
      });
    res.json(labTests);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get lab test by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const labTest = await LabTest.findById(req.params.id)
      .populate({
        path: 'patient',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'doctor',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'labTester',
        populate: { path: 'userId', select: 'name email phone' }
      });
    if (!labTest) {
      return res.status(404).json({ error: 'Lab test not found' });
    }
    res.json(labTest);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update lab test (status and results)
router.put('/:id', auth, authorize('lab_tester'), async (req, res) => {
  try {
    const LabTester = require('../models/LabTester');
    const labTester = await LabTester.findOne({ userId: req.userId });
    
    if (!labTester) {
      return res.status(404).json({ error: 'Lab tester profile not found' });
    }
    
    const labTest = await LabTest.findById(req.params.id);
    if (!labTest) {
      return res.status(404).json({ error: 'Lab test not found' });
    }
    
    // Ensure lab tester is updating tests assigned to them
    if (labTest.labTester.toString() !== labTester._id.toString()) {
      return res.status(403).json({ error: 'Cannot update tests of other labs' });
    }
    
    const updatedLabTest = await LabTest.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    res.json(updatedLabTest);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
