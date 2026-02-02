# Firebase Authentication Implementation

## Overview
This implementation simplifies the Firebase authentication flow to handle both user registration (sign-up) and login with a single endpoint.

## Authentication Flow

### Case 1: User Registers (Sign-up)
1. User signs up with Firebase Auth
2. Firebase creates a UID
3. User logs in (usually automatic after signup)
4. Frontend sends Firebase ID token to backend
5. Backend:
   - Verifies Firebase ID token
   - Creates user in MongoDB if not exists
   - Returns user data + JWT token

### Case 2: User Logs In (Already Registered)
1. User logs in with Firebase Auth
2. Frontend sends Firebase ID token to backend
3. Backend:
   - Verifies Firebase ID token
   - Checks MongoDB for existing user
   - Creates user if missing (handles legacy users)
   - Returns user data + JWT token

## API Endpoints

### POST /api/auth/firebase-login
Authenticate user with Firebase ID token.

**Request:**
```json
{
  "idToken": "firebase-id-token-here"
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "mongodb-user-id",
      "firebaseUid": "firebase-user-uid",
      "fullName": "User Name",
      "email": "user@example.com",
      "role": "student",
      "provider": "firebase"
    },
    "token": "jwt-access-token",
    "refreshToken": "jwt-refresh-token"
  },
  "message": "Authentication successful"
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Invalid Firebase ID token",
  "statusCode": 401
}
```

## How It Works

### Backend Logic
1. **Token Verification**: The backend verifies the Firebase ID token using Firebase Admin SDK
2. **User Lookup**: Checks if user exists in MongoDB by `firebaseUid`
3. **User Creation**: If user doesn't exist, creates new user record
4. **Token Generation**: Generates JWT tokens for subsequent API requests
5. **Response**: Returns user data and tokens

### Middleware Protection
The `protect` middleware now only verifies Firebase ID tokens:
- Extracts token from `Authorization: Bearer <token>` header
- Verifies token with Firebase Admin SDK
- Looks up user in MongoDB
- Ensures user is active
- Attaches user to request object

## Frontend Integration

### 1. After Firebase Sign-in
```javascript
// Get Firebase ID token
const idToken = await user.getIdToken();

// Send to backend
const response = await fetch('/api/auth/firebase-login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ idToken })
});

const { data } = await response.json();
// Store tokens for future requests
localStorage.setItem('token', data.token);
localStorage.setItem('refreshToken', data.refreshToken);
```

### 2. Making Protected Requests
```javascript
// Use JWT token for protected routes
const token = localStorage.getItem('token');
const response = await fetch('/api/courses', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

## Key Changes Made

### Removed Complexity
- ❌ Removed Firebase functions for automatic user sync
- ❌ Removed complex sync endpoints
- ❌ Removed API key-based authentication for sync

### Simplified Approach
- ✅ Single `/firebase-login` endpoint handles both cases
- ✅ Clean auth middleware focused on Firebase tokens
- ✅ Optional password field for Firebase users
- ✅ Automatic user creation on first login

## Benefits

1. **Simplicity**: One endpoint handles both registration and login
2. **Reliability**: No complex synchronization between Firebase and MongoDB
3. **Flexibility**: Works for new users and existing Firebase users
4. **Security**: Uses Firebase's secure token verification
5. **Performance**: Direct token verification without additional HTTP calls

## Error Handling

Common error responses:
- `400`: Missing ID token
- `401`: Invalid Firebase token
- `500`: Server/database errors

The implementation automatically handles edge cases like users who exist in Firebase but not in MongoDB.