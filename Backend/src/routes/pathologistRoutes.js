const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');
const User = require('../models/User');
const LabTestOrder = require('../models/LabTestOrder');
const multer = require('multer');
const { uploadToCloudinary, deleteFromCloudinaryByUrl } = require('../utils/cloudinary');

const upload = multer({ storage: multer.memoryStorage() });

// Get Lab Tests for a Patient (Lookup by ABHA ID)
router.get('/patients/:abhaId/lab-tests', protect, authorize('Pathologist'), async (req, res) => {
    try {
        const { abhaId } = req.params;
        
        // Find patient
        const patient = await User.findOne({ abhaId, role: 'Patient' });
        if (!patient) {
            return res.status(404).json({ message: 'Patient not found' });
        }

        // Find prescriptions for this patient that contain lab tests
        const prescriptions = await Prescription.find({ 
            abhaId, 
            labTests: { $exists: true, $not: { $size: 0 } }
        }).sort({ date: -1 });

        // Fetch existing orders to merge status
        const existingOrders = await LabTestOrder.find({ patientId: patient._id });

        // Extract and format the lab tests
        const testsToPerform = [];
        prescriptions.forEach(p => {
            if (p.labTests && p.labTests.length > 0) {
                p.labTests.forEach(test => {
                    // Find if there's an existing order for this exact test from this prescription
                    const order = existingOrders.find(o => 
                        o.testName === test && 
                        o.prescriptionId?.toString() === p._id.toString()
                    );
                    
                    testsToPerform.push({
                        testName: test,
                        prescriptionId: p._id,
                        doctorName: p.doctorName,
                        datePrescribed: p.date,
                        diagnosis: p.diagnosis,
                        status: order ? order.status : 'Pending',
                        orderId: order ? order._id : null
                    });
                });
            }
        });

        res.json({
            patient: {
                name: patient.username,
                abhaId: patient.abhaId,
                age: patient.age,
                gender: patient.gender,
            },
            tests: testsToPerform
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Process a Lab Test (Create or Update LabTestOrder to In_Progress)
router.post('/patients/:abhaId/process-test', protect, authorize('Pathologist'), async (req, res) => {
    try {
        const { abhaId } = req.params;
        const { testName, prescriptionId } = req.body;
        
        if (!testName || !prescriptionId) {
            return res.status(400).json({ message: 'testName and prescriptionId are required' });
        }

        const patient = await User.findOne({ abhaId, role: 'Patient' });
        if (!patient) {
            return res.status(404).json({ message: 'Patient not found' });
        }

        // Check if order already exists
        let order = await LabTestOrder.findOne({
            patientId: patient._id,
            prescriptionId,
            testName
        });

        if (order) {
            if (order.status === 'Completed') {
                return res.status(400).json({ message: 'Test already completed' });
            }
            order.status = 'In_Progress';
            order.pathologistId = req.user._id; // Take ownership
            await order.save();
        } else {
            order = await LabTestOrder.create({
                patientId: patient._id,
                patientName: patient.username || 'Unknown Patient',
                pathologistId: req.user._id,
                testName,
                prescriptionId,
                status: 'In_Progress'
            });
        }

        // Check if the pathologist already provides this test, if not, add it
        const pathologist = await User.findById(req.user._id);
        if (pathologist && !pathologist.labTestsProvided.includes(testName)) {
            pathologist.labTestsProvided.push(testName);
            await pathologist.save();
        }

        res.json(order);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Lab Test Orders for this Pathologist
router.get('/orders', protect, authorize('Pathologist'), async (req, res) => {
    try {
        const orders = await LabTestOrder.find({ pathologistId: req.user._id }).sort({ createdAt: -1 });
        res.json(orders);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update Lab Test Order Status
router.put('/orders/:id/status', protect, authorize('Pathologist'), upload.single('reportFile'), async (req, res) => {
    try {
        const { status } = req.body;
        if (!['Pending', 'In_Progress', 'Completed'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        const existingOrder = await LabTestOrder.findOne({ _id: req.params.id, pathologistId: req.user._id });
        if (!existingOrder) return res.status(404).json({ message: 'Order not found' });

        const updateData = { status };
        if (status === 'Completed') {
            updateData.dateCompleted = Date.now();
            
            // Check if a file was uploaded via multer
            if (req.file) {
                try {
                    // If an old report exists, delete it first
                    if (existingOrder.reportPdf) {
                        await deleteFromCloudinaryByUrl(existingOrder.reportPdf);
                    }
                    const fileUrl = await uploadToCloudinary(req.file.buffer, req.file.originalname);
                    updateData.reportPdf = fileUrl;
                } catch (uploadError) {
                    console.error('Cloudinary Upload Error:', uploadError);
                    return res.status(500).json({ message: 'Failed to upload report to cloud storage' });
                }
            } 
            // Fallback for legacy base64 or URL passed in body
            else if (req.body.reportPdf) {
                if (existingOrder.reportPdf && existingOrder.reportPdf !== req.body.reportPdf) {
                    await deleteFromCloudinaryByUrl(existingOrder.reportPdf);
                }
                updateData.reportPdf = req.body.reportPdf;
            }
        }

        const order = await LabTestOrder.findOneAndUpdate(
            { _id: req.params.id, pathologistId: req.user._id },
            updateData,
            { new: true }
        );

        if (!order) return res.status(404).json({ message: 'Order not found' });

        res.json(order);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Pathologist Dashboard Stats
router.get('/dashboard-stats', protect, authorize('Pathologist'), async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const appointmentsToday = await LabTestOrder.countDocuments({
            pathologistId: req.user._id,
            createdAt: { $gte: today, $lt: tomorrow }
        });

        const pendingOrders = await LabTestOrder.countDocuments({
            pathologistId: req.user._id,
            status: { $in: ['Pending', 'In_Progress'] }
        });

        const uniquePatients = await LabTestOrder.distinct('patientId', { pathologistId: req.user._id });
        const totalPatients = uniquePatients.length;

        res.json({
            appointmentsToday,
            pendingOrders,
            totalPatients
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
