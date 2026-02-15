const nodemailer = require('nodemailer');
const fs = require('fs').promises;
const path = require('path');

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransporter({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });
    
    this.fromEmail = process.env.EMAIL_USER || 'noreply@excellencecoachinghub.com';
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(email, resetToken, user) {
    try {
      const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;
      
      const mailOptions = {
        from: `"Excellence Coaching Hub" <${this.fromEmail}>`,
        to: email,
        subject: 'Password Reset Request - Excellence Coaching Hub',
        html: this.getPasswordResetTemplate(user.fullName, resetUrl)
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Password reset email sent:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw new Error('Failed to send password reset email');
    }
  }

  /**
   * Send password reset confirmation email
   */
  async sendPasswordResetConfirmationEmail(email, user) {
    try {
      const loginUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`;
      
      const mailOptions = {
        from: `"Excellence Coaching Hub" <${this.fromEmail}>`,
        to: email,
        subject: 'Password Successfully Reset - Excellence Coaching Hub',
        html: this.getPasswordResetConfirmationTemplate(user.fullName, loginUrl)
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Password reset confirmation email sent:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('Error sending password reset confirmation email:', error);
      throw new Error('Failed to send password reset confirmation email');
    }
  }

  /**
   * Send welcome email to new users
   */
  async sendWelcomeEmail(email, user) {
    try {
      const loginUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`;
      
      const mailOptions = {
        from: `"Excellence Coaching Hub" <${this.fromEmail}>`,
        to: email,
        subject: 'Welcome to Excellence Coaching Hub!',
        html: this.getWelcomeTemplate(user.fullName, loginUrl)
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Welcome email sent:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('Error sending welcome email:', error);
      throw new Error('Failed to send welcome email');
    }
  }

  /**
   * Password reset email template
   */
  getPasswordResetTemplate(fullName, resetUrl) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #00b09b, #96c93d); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .header h1 { color: white; margin: 0; font-size: 28px; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { 
                display: inline-block; 
                padding: 15px 30px; 
                background: #00b09b; 
                color: white; 
                text-decoration: none; 
                border-radius: 5px; 
                font-weight: bold;
                margin: 20px 0;
            }
            .button:hover { background: #009a86; }
            .footer { 
                text-align: center; 
                padding: 20px; 
                color: #666; 
                font-size: 12px;
                border-top: 1px solid #eee;
                margin-top: 20px;
            }
            .warning { 
                background: #fff3cd; 
                border: 1px solid #ffeaa7; 
                padding: 15px; 
                border-radius: 5px; 
                margin: 20px 0;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔑 Password Reset</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                <p>We received a request to reset your password for your Excellence Coaching Hub account.</p>
                
                <p>If you made this request, please click the button below to reset your password:</p>
                
                <div style="text-align: center;">
                    <a href="${resetUrl}" class="button">Reset Your Password</a>
                </div>
                
                <div class="warning">
                    <strong>⚠️ Important Security Notice:</strong>
                    <ul>
                        <li>This link will expire in 1 hour</li>
                        <li>If you didn't request this, please ignore this email</li>
                        <li>Your password won't change until you create a new one</li>
                    </ul>
                </div>
                
                <p>If the button doesn't work, copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #00b09b;">${resetUrl}</p>
                
                <p>For security reasons, this link can only be used once and will expire after 1 hour.</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>If you have any questions, please contact our support team.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Password reset confirmation template
   */
  getPasswordResetConfirmationTemplate(fullName, loginUrl) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset Successful</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #00b09b, #96c93d); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .header h1 { color: white; margin: 0; font-size: 28px; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .success { 
                background: #d4edda; 
                border: 1px solid #c3e6cb; 
                padding: 15px; 
                border-radius: 5px; 
                margin: 20px 0;
                text-align: center;
            }
            .button { 
                display: inline-block; 
                padding: 15px 30px; 
                background: #00b09b; 
                color: white; 
                text-decoration: none; 
                border-radius: 5px; 
                font-weight: bold;
                margin: 20px 0;
            }
            .footer { 
                text-align: center; 
                padding: 20px; 
                color: #666; 
                font-size: 12px;
                border-top: 1px solid #eee;
                margin-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>✅ Password Reset Successful</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                
                <div class="success">
                    <h3>🎉 Your password has been successfully reset!</h3>
                    <p>You can now log in with your new password.</p>
                </div>
                
                <p>If you did not make this change, please contact our support team immediately.</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${loginUrl}" class="button">Login to Your Account</a>
                </div>
                
                <p>Thank you for using Excellence Coaching Hub!</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>Stay secure and keep learning!</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Welcome email template
   */
  getWelcomeTemplate(fullName, loginUrl) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to Excellence Coaching Hub</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #00b09b, #96c93d); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .header h1 { color: white; margin: 0; font-size: 28px; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { 
                display: inline-block; 
                padding: 15px 30px; 
                background: #00b09b; 
                color: white; 
                text-decoration: none; 
                border-radius: 5px; 
                font-weight: bold;
                margin: 20px 0;
            }
            .features { 
                background: white; 
                padding: 20px; 
                border-radius: 5px; 
                margin: 20px 0;
                border-left: 4px solid #00b09b;
            }
            .footer { 
                text-align: center; 
                padding: 20px; 
                color: #666; 
                font-size: 12px;
                border-top: 1px solid #eee;
                margin-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎓 Welcome to Excellence Coaching Hub!</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                <p>Welcome to Excellence Coaching Hub! We're excited to have you join our learning community.</p>
                
                <p>Your account has been successfully created and you're ready to start your learning journey.</p>
                
                <div class="features">
                    <h3>✨ What you can do now:</h3>
                    <ul>
                        <li>Browse our comprehensive courses</li>
                        <li>Enroll in subjects that interest you</li>
                        <li>Access exclusive learning materials</li>
                        <li>Track your progress and achievements</li>
                    </ul>
                </div>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${loginUrl}" class="button">Start Learning Now</a>
                </div>
                
                <p>If you have any questions or need assistance, our support team is always here to help.</p>
                <p>Happy learning!</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>Start your educational journey with us today!</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Verify email configuration
   */
  async verifyConfiguration() {
    try {
      await this.transporter.verify();
      console.log('✅ Email service configured successfully');
      return true;
    } catch (error) {
      console.error('❌ Email service configuration failed:', error);
      return false;
    }
  }
}

module.exports = new EmailService();