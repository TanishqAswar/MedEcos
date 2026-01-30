const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const PharmacyOrder = require('../models/PharmacyOrder');

// Create pharmacy order
router.post('/', auth, authorize('patient'), async (req, res) => {
  try {
    const Patient = require('../models/Patient');
    const patient = await Patient.findOne({ userId: req.userId });
    
    if (!patient) {
      return res.status(404).json({ error: 'Patient profile not found' });
    }
    
    // Ensure patient is creating order for themselves
    if (req.body.patient && req.body.patient !== patient._id.toString()) {
      return res.status(403).json({ error: 'Cannot create orders for other patients' });
    }
    
    req.body.patient = patient._id;
    const order = new PharmacyOrder(req.body);
    await order.save();
    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get pharmacy orders (filtered by user type)
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
    } else if (req.user.userType === 'pharmacist') {
      const Pharmacist = require('../models/Pharmacist');
      const pharmacist = await Pharmacist.findOne({ userId: req.userId });
      if (!pharmacist) {
        return res.status(404).json({ error: 'Pharmacist profile not found' });
      }
      query.pharmacist = pharmacist._id;
    }

    const orders = await PharmacyOrder.find(query)
      .populate({
        path: 'patient',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'pharmacist',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate('prescription');
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get pharmacy order by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const order = await PharmacyOrder.findById(req.params.id)
      .populate({
        path: 'patient',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate({
        path: 'pharmacist',
        populate: { path: 'userId', select: 'name email phone' }
      })
      .populate('prescription');
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update order status
router.put('/:id', auth, authorize('pharmacist'), async (req, res) => {
  try {
    const Pharmacist = require('../models/Pharmacist');
    const pharmacist = await Pharmacist.findOne({ userId: req.userId });
    
    if (!pharmacist) {
      return res.status(404).json({ error: 'Pharmacist profile not found' });
    }
    
    const order = await PharmacyOrder.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    // Ensure pharmacist is updating orders assigned to them
    if (order.pharmacist.toString() !== pharmacist._id.toString()) {
      return res.status(403).json({ error: 'Cannot update orders of other pharmacies' });
    }
    
    const updatedOrder = await PharmacyOrder.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    res.json(updatedOrder);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
