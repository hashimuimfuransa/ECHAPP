# SendGrid Email Integration Setup Guide

This document explains how to set up SendGrid for sending automated emails in the Excellence Coaching Hub application.

## Overview

The application now supports automated email notifications for:
- Welcome emails to new registered users
- Password reset emails
- Payment status notifications (approved, rejected, pending)
- New course announcements

## Prerequisites

1. A SendGrid account (sign up at [sendgrid.com](https://sendgrid.com))
2. A verified sender email address in SendGrid
3. Your SendGrid API key

## Configuration Steps

### 1. Obtain SendGrid API Key

1. Log in to your SendGrid account
2. Navigate to Settings → API Keys
3. Click "Create API Key"
4. Give your API key a name (e.g., "ExcellenceCoachingHub")
5. Select "Restricted Access" and grant permissions:
   - Mail Send: Full Access
   - Other permissions as needed
6. Copy the generated API key (you won't be able to see it again)

### 2. Update Environment Variables

Add your SendGrid API key to the `.env` file in the backend directory:

```bash
SENDGRID_API_KEY=your_actual_sendgrid_api_key_here
FROM_EMAIL=your_verified_sender@example.com
FROM_NAME="Excellence Coaching Hub"
```

Replace `your_actual_sendgrid_api_key_here` with your actual SendGrid API key.
Replace `your_verified_sender@example.com` with your verified sender email address.

### 3. Verify Domain (Recommended)

For better deliverability:
1. In SendGrid dashboard, go to Settings → Sender Authentication
2. Verify your domain by adding DNS records as prompted

## Email Features

### Welcome Emails
- Automatically sent when users register via email/password or social login
- Includes login instructions and platform introduction

### Password Reset Emails
- Sent when users request a password reset
- Contains secure reset link with expiration

### Payment Status Emails
- **Pending**: Sent when payment is submitted for review
- **Approved**: Sent when payment is approved
- **Rejected**: Sent when payment is declined
- Includes transaction details and next steps

### New Course Announcements
- Sent to all active users when new courses are published
- Includes course details, pricing, and enrollment link

## Integration Points

The email service is integrated into:
- User registration (`/api/auth/register`)
- Password reset workflow
- Payment status updates (`/api/payments/verify`)
- Course publishing (`/api/courses` POST)

## Testing

To test the email functionality:

1. Update your `.env` file with a valid SendGrid API key
2. Set a test email address: `TEST_EMAIL=test@example.com`
3. Run the test script: `node test_email_service.js`

## Troubleshooting

### Common Issues

1. **API Key Errors**: Verify your API key format starts with "SG."
2. **Email Not Sent**: Check that your sender email is verified in SendGrid
3. **Rate Limits**: SendGrid has usage limits; check your plan's restrictions
4. **Spam Folder**: New domains may have deliverability issues

### Delivery Issues

- Monitor SendGrid's Activity Feed for bounce/drop reports
- Check domain authentication settings
- Review content filtering settings
- Ensure sender reputation is maintained

## Security Considerations

- Never commit API keys to version control
- Use environment variables exclusively
- Rotate API keys periodically
- Use restricted access keys with minimal required permissions

## Production Checklist

- [ ] Valid SendGrid API key in production environment
- [ ] Verified sender email domain
- [ ] Custom email templates configured
- [ ] Rate limits understood and planned for
- [ ] Email analytics and monitoring set up
- [ ] Backup notification system (e.g., SMS) for critical notifications