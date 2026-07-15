const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const User = require('../models/User');

dotenv.config({ path: path.join(__dirname, '../../.env') });

async function markExistingPractitionersVerified() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected.');

        const roles = ['Doctor', 'Pharmacist', 'Pathologist'];
        const practitioners = await User.find({ role: { $in: roles } });

        console.log(`Found ${practitioners.length} existing practitioners/laboratories.`);

        let updatedCount = 0;
        for (const user of practitioners) {
            if (!user.isVerified) {
                user.isVerified = true;
                user.aiVerification = {
                    status: 'verified',
                    confidenceScore: 99,
                    documentTypeDetected: 'Pre-existing Practice Record',
                    notes: 'Pre-existing practitioner automatically marked verified.',
                    verifiedAt: new Date()
                };
                user.humanVerification = {
                    status: 'verified',
                    verifiedBy: 'System Migration',
                    notes: 'Pre-existing practitioner marked verified per policy.',
                    verifiedAt: new Date()
                };
                await user.save();
                updatedCount++;
                console.log(`Marked verified: ${user.username} (${user.role})`);
            }
        }

        console.log(`Migration complete. Updated ${updatedCount} practitioners to isVerified = true.`);
        process.exit(0);
    } catch (error) {
        console.error('Migration error:', error);
        process.exit(1);
    }
}

markExistingPractitionersVerified();
