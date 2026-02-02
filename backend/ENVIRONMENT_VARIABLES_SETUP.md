# Environment Variables Setup Guide

This document provides guidance on how to properly set up environment variables for the ExcellenceCoachingHub backend application.

## Required Environment Variables

Create a `.env` file in the backend root directory with the following variables:

```
NODE_ENV=development
PORT=5000
MONGODB_URI=your_mongodb_connection_string_here
JWT_SECRET=your_jwt_secret_key_here_change_in_production
JWT_REFRESH_SECRET=your_jwt_refresh_secret_key_here_change_in_production
CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
CLOUDFLARE_STREAM_KEY=your_cloudflare_stream_key

# Firebase Configuration
FIREBASE_SYNC_API_KEY=your_firebase_sync_api_key_here_change_in_production
```

## Setting Up Environment Variables

### 1. MongoDB Connection String

Replace `your_mongodb_connection_string_here` with your actual MongoDB connection string:
- For MongoDB Atlas: `mongodb+srv://username:password@cluster.mongodb.net/database_name`
- For local MongoDB: `mongodb://localhost:27017/database_name`

### 2. JWT Secrets

Generate strong, random secrets for JWT tokens:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 3. Cloudflare Credentials

Sign up for Cloudflare and create:
- Account ID from your Cloudflare dashboard
- API Token with appropriate permissions
- Stream Key for video streaming

### 4. Firebase Sync API Key

Generate a secure API key for Firebase user synchronization:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Security Best Practices

1. **Never commit .env files** - They are already excluded in `.gitignore`, ensure they stay that way
2. **Use different values for different environments** (dev, staging, prod)
3. **Regenerate secrets regularly** - Especially in production
4. **Use strong, randomly generated passwords** - Avoid predictable values
5. **Restrict access** - Ensure only authorized people have access to these values

## Production Deployment

When deploying to production:
1. Use environment variables provided by your hosting platform
2. Use a secrets management system if available (like AWS Secrets Manager, Azure Key Vault, etc.)
3. Ensure all sensitive values are properly encrypted
4. Review all configuration values before deployment

## Troubleshooting

If you encounter issues with environment variables:
1. Verify the `.env` file exists and is in the correct location
2. Check that there are no spaces around the `=` sign in variable assignments
3. Ensure the application has read permissions for the `.env` file
4. Restart the application after making changes to the `.env` file