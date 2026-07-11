const nodemailer = require('nodemailer');

let cachedTransporter = null;

const getTransporter = () => {
    if (cachedTransporter) {
        return cachedTransporter;
    }

    const user = process.env.EMAIL_USER || 'medecosmail@gmail.com';
    // Remove quotes and all whitespace (including spaces between 4-letter chunks)
    const pass = (process.env.EMAIL_APP_PASSWORD || 'tcll qyrr ntjg pona').replace(/['"\s]/g, '').trim();

    // Singleton transporter instance using Gmail service settings optimized for cloud platforms (Render/AWS)
    cachedTransporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user,
            pass
        },
        connectionTimeout: 15000,
        greetingTimeout: 15000,
        socketTimeout: 20000
    });

    return cachedTransporter;
};

/**
 * Sends a stylized HTML OTP Verification email to the user.
 * @param {string} toEmail - Recipient email address
 * @param {string} otp - The 6-digit verification code
 * @param {string} purpose - Purpose description (e.g. "Login Verification", "Account Registration")
 */
const sendOtpEmail = async (toEmail, otp, purpose = 'Verification') => {
    const transporter = getTransporter();

    const htmlContent = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>MedEcos Verification Code</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f0f4f8; color: #1e293b; -webkit-font-smoothing: antialiased;">
        <!-- Hidden preheader text -->
        <div style="display: none; max-height: 0px; overflow: hidden;">
            Your MedEcos security code is ${otp}. Use this to verify your email address. Valid for 5 minutes.
        </div>
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f0f4f8; padding: 40px 16px;">
            <tr>
                <td align="center">
                    <!-- Main Card -->
                    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 580px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(15, 23, 42, 0.08); border: 1px solid #e2e8f0;">
                        <!-- Header Banner -->
                        <tr>
                            <td style="background: linear-gradient(135deg, #0284c7 0%, #0d9488 100%); padding: 36px 32px; text-align: center;">
                                <table border="0" cellpadding="0" cellspacing="0" width="100%">
                                    <tr>
                                        <td align="center">
                                            <div style="display: inline-block; background-color: rgba(255, 255, 255, 0.15); padding: 8px 16px; border-radius: 999px; margin-bottom: 12px;">
                                                <span style="color: #ffffff; font-size: 12px; font-weight: 600; letter-spacing: 1.5px; text-transform: uppercase;">Secure Authentication</span>
                                            </div>
                                            <h1 style="color: #ffffff; margin: 0; font-size: 30px; font-weight: 800; letter-spacing: -0.5px;">MedEcos</h1>
                                            <p style="color: #e0f2fe; margin: 6px 0 0; font-size: 14px; font-weight: 400;">Smart Decentralized Healthcare Ecosystem</p>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>

                        <!-- Body Content -->
                        <tr>
                            <td style="padding: 40px 36px;">
                                <h2 style="color: #0f172a; font-size: 22px; font-weight: 700; margin: 0 0 12px;">Verify Your Email Address</h2>
                                <p style="font-size: 15px; line-height: 1.6; color: #475569; margin: 0 0 24px;">
                                    Thank you for using <strong>MedEcos</strong>. Please use the following One-Time Password (OTP) to complete your <strong>${purpose}</strong>.
                                </p>

                                <!-- OTP Box Card -->
                                <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 28px 0;">
                                    <tr>
                                        <td align="center" style="background: linear-gradient(145deg, #f8fafc 0%, #f1f5f9 100%); border: 2px dashed #0284c7; border-radius: 14px; padding: 24px 16px;">
                                            <p style="margin: 0 0 8px; font-size: 11px; font-weight: 700; color: #0284c7; text-transform: uppercase; letter-spacing: 1.5px;">Your Verification Code</p>
                                            <div style="font-size: 38px; font-weight: 800; letter-spacing: 10px; color: #0f172a; font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; padding-left: 10px;">
                                                ${otp}
                                            </div>
                                            <p style="margin: 10px 0 0; font-size: 12px; color: #64748b;">
                                                ⏱️ Code expires in <strong>5 minutes</strong>
                                            </p>
                                        </td>
                                    </tr>
                                </table>

                                <!-- Security Shield Banner -->
                                <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #fffbeb; border-left: 4px solid #f59e0b; border-radius: 8px; margin-top: 28px;">
                                    <tr>
                                        <td style="padding: 16px;">
                                            <p style="margin: 0; font-size: 13px; line-height: 1.5; color: #92400e;">
                                                <strong>Security Advice:</strong> Never share this verification code with anyone, including MedEcos support staff. If you did not request this email, please ignore it safely.
                                            </p>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>

                        <!-- Footer -->
                        <tr>
                            <td style="background-color: #f8fafc; padding: 24px 36px; text-align: center; border-top: 1px solid #e2e8f0;">
                                <p style="margin: 0 0 8px; font-size: 13px; font-weight: 600; color: #334155;">MedEcos Healthcare Platform</p>
                                <p style="margin: 0; font-size: 12px; color: #64748b; line-height: 1.6;">
                                    &copy; ${new Date().getFullYear()} MedEcos. All rights reserved.<br>
                                    End-to-End Secure Healthcare Verification
                                </p>
                            </td>
                        </tr>
                    </table>
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
