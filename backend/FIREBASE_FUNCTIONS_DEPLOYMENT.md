# Firebase Functions Deployment Instructions

## Prerequisites

1. Firebase CLI installed globally: `npm install -g firebase-tools`
2. Firebase project created in Firebase Console
3. **Blaze (pay-as-you-go) plan** activated for your Firebase project (required for secrets/environment variables)

## Configuration Steps

### 1. Upgrade to Blaze Plan
- Go to Firebase Console: https://console.firebase.google.com/
- Select your project
- Navigate to "Usage and billing" 
- Upgrade to Blaze plan (you won't be charged until usage exceeds free tier)

### 2. Set Environment Variables

After upgrading to Blaze plan, run:

```bash
cd d:\ECHAPP\backend\functions
firebase functions:secrets:set MONGODB_URI --data="mongodb+srv://hashimuimfuransa:hashimu@cluster0.qzuhv97.mongodb.net/echapp?retryWrites=true&w=majority&appName=Cluster0"
```

Alternatively, you can use the newer params system:

```bash
firebase functions:config:set mongodb.uri="mongodb+srv://hashimuimfuransa:hashimu@cluster0.qzuhv97.mongodb.net/echapp?retryWrites=true&w=majority&appName=Cluster0"
```

### 3. Deploy Functions

```bash
cd d:\ECHAPP\backend
firebase deploy --only functions
```

## Function Overview

The following functions are deployed:

1. `syncUserToMongo` - Triggers on Firebase Auth user creation to sync user data to MongoDB
2. `updateUserInMongo` - Triggers on Firebase Auth user updates
3. `handleUserDeletion` - Triggers on Firebase Auth user deletion to remove from MongoDB
4. `manualSyncUsers` - Callable function to manually sync all existing Firebase users to MongoDB

## Security Considerations

- The MongoDB URI is stored securely using Firebase secrets
- Functions authenticate with Firebase Admin SDK
- Only authenticated users can call the manual sync function
- All user data is sanitized before insertion

## Troubleshooting

### Common Issues:

1. **Billing not enabled**: Make sure your project is on the Blaze plan
2. **Permission errors**: Ensure your Firebase Admin SDK is properly initialized
3. **Connection timeouts**: Verify your MongoDB Atlas connection string and IP whitelist

### Testing:

1. Create a test user in Firebase Authentication
2. Check MongoDB Atlas to confirm user was created in the 'users' collection
3. Monitor Firebase Functions logs for any errors

## Architecture

```
User signs up
   ↓
Firebase Authentication
   ↓
Firebase Cloud Function (onCreate)
   ↓
MongoDB Atlas
```

This ensures no frontend risk, no manual sync, no 401 errors, and fully secure operation.