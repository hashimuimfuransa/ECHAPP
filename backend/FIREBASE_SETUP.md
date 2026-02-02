# Firebase Integration Setup Guide

## Overview
This guide explains how to set up Firebase integration with the Excellence Coaching Hub backend to synchronize users between Firebase Authentication and MongoDB.

## Prerequisites
- Node.js installed
- Firebase project created
- Service account key from Firebase Console
- MongoDB database setup

## Setup Steps

### 1. Firebase Configuration
1. Download your Firebase service account key from Firebase Console
2. Place the `serviceAccountKey.json` file in the backend root directory
3. Make sure the file is in `.gitignore` to avoid committing sensitive credentials

### 2. Environment Variables
Update your `.env` file with the Firebase sync API key:
```env
FIREBASE_SYNC_API_KEY=your_generated_secure_api_key_here
```

### 3. Test Firebase Connection
Run the test script to verify Firebase connectivity:
```bash
npm run test:firebase
```

### 4. Sync Existing Users
If you have existing Firebase users, sync them to MongoDB:
```bash
npm run sync:users
```

### 5. Deploy Firebase Functions (Optional)
For automatic synchronization:
1. Navigate to the `functions` directory
2. Install dependencies: `npm install`
3. Deploy functions: `npm run deploy`

## How It Works

### User Creation Flow
1. User registers/signs in through Firebase Authentication
2. Firebase Cloud Function triggers on user creation
3. Function sends user data to backend `/api/auth/sync-firebase-user` endpoint
4. Backend creates/updates user record in MongoDB
5. Admin dashboard can now fetch users from Firebase directly

### Admin Dashboard Access
The admin dashboard now fetches users directly from Firebase Authentication instead of MongoDB, ensuring real-time data.

## API Endpoints

### Firebase Sync Endpoints
- `POST /api/auth/sync-firebase-user` - Sync Firebase user to MongoDB
- `DELETE /api/auth/sync-firebase-user/:firebaseUid` - Delete user from MongoDB

### Admin Endpoints
- `GET /api/admin/students` - Fetch students from Firebase (with fallback to MongoDB)

## Security Notes
- The sync endpoints are protected by `FIREBASE_SYNC_API_KEY`
- Never expose this key in client-side code
- Use HTTPS in production
- Regularly rotate API keys

## Troubleshooting

### Common Issues
1. **Firebase connection fails**: Check service account key permissions
2. **Sync fails**: Verify `FIREBASE_SYNC_API_KEY` matches in both backend and Firebase functions
3. **Users not appearing**: Run manual sync script to populate existing users

### Logs
Check logs for detailed error information:
```bash
# Backend logs
npm run dev

# Firebase function logs
npm run logs
```

## Maintenance
- Regularly backup your MongoDB database
- Monitor sync success rates
- Update Firebase functions when making changes to user schema