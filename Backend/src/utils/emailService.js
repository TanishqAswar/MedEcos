const nodemailer = require('nodemailer');

const createTransporter = () => {
    const user = process.env.EMAIL_USER || 'medecosmail@gmail.com';
    const pass = (process.env.EMAIL_APP_PASSWORD || 'tcll qyrr ntjg pona').replace(/['"]/g, '').trim();

    return nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user,
            pass
        }
    });
};

/**
 * Sends a stylized HTML OTP Verification email to the user.
 * @param {string} toEmail - Recipient email address
 * @param {string} otp - The 6-digit verification code
 * @param {string} purpose - Purpose description (e.g. "Login Verification", "Account Registration")
 */
const sendOtpEmail = async (toEmail, otp, purpose = 'Verification') => {
    const transporter = createTransporter();

    const htmlContent = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>MedEcos OTP Verification</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f9; color: #333333;">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08);">
            <!-- Header -->
            <tr>
                <td style="background: linear-gradient(135deg, #0d6efd, #00b4d8); padding: 32px 24px; text-align: center;">
                    <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: 0.5px;">MedEcos</h1>
                    <p style="color: #e0f2fe; margin: 6px 0 0; font-size: 14px;">Smart Decentralized Healthcare Ecosystem</p>
                </td>
            </tr>
            <!-- Content -->
            <tr>
                <td style="padding: 36px 32px;">
                    <h2 style="color: #1e293b; font-size: 20px; margin-top: 0; margin-bottom: 16px;">Hello,</h2>
                    <p style="font-size: 15px; line-height: 1.6; color: #475569; margin-bottom: 24px;">
                        Use the verification code below to complete your <strong>${purpose}</strong> on MedEcos. This code is valid for the next <strong>5 minutes</strong>.
                    </p>
                    <!-- OTP Box -->
                    <div style="background-color: #f8fafc; border: 2px dashed #cbd5e1; border-radius: 10px; padding: 20px; text-align: center; margin: 24px 0;">
                        <span style="font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #0f172a; font-family: monospace;">${otp}</span>
                    </div>
                    <p style="font-size: 13px; color: #64748b; line-height: 1.5; margin-top: 24px;">
                        If you did not request this verification code, please ignore this email or contact support immediately. Never share your OTP with anyone.
                    </p>
                </td>
            </tr>
            <!-- Footer -->
            <tr>
                <td style="background-color: #f1f5f9; padding: 20px 32px; text-align: center; font-size: 12px; color: #64748b; border-top: 1px solid #e2e8f0;">
                    <p style="margin: 0;">&copy; ${new Date().getFullYear()} MedEcos Healthcare Platform. All rights reserved.</p>
                </td>
            </tr>
        </table>
    </body>
    </html>
    `;

    const mailOptions = {
        from: '"MedEcos Security" <medecosmail@gmail.com>',
        to: toEmail,
        subject: `MedEcos Verification Code: ${otp}`,
        html: htmlContent
    };

    return await transporter.sendMail(mailOptions);
};

module.exports = {
    sendOtpEmail
};
