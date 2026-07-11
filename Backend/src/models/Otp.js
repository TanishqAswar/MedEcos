const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema({
    abhaId: {
        type: String,
        required: false,
    },
    email: {
        type: String,
        required: false,
    },
    otp: {
        type: String,
        required: true,
    },
    transactionId: {
        type: String,
        required: true,
        unique: true,
    },
    verified: {
        type: Boolean,
        default: false,
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 1800, // Expires in 30 minutes after verification
    }
}, { timestamps: true });

module.exports = mongoose.model('Otp', otpSchema);
