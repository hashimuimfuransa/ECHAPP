const User = require('../models/User');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const Payment = require('../models/Payment');
const Result = require('../models/Result');
const { sendSuccess, sendError } = require('../utils/response.utils');
const admin = require('firebase-admin');

// Sync Firebase user to MongoDB
const syncFirebaseUser = async (req, res) => {
  try {
    // Verify API key for security
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== process.env.FIREBASE_SYNC_API_KEY) {
      return sendUnauthorized(res, 'Invalid API key');
    }
    
    const { firebaseUid, fullName, email, phone, provider, role = 'student' } = req.body;
    
    // Validate required fields
    if (!firebaseUid || !email) {
      return sendError(res, 'Firebase UID and email are required', 400);
    }
    
    // Check if user already exists
    let user = await User.findOne({ firebaseUid });
    
    if (user) {
      // Update existing user
      user.fullName = fullName || user.fullName;
      user.email = email;
      user.phone = phone || user.phone;
      user.role = role;
      user.lastLogin = new Date();
      await user.save();
      
      return sendSuccess(res, {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role
      }, 'User updated successfully');
    } else {
      // Create new user
      user = await User.create({
        firebaseUid,
        fullName: fullName || 'New User',
        email,
        phone,
        role,
        provider: provider || 'firebase'
      });
      
      return sendSuccess(res, {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role
      }, 'User created successfully', 201);
    }
  } catch (error) {
    sendError(res, 'Failed to sync user', 500, error.message);
  }
};

// Delete user sync
const deleteUserSync = async (req, res) => {
  try {
    const { firebaseUid } = req.params;
    
    if (!firebaseUid) {
      return sendError(res, 'Firebase UID is required', 400);
    }
    
    const user = await User.findOneAndDelete({ firebaseUid });
    
    if (!user) {
      return sendError(res, 'User not found', 404);
    }
    
    sendSuccess(res, {
      id: user._id,
      firebaseUid: user.firebaseUid,
      email: user.email
    }, 'User deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete user', 500, error.message);
  }
};

// Get all students from Firebase with MongoDB backup
const getStudents = async (req, res) => {
  try {
    const { page = 1, limit = 10, search, source = 'firebase' } = req.query;
    
    if (source === 'firebase') {
      // Fetch from Firebase
      let firebaseUsers = [];
      let total = 0;
      
      try {
        // Get all users from Firebase
        const userList = await admin.auth().listUsers();
        let filteredUsers = userList.users.filter(user => 
          user.customClaims?.role !== 'admin'
        );
        
        // Apply search filter
        if (search) {
          filteredUsers = filteredUsers.filter(user => 
            (user.displayName?.toLowerCase().includes(search.toLowerCase()) ||
             user.email?.toLowerCase().includes(search.toLowerCase()))
          );
        }
        
        total = filteredUsers.length;
        
        // Apply pagination
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + parseInt(limit);
        const paginatedUsers = filteredUsers.slice(startIndex, endIndex);
        
        // Transform Firebase users to match our format
        firebaseUsers = paginatedUsers.map(user => ({
          id: user.uid,
          firebaseUid: user.uid,
          fullName: user.displayName || 'Unknown User',
          email: user.email || 'No email',
          phone: user.phoneNumber,
          role: user.customClaims?.role || 'student',
          provider: user.providerData[0]?.providerId || 'unknown',
          createdAt: user.metadata.creationTime ? 
            new Date(user.metadata.creationTime) : new Date(),
          lastLogin: user.metadata.lastSignInTime ? 
            new Date(user.metadata.lastSignInTime) : null,
          emailVerified: user.emailVerified,
          disabled: user.disabled
        }));
        
        sendSuccess(res, {
          students: firebaseUsers,
          totalPages: Math.ceil(total / limit),
          currentPage: Number(page),
          total,
          source: 'firebase'
        }, 'Students retrieved from Firebase successfully');
        
      } catch (firebaseError) {
        console.error('Firebase error, falling back to MongoDB:', firebaseError.message);
        // Fallback to MongoDB
        const filter = { role: 'student' };
        
        if (search) {
          filter.$or = [
            { fullName: { $regex: search, $options: 'i' } },
            { email: { $regex: search, $options: 'i' } }
          ];
        }
        
        const students = await User.find(filter)
          .select('-password')
          .limit(limit * 1)
          .skip((page - 1) * limit)
          .sort({ createdAt: -1 });
        
        const total = await User.countDocuments(filter);
        
        sendSuccess(res, {
          students,
          totalPages: Math.ceil(total / limit),
          currentPage: Number(page),
          total,
          source: 'mongodb-fallback'
        }, 'Students retrieved from MongoDB (fallback)');
      }
    } else {
      // Original MongoDB approach
      const filter = { role: 'student' };
      
      if (search) {
        filter.$or = [
          { fullName: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } }
        ];
      }
      
      const students = await User.find(filter)
        .select('-password')
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .sort({ createdAt: -1 });
      
      const total = await User.countDocuments(filter);
      
      sendSuccess(res, {
        students,
        totalPages: Math.ceil(total / limit),
        currentPage: Number(page),
        total,
        source: 'mongodb'
      }, 'Students retrieved from MongoDB');
    }
  } catch (error) {
    sendError(res, 'Failed to retrieve students', 500, error.message);
  }
};

