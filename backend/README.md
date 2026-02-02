# ExcellenceCoachingHub Backend API

## Overview
This is the backend API for ExcellenceCoachingHub, a comprehensive e-learning platform built with Node.js, Express, and MongoDB.

## Features
- User authentication with JWT tokens
- Course management (CRUD operations)
- Enrollment system
- Video streaming with Cloudflare Stream integration
- Exam and quiz system with auto-grading
- Mobile money payment integration (MTN MoMo, Airtel Money)
- Admin panel for course and user management

## Technology Stack
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database with Mongoose ODM
- **JWT** - Authentication
- **Cloudflare Stream** - Video streaming
- **bcryptjs** - Password hashing

## API Endpoints

### Authentication
```
POST /api/auth/register - Register new user
POST /api/auth/login - Login user
POST /api/auth/refresh-token - Refresh JWT token
GET /api/auth/profile - Get user profile
POST /api/auth/logout - Logout user
```

### Courses
```
GET /api/courses - Get all courses
GET /api/courses/:id - Get course by ID
GET /api/courses/:id/details - Get detailed course information
POST /api/courses - Create course (admin only)
PUT /api/courses/:id - Update course (admin only)
DELETE /api/courses/:id - Delete course (admin only)
```

### Enrollments
```
POST /api/enrollments - Enroll in a course
GET /api/enrollments/my-courses - Get user's enrolled courses
GET /api/enrollments/:id/progress - Get enrollment progress
PUT /api/enrollments/:id/progress - Update enrollment progress
```

### Exams
```
GET /api/exams/:courseId - Get course exams
GET /api/exams/:examId/questions - Get exam questions
POST /api/exams/:examId/submit - Submit exam answers
GET /api/exams/:examId/results - Get exam results
POST /api/exams - Create exam (admin only)
```

### Payments
```
POST /api/payments/initiate - Initiate payment
POST /api/payments/verify - Verify payment
GET /api/payments/my-payments - Get user's payment history
GET /api/payments/:id - Get payment by ID
GET /api/payments - Get all payments (admin only)
```

### Videos
```
GET /api/videos/:lessonId/stream-url - Get signed video stream URL
POST /api/videos/upload - Upload video (admin only)
GET /api/videos/details/:videoId - Get video details (admin only)
```

### Admin
```
POST /api/admin/create-admin - Create admin user
GET /api/admin/students - Get all students
GET /api/admin/course-stats - Get course statistics
GET /api/admin/payment-stats - Get payment statistics
GET /api/admin/exam-stats - Get exam statistics
```

## Environment Variables
Create a `.env` file in the backend root directory:

```
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://localhost:27017/echapp
JWT_SECRET=your_jwt_secret_key_here
JWT_REFRESH_SECRET=your_jwt_refresh_secret_key_here
CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
CLOUDFLARE_STREAM_KEY=your_cloudflare_stream_key

# Firebase Configuration
FIREBASE_SYNC_API_KEY=your_firebase_sync_api_key_here_change_in_production
```

## Firebase Integration

This backend integrates with Firebase Authentication for user management:

### Setup
1. Place your `serviceAccountKey.json` in the backend root directory
2. Set `FIREBASE_SYNC_API_KEY` in your `.env` file
3. Deploy Firebase Cloud Functions from the `functions` directory

### Features
- Automatic user synchronization between Firebase and MongoDB (NEW: Direct sync via Firebase Cloud Functions)
- Real-time user creation/deletion sync
- Manual sync script for existing users
- Admin dashboard fetches users directly from Firebase
- NEW: Firebase Cloud Functions for secure server-side user sync

### Manual Sync
To sync existing Firebase users to MongoDB:
```bash
node scripts/syncFirebaseUsers.js
```

## Installation

1. Clone the repository
2. Navigate to the backend directory:
   ```bash
   cd backend
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Create a `.env` file with the required environment variables
5. Start the development server:
   ```bash
   npm run dev
   ```

## Database Models

### User
- fullName: String
- email: String (unique)
- password: String (hashed)
- role: String (student/admin)
- phone: String
- isActive: Boolean

### Course
- title: String
- description: String
- price: Number
- duration: Number
- level: String (beginner/intermediate/advanced)
- thumbnail: String
- isPublished: Boolean
- createdBy: ObjectId (User)

### Enrollment
- userId: ObjectId (User)
- courseId: ObjectId (Course)
- enrollmentDate: Date
- completionStatus: String
- progress: Number
- completedLessons: [ObjectId]
- certificateEligible: Boolean

### Payment
- userId: ObjectId (User)
- courseId: ObjectId (Course)
- amount: Number
- currency: String
- paymentMethod: String (mtn_momo/airtel_money)
- transactionId: String (unique)
- status: String
- paymentDate: Date

### Exam
- courseId: ObjectId (Course)
- title: String
- type: String (quiz/final)
- passingScore: Number
- timeLimit: Number
- isPublished: Boolean

### Question
- examId: ObjectId (Exam)
- question: String
- options: [String]
- correctAnswer: Number
- points: Number

### Result
- userId: ObjectId (User)
- examId: ObjectId (Exam)
- answers: [{ questionId, selectedOption }]
- score: Number
- totalPoints: Number
- percentage: Number
- passed: Boolean
- submittedAt: Date

## Security Features

1. **JWT Authentication**: Secure token-based authentication
2. **Role-based Access Control**: Different permissions for students and admins
3. **Video Security**: Signed URLs with short expiration times
4. **Password Hashing**: bcrypt for secure password storage
5. **Input Validation**: Joi validation for all inputs
6. **Rate Limiting**: Protection against abuse
7. **CORS**: Controlled cross-origin resource sharing

## Development Phases

1. ✅ Authentication & User Management
2. ✅ Course Management
3. ✅ Enrollment System
4. ✅ Video Streaming Integration
5. ✅ Exam & Quiz System
6. ✅ Payment Integration
7. ✅ Admin Panel

## Future Enhancements

- Certificate generation
- Offline content download
- Push notifications
- Multi-language support
- Instructor role and course creation tools
- Analytics dashboard

## Testing

```bash
npm test
```

## Deployment

The API can be deployed to any cloud provider (AWS, DigitalOcean, Heroku, etc.) that supports Node.js applications.

## Support

For issues and questions, please contact the development team.