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
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 300, // Expires in 5 minutes
    }
}, { timestamps: true });

module.exports = mongoose.model('Otp', otpSchema);
