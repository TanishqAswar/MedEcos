const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Database Connection
mongoose.connect(process.env.MONGO_URI)
    .then(async () => {
        console.log('MongoDB Connected');
        try {
            const User = require('./models/User');
            const bcrypt = require('bcryptjs');
            let adminUser = await User.findOne({ email: 'admin@medecos.com' });
            if (!adminUser) {
                const salt = await bcrypt.genSalt(10);
                const adminPassword = await bcrypt.hash('Admin@123', salt);
                await User.create({
                    username: 'System Admin',
                    email: 'admin@medecos.com',
                    password: adminPassword,
                    role: 'Admin',
                    isVerified: true,
                    aiVerification: { status: 'not_required' },
                    humanVerification: { status: 'not_required' }
                });
                console.log('Created initial System Admin user (admin@medecos.com)');
            }
        } catch (e) {
            console.error('Error verifying admin account on startup:', e);
        }
    })
    .catch(err => console.log(err));

// Serve static files from Frontend/public
const path = require('path');
app.use(express.static(path.join(__dirname, '../../Frontend/public')));

// Import Routes
const authRoutes = require('./routes/authRoutes');
const doctorRoutes = require('./routes/doctorRoutes');
const patientRoutes = require('./routes/patientRoutes');
const pharmacistRoutes = require('./routes/pharmacistRoutes');
const pathologistRoutes = require('./routes/pathologistRoutes');
const adminRoutes = require('./routes/adminRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/v1/doctor', doctorRoutes);
app.use('/api/v1/patient', patientRoutes);
app.use('/api/v1/pharmacist', pharmacistRoutes);
app.use('/api/v1/pathologist', pathologistRoutes);
app.use('/api/v1/admin', adminRoutes);

// ABDM Webhook Routes
const abdmRoutes = require('./routes/abdmRoutes');
app.use('/api/abdm', abdmRoutes);
app.use('/v0.5', abdmRoutes);

// Mock ABDM Gateway (For Presentation)
const mockAbdmGateway = require('./routes/mockAbdmGateway');
app.use('/mock-gateway', mockAbdmGateway);

// Public Routes
const publicRoutes = require('./routes/publicRoutes');
app.use('/api/public', publicRoutes);

// Test Routes
const testRoutes = require('./routes/testRoutes');
app.use('/api/test', testRoutes);

// Agora Routes
const agoraRoutes = require('./routes/agoraRoutes');
app.use('/api/agora', agoraRoutes);

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
