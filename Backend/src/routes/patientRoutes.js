const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');
const MedicineHistory = require('../models/MedicineHistory');
const Appointment = require('../models/Appointment');
const User = require('../models/User');
const LabTestOrder = require('../models/LabTestOrder');
const multer = require('multer');
const { uploadToCloudinary } = require('../utils/cloudinary');

const upload = multer({ storage: multer.memoryStorage() });

// Get My Medical History (Prescriptions)
router.get('/prescriptions', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }

        const prescriptions = await Prescription.find({ abhaId }).sort({ date: -1 });

        // Transform to MedicalHistory format if needed, or just return list
        const medicalHistory = {
            abhaId: abhaId,
            records: prescriptions.map(p => ({
                prescriptionId: p._id,
                doctorName: p.doctorName,
                date: p.date,
                diagnosis: p.diagnosis,
                medicines: p.medicines.map(m => m.name), // Simplifying for view
                fullMedicines: p.medicines // Providing full details too
            }))
        };

        res.json(medicalHistory);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Profile
router.get('/profile', protect, authorize('Patient'), async (req, res) => {
    res.json(req.user);
});

// Update Profile (Routine Settings & Custom Reminder Medicines)
router.put('/profile', protect, authorize('Patient'), async (req, res) => {
    try {
        const { routine, customMedicines, deletedReminders } = req.body;
        if (routine) req.user.routine = routine;
        if (customMedicines !== undefined) req.user.customMedicines = customMedicines;
        if (deletedReminders !== undefined) req.user.deletedReminders = deletedReminders;
        await req.user.save();
        res.json(req.user);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Add Custom Reminder Medicine
router.post('/medicines', protect, authorize('Patient'), async (req, res) => {
    try {
        const { name, timing, context, instruction, dosage, durationDays, startDate } = req.body;
        if (!name) return res.status(400).json({ message: 'Medicine name is required' });
        
        const medId = `custom_${Date.now()}`;
        const newMed = {
            id: medId,
            name: name.trim(),
            timing: timing || 'Morning',
            context: context || 'After Food',
            instruction: instruction || '1 Unit',
            dosage: dosage || '1 Unit',
            durationDays: Number(durationDays) || 0,
            startDate: startDate ? new Date(startDate) : new Date()
        };
        
        req.user.customMedicines = req.user.customMedicines || [];
        req.user.customMedicines.push(newMed);
        
        // Remove from deletedReminders if present
        if (req.user.deletedReminders) {
            req.user.deletedReminders = req.user.deletedReminders.filter(
                d => d.toLowerCase() !== name.trim().toLowerCase() && d !== medId
            );
        }
        
        await req.user.save();
        res.status(201).json(req.user.customMedicines);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Delete Reminder Medicine
router.delete('/medicines/:id', protect, authorize('Patient'), async (req, res) => {
    try {
        const medId = req.params.id;
        const medName = req.query.name;
        
        req.user.customMedicines = (req.user.customMedicines || []).filter(m => m.id !== medId && m.name.toLowerCase() !== (medName || '').toLowerCase());
        req.user.deletedReminders = req.user.deletedReminders || [];
        if (!req.user.deletedReminders.includes(medId)) {
            req.user.deletedReminders.push(medId);
        }
        if (medName && !req.user.deletedReminders.includes(medName.toLowerCase().trim())) {
            req.user.deletedReminders.push(medName.toLowerCase().trim());
        }
        await req.user.save();
        res.json({ message: 'Medicine reminder removed successfully', customMedicines: req.user.customMedicines, deletedReminders: req.user.deletedReminders });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Upload Prescription Image or PDF to Cloudinary
router.post('/prescriptions/upload', protect, authorize('Patient'), upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }
        const secureUrl = await uploadToCloudinary(req.file.buffer, req.file.originalname);
        res.json({ secure_url: secureUrl });
    } catch (error) {
        console.error('Cloudinary upload error:', error);
        res.status(500).json({ message: 'Failed to upload prescription file to cloud' });
    }
});

// Save Scanned Prescription with Reviewed OCR Medicines
router.post('/prescriptions/scanned', protect, authorize('Patient'), async (req, res) => {
    try {
        const { attachmentUrl, doctorName, diagnosis, medicines } = req.body;
        const abhaId = req.user.abhaId || req.user._id.toString();

        const prescription = await Prescription.create({
            abhaId,
            doctorId: req.user._id,
            doctorName: doctorName || 'Scanned Prescription',
            diagnosis: diagnosis || 'Patient Uploaded Prescription',
            patientName: req.user.name,
            attachmentUrl: attachmentUrl || null,
            source: 'Scanned',
            medicines: Array.isArray(medicines) ? medicines : []
        });

        // Sync verified scanned medicines into user's customMedicines reminders
        if (Array.isArray(medicines)) {
            req.user.customMedicines = req.user.customMedicines || [];
            for (const med of medicines) {
                if (med.name) {
                    req.user.customMedicines.push({
                        id: `scanned_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
                        name: med.name.trim(),
                        timing: med.timing || 'Morning, Night',
                        context: med.context || 'After Food',
                        instruction: med.instruction || 'Scanned prescription dose',
                        dosage: med.dosage || '1 Unit',
                        durationDays: Number(med.durationDays) || 0,
                        startDate: new Date()
                    });
                }
            }
            await req.user.save();
        }

        res.status(201).json({ message: 'Scanned prescription saved and reminders created successfully', prescription });
    } catch (error) {
        console.error('Error saving scanned prescription:', error);
        res.status(500).json({ message: 'Server error saving scanned prescription' });
    }
});

// Get Dashboard Stats
router.get('/dashboard-stats', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }
        
        const prescriptions = await Prescription.find({ abhaId });
        
        // Calculate active medicines (unique medicines across all prescriptions)
        const uniqueMedicines = new Set();
        prescriptions.forEach(p => {
            if (p.medicines && Array.isArray(p.medicines)) {
                p.medicines.forEach(m => {
                    if (m.name) uniqueMedicines.add(m.name.toLowerCase().trim());
                });
            }
        });

        res.json({
            activeMedicines: uniqueMedicines.size,
            totalPrescriptions: prescriptions.length
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Log Medicine Taken
router.post('/history', protect, authorize('Patient'), async (req, res) => {
    try {
        const { medicineId, medicineName, takenTime, status } = req.body;
        const abhaId = req.user.abhaId;

        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }

        const historyLog = new MedicineHistory({
            patient: req.user._id,
            abhaId,
            medicineId,
            medicineName,
            takenTime: takenTime || new Date(),
            status: status || 'TAKEN'
        });

        await historyLog.save();
        res.status(201).json(historyLog);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Medicine History
router.get('/history', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }

        const history = await MedicineHistory.find({ abhaId }).sort({ takenTime: -1 });
        res.json(history);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get all appointments for a patient
router.get('/appointments', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        const appointments = await Appointment.find({ abhaId }).populate('doctorId', 'username speciality').sort({ date: -1 });
        res.json(appointments);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Create new appointment
router.post('/appointments', protect, authorize('Patient'), async (req, res) => {
    try {
        const { doctorId, date, notes } = req.body;
        const abhaId = req.user.abhaId;
        
        if (!doctorId || !date) return res.status(400).json({ message: 'doctorId and date are required' });

        const appointment = await Appointment.create({
            doctorId,
            abhaId,
            patientName: req.user.username,
            date,
            notes,
            status: 'Pending'
        });
        res.status(201).json(appointment);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Accept reschedule request
router.post('/appointments/:id/accept-reschedule', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        const appointment = await Appointment.findOne({ _id: req.params.id, abhaId });
        if (!appointment) return res.status(404).json({ message: 'Appointment not found' });
        
        if (appointment.status !== 'RescheduleRequested') {
            return res.status(400).json({ message: 'Appointment is not in RescheduleRequested status' });
        }
        
        appointment.status = 'Confirmed';
        appointment.date = appointment.rescheduleDate;
        appointment.rescheduleDate = undefined;
        appointment.rescheduleNotes = undefined;
        
        await appointment.save();
        res.json(appointment);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Lab Locations
router.get('/labs', protect, authorize('Patient'), async (req, res) => {
    try {
        const labs = await User.find({ role: 'Pathologist' }).select('username location address labTestsProvided');
        res.json(labs);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Book a Lab Test
router.post('/lab-test-orders', protect, authorize('Patient'), async (req, res) => {
    try {
        const { pathologistId, testName } = req.body;
        if (!pathologistId || !testName) return res.status(400).json({ message: 'pathologistId and testName are required' });

        const order = await LabTestOrder.create({
            patientId: req.user._id,
            patientName: req.user.username,
            pathologistId,
            testName,
            status: 'Pending'
        });
        res.status(201).json(order);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Patient's Lab Test Orders
router.get('/lab-test-orders', protect, authorize('Patient'), async (req, res) => {
    try {
        const orders = await LabTestOrder.find({ patientId: req.user._id }).populate('pathologistId', 'username').sort({ createdAt: -1 });
        res.json(orders);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
