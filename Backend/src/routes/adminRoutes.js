const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { protect, authorize } = require('../middleware/authMiddleware');

// Get all practitioner verifications (Doctors, Pharmacists, Pathologists)
router.get('/verifications', protect, authorize('Admin'), async (req, res) => {
    try {
        const { status } = req.query; // e.g., 'pending', 'verified', 'rejected'
        const filter = {
            role: { $in: ['Doctor', 'Pharmacist', 'Pathologist'] }
        };

        if (status && status !== 'all') {
            if (status === 'pending') {
                filter.isVerified = false;
            } else if (status === 'verified') {
                filter.isVerified = true;
            } else if (status === 'rejected') {
                filter['humanVerification.status'] = 'rejected';
            }
        }

        const practitioners = await User.find(filter)
            .select('-password -privateKey -aadhaarNumber')
            .sort({ createdAt: -1 });

        res.json(practitioners);
    } catch (error) {
        console.error('Error fetching verification requests:', error);
        res.status(500).json({ message: 'Server error fetching verifications' });
    }
});

// Verify or Reject Practitioner (Human Admin verification holds more value and decides final isVerified)
router.post('/verify/:userId', protect, authorize('Admin'), async (req, res) => {
    try {
        const { userId } = req.params;
        const { status, notes } = req.body; // status: 'verified' | 'rejected'

        if (!['verified', 'rejected'].includes(status)) {
            return res.status(400).json({ message: 'Status must be either verified or rejected' });
        }

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        if (!['Doctor', 'Pharmacist', 'Pathologist'].includes(user.role)) {
            return res.status(400).json({ message: 'Only Doctor, Pharmacist, or Pathologist accounts require verification' });
        }

        user.humanVerification = {
            status: status,
            verifiedBy: req.user.username || req.user.email || 'Admin',
            notes: notes || (status === 'verified' ? 'Approved by Admin.' : 'Rejected by Admin.'),
            verifiedAt: new Date()
        };

        // Human verification holds more value: if verified by Admin -> isVerified = true, else false
        user.isVerified = (status === 'verified');

        await user.save();

        res.json({
            success: true,
            message: `Practitioner ${user.username} (${user.role}) has been ${status === 'verified' ? 'verified and approved' : 'rejected'}.`,
            user: {
                _id: user._id,
                username: user.username,
                email: user.email,
                role: user.role,
                isVerified: user.isVerified,
                aiVerification: user.aiVerification,
                humanVerification: user.humanVerification
            }
        });
    } catch (error) {
        console.error('Error updating verification status:', error);
        res.status(500).json({ message: 'Server error updating verification status' });
    }
});

// Admin system overview stats
router.get('/stats', protect, authorize('Admin'), async (req, res) => {
    try {
        const totalUsers = await User.countDocuments({});
        const totalPatients = await User.countDocuments({ role: 'Patient' });
        const totalDoctors = await User.countDocuments({ role: 'Doctor' });
        const totalPharmacists = await User.countDocuments({ role: 'Pharmacist' });
        const totalPathologists = await User.countDocuments({ role: 'Pathologist' });

        const pendingVerifications = await User.countDocuments({
            role: { $in: ['Doctor', 'Pharmacist', 'Pathologist'] },
            isVerified: false
        });

        const verifiedPractitioners = await User.countDocuments({
            role: { $in: ['Doctor', 'Pharmacist', 'Pathologist'] },
            isVerified: true
        });

        res.json({
            totalUsers,
            totalPatients,
            totalDoctors,
            totalPharmacists,
            totalPathologists,
            pendingVerifications,
            verifiedPractitioners
        });
    } catch (error) {
        console.error('Error fetching admin stats:', error);
        res.status(500).json({ message: 'Server error fetching stats' });
    }
});

module.exports = router;
