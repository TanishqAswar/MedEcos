require('dotenv').config();
const { sendOtpEmail } = require('./src/utils/emailService');

async function testGmailOtp() {
    console.log('Testing Gmail OTP service...');
    console.log('EMAIL_USER:', process.env.EMAIL_USER || 'medecosmail@gmail.com');
    
    // We will send a test OTP to medecosmail@gmail.com itself to verify SMTP auth works
    const targetEmail = process.env.EMAIL_USER || 'medecosmail@gmail.com';
    const testOtp = '849201';

    try {
        const info = await sendOtpEmail(targetEmail, testOtp, 'Security Test');
        console.log('SUCCESS! OTP Email sent.');
        console.log('Message ID:', info.messageId);
    } catch (err) {
        console.error('ERROR sending email via Gmail:', err);
    }
}

testGmailOtp();
