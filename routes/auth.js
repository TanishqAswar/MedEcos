const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Doctor = require('../models/Doctor');
const Patient = require('../models/Patient');
const Pharmacist = require('../models/Pharmacist');
const LabTester = require('../models/LabTester');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, userType, phone, address, additionalInfo } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Create user
    const user = new User({
      name,
      email,
      password,
      userType,
      phone,
      address
    });
    await user.save();

    // Create type-specific profile
    let profile;
    switch (userType) {
      case 'doctor':
        profile = new Doctor({
          userId: user._id,
          ...additionalInfo
        });
        break;
      case 'patient':
        profile = new Patient({
          userId: user._id,
          ...additionalInfo
        });
        break;
      case 'pharmacist':
        profile = new Pharmacist({
          userId: user._id,
          ...additionalInfo
        });
        break;
      case 'lab_tester':
        profile = new LabTester({
          userId: user._id,
          ...additionalInfo
        });
        break;
    }
    await profile.save();

    // Generate token
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d'
    });

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        userType: user.userType
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate token
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d'
    });

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        userType: user.userType
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