// Get course statistics
const getCourseStats = async (req, res) => {
  try {
    const courses = await Course.find({ isPublished: true });
    
    const stats = await Promise.all(courses.map(async (course) => {
      const enrollmentCount = await Enrollment.countDocuments({ courseId: course._id });
      const paymentCount = await Payment.countDocuments({ 
        courseId: course._id, 
        status: 'completed' 
      });
      
      return {
        courseId: course._id,
        title: course.title,
        price: course.price,
        enrollmentCount,
        paymentCount,
        revenue: paymentCount * course.price
      };
    }));
    
    sendSuccess(res, stats, 'Course statistics retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course statistics', 500, error.message);
  }
};

// Get payment statistics
const getPaymentStats = async (req, res) => {
  try {
    const totalPayments = await Payment.countDocuments({ status: 'completed' });
    const totalRevenue = await Payment.aggregate([
      { $match: { status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);
    
    const recentPayments = await Payment.find({ status: 'completed' })
      .populate('userId', 'fullName email')
      .populate('courseId', 'title')
      .sort({ paymentDate: -1 })
      .limit(10);
    
    sendSuccess(res, {
      totalPayments,
      totalRevenue: totalRevenue[0]?.total || 0,
      recentPayments
    }, 'Payment statistics retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve payment statistics', 500, error.message);
  }
};

// Get exam results statistics
const getExamStats = async (req, res) => {
  try {
    const totalResults = await Result.countDocuments();
    const passedResults = await Result.countDocuments({ passed: true });
    const passRate = totalResults > 0 ? (passedResults / totalResults) * 100 : 0;
    
    const recentResults = await Result.find()
      .populate('userId', 'fullName')
      .populate('examId', 'title')
      .sort({ submittedAt: -1 })
      .limit(10);
    
    sendSuccess(res, {
      totalResults,
      passedResults,
      passRate,
      recentResults
    }, 'Exam statistics retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve exam statistics', 500, error.message);
  }
};

// Manual sync all Firebase users to MongoDB
const manualSyncAllUsers = async (req, res) => {
  try {
    console.log('Manual user sync initiated');
    
    // Get all users from Firebase
    const userList = await admin.auth().listUsers();
    
    // Filter out admin users
    const studentUsers = userList.users.filter(userRecord => userRecord.customClaims?.role !== 'admin');
    
    console.log(`Processing ${studentUsers.length} users from ${userList.users.length} total users`);
    
    let syncedCount = 0;
    let errorCount = 0;
    const errors = [];
    
    // Process users in batches to improve performance
    const batchSize = 10;
    
    for (let i = 0; i < studentUsers.length; i += batchSize) {
      const batch = studentUsers.slice(i, i + batchSize);
      
      // Process batch in parallel
      const batchPromises = batch.map(async (userRecord) => {
        try {
          const userData = {
            firebaseUid: userRecord.uid,
            fullName: userRecord.displayName || 'Unknown User',
            email: userRecord.email,
            phone: userRecord.phoneNumber,
            provider: userRecord.providerData[0]?.providerId || 'unknown',
            role: userRecord.customClaims?.role || 'student'
          };

          // Sync to MongoDB
          let user = await User.findOne({ firebaseUid: userRecord.uid });
          
          if (user) {
            // Update existing user
            user.fullName = userData.fullName;
            user.email = userData.email;
            user.phone = userData.phone;
            user.role = userData.role;
            user.lastLogin = new Date();
            await user.save();
          } else {
            // Create new user
            await User.create({
              firebaseUid: userData.firebaseUid,
              fullName: userData.fullName,
              email: userData.email,
              phone: userData.phone,
              role: userData.role,
              provider: userData.provider
            });
          }
          
          return true;
        } catch (syncError) {
          console.error(`Failed to sync user ${userRecord.uid}:`, syncError.message);
          return { uid: userRecord.uid, email: userRecord.email, error: syncError.message };
        }
      });
      
      const results = await Promise.all(batchPromises);
      
      // Count successes and collect errors
      results.forEach(result => {
        if (result === true) {
          syncedCount++;
        } else {
          errors.push(result);
          errorCount++;
        }
      });
      
      // Log progress
      console.log(`Processed batch ${Math.floor(i/batchSize) + 1}/${Math.ceil(studentUsers.length/batchSize)}, synced: ${syncedCount}, errors: ${errorCount}`);
    }

    const result = {
      totalUsers: userList.users.length,
      processed: studentUsers.length,
      synced: syncedCount,
      errors: errorCount,
      errorDetails: errors,
      message: `Sync completed: ${syncedCount} users synced, ${errorCount} errors from ${studentUsers.length} student users processed`
    };

    console.log('Manual sync result:', result);
    sendSuccess(res, result, 'Manual user sync completed');
  } catch (error) {
    console.error('Manual sync failed:', error.message);
    sendError(res, 'Manual sync failed', 500, error.message);
  }
};

// Create admin user (for initial setup)
const createAdmin = async (req, res) => {
  try {
    const { fullName, email, password, phone } = req.body;
    
    // Check if admin already exists
    const adminExists = await User.findOne({ email, role: 'admin' });
    if (adminExists) {
      return sendError(res, 'Admin user already exists', 400);
    }
    
    const admin = await User.create({
      fullName,
      email,
      password,
      phone,
      role: 'admin'
    });
    
    sendSuccess(res, {
      id: admin._id,
      fullName: admin.fullName,
      email: admin.email,
      role: admin.role
    }, 'Admin user created successfully', 201);
  } catch (error) {
    sendError(res, 'Failed to create admin user', 500, error.message);
  }
};

module.exports = {
  getStudents,
  getCourseStats,
  getPaymentStats,
  getExamStats,
  createAdmin,
  syncFirebaseUser,
  deleteUserSync,
  manualSyncAllUsers
};