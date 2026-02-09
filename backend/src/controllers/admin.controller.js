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
    // For admin dashboard, show all courses (both published and unpublished)
    const courses = await Course.find({});
    
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
        revenue: paymentCount * course.price,
        isPublished: course.isPublished,
        createdAt: course.createdAt
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
    console.log('Admin getPaymentStats called by user:', req.user?.id);
    
    const totalPayments = await Payment.countDocuments({ status: { $in: ['completed', 'approved'] } });
    const totalRevenue = await Payment.aggregate([
      { $match: { status: { $in: ['completed', 'approved'] } } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);
    
    const recentPayments = await Payment.find({ status: { $in: ['completed', 'approved'] } })
      .populate('userId', 'fullName email')
      .populate('courseId', 'title')
      .sort({ paymentDate: -1 })
      .limit(10);
    
    const responseData = {
      totalPayments,
      totalRevenue: totalRevenue[0]?.total || 0,
      recentPayments
    };
    
    console.log('Admin getPaymentStats response:', responseData);
    
    sendSuccess(res, responseData, 'Payment statistics retrieved successfully');
  } catch (error) {
    console.error('Error in admin getPaymentStats:', error);
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

// Get detailed student information including enrollments
const getStudentDetail = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Try to find user in Firebase first
    let user;
    let mongoUserId;
    
    try {
      const firebaseUser = await admin.auth().getUser(id);
      user = {
        _id: firebaseUser.uid,
        id: firebaseUser.uid,
        firebaseUid: firebaseUser.uid,
        fullName: firebaseUser.displayName || 'Unknown User',
        email: firebaseUser.email || 'No email',
        phone: firebaseUser.phoneNumber,
        role: firebaseUser.customClaims?.role || 'student',
        provider: firebaseUser.providerData[0]?.providerId || 'unknown',
        createdAt: firebaseUser.metadata.creationTime ? 
          new Date(firebaseUser.metadata.creationTime) : new Date(),
        lastLogin: firebaseUser.metadata.lastSignInTime ? 
          new Date(firebaseUser.metadata.lastSignInTime) : null,
        emailVerified: firebaseUser.emailVerified,
        disabled: firebaseUser.disabled
      };
      
      // Try to find the corresponding MongoDB user
      const mongoUser = await User.findOne({ firebaseUid: id });
      mongoUserId = mongoUser?._id;
      
    } catch (firebaseError) {
      console.log(`Firebase user ${id} not found, falling back to MongoDB:`, firebaseError.message);
      // Fallback to MongoDB
      const mongoUser = await User.findById(id).select('-password');
      if (!mongoUser) {
        return sendError(res, 'Student not found', 404);
      }
      
      user = {
        _id: mongoUser._id,
        id: mongoUser._id,
        firebaseUid: mongoUser.firebaseUid,
        fullName: mongoUser.fullName,
        email: mongoUser.email,
        phone: mongoUser.phone,
        role: mongoUser.role,
        provider: mongoUser.provider,
        createdAt: mongoUser.createdAt,
        lastLogin: mongoUser.lastLogin
      };
      
      mongoUserId = mongoUser._id;
    }
    
    // Get student's enrollments using the MongoDB user ID
    const enrollments = mongoUserId 
      ? await Enrollment.find({ userId: mongoUserId })
          .populate({
            path: 'courseId',
            select: 'title description price duration level thumbnail isPublished createdBy',
            populate: {
              path: 'createdBy',
              select: 'fullName'
            }
          })
          .sort({ enrollmentDate: -1 })
      : [];
    
    // Calculate statistics
    const totalEnrollments = enrollments.length;
    const completedCourses = enrollments.filter(e => e.completionStatus === 'completed').length;
    const inProgressCourses = enrollments.filter(e => e.completionStatus === 'in-progress').length;
    
    // Calculate total spent
    const payments = mongoUserId
      ? await Payment.find({ 
          userId: mongoUserId, 
          status: 'completed' 
        }).populate('courseId', 'price')
      : [];
    
    const totalSpent = payments.reduce((sum, payment) => {
      return sum + (payment.courseId?.price || 0);
    }, 0);
    
    // Get last active date (latest enrollment or login)
    const lastActive = user.lastLogin || 
      (enrollments.length > 0 ? enrollments[0].enrollmentDate : user.createdAt);
    
    sendSuccess(res, {
      user,
      enrollments,
      totalEnrollments,
      completedCourses,
      inProgressCourses,
      totalSpent,
      lastActive
    }, 'Student details retrieved successfully');
  } catch (error) {
    console.error('Error in getStudentDetail:', error);
    sendError(res, 'Failed to retrieve student details', 500, error.message);
  }
};

// Get student analytics data
const getStudentAnalytics = async (req, res) => {
  try {
    // Get total students from both Firebase and MongoDB
    const firebaseUsers = await admin.auth().listUsers();
    const mongoUsers = await User.countDocuments({ role: 'student' });
    
    // Count Firebase users excluding admins
    const firebaseStudentCount = firebaseUsers.users.filter(user => 
      user.customClaims?.role !== 'admin'
    ).length;
    
    const totalStudents = firebaseStudentCount + mongoUsers;
    
    // Get active students (those who logged in recently)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const activeStudents = await User.countDocuments({
      role: 'student',
      $or: [
        { lastLogin: { $gte: thirtyDaysAgo } },
        { createdAt: { $gte: thirtyDaysAgo } }
      ]
    });
    
    const inactiveStudents = totalStudents - activeStudents;
    
    // Get new students this month
    const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const newStudentsThisMonth = await User.countDocuments({
      role: 'student',
      createdAt: { $gte: startOfMonth }
    });
    
    // Calculate average enrollments per student
    const studentEnrollmentCounts = await Enrollment.aggregate([
      { $group: { _id: '$userId', count: { $sum: 1 } } }
    ]);
    
    const totalEnrollments = studentEnrollmentCounts.reduce((sum, item) => sum + item.count, 0);
    const averageEnrollmentsPerStudent = studentEnrollmentCounts.length > 0 
      ? totalEnrollments / studentEnrollmentCounts.length 
      : 0;
    
    // Get top performing students (most enrollments and completions)
    try {
      const topStudentsPipeline = [
        {
          $lookup: {
            from: 'users',
            localField: 'userId',
            foreignField: '_id',
            as: 'user'
          }
        },
        { $unwind: '$user' },
        {
          $group: {
            _id: '$userId',
            totalEnrollments: { $sum: 1 },
            completedCourses: {
              $sum: {
                $cond: [{ $eq: ['$completionStatus', 'completed'] }, 1, 0]
              }
            },
            averageProgress: { $avg: '$progress' },
            user: { $first: '$user' }
          }
        },
        {
          $lookup: {
            from: 'payments',
            localField: '_id',
            foreignField: 'userId',
            as: 'payments'
          }
        },
        {
          $addFields: {
            totalSpent: {
              $sum: {
                $map: {
                  input: '$payments',
                  as: 'payment',
                  in: {
                    $cond: [
                      { $eq: ['$$payment.status', 'completed'] },
                      { $ifNull: ['$$payment.amount', 0] },
                      0
                    ]
                  }
                }
              }
            }
          }
        },
        {
          $sort: {
            totalEnrollments: -1,
            completedCourses: -1,
            averageProgress: -1
          }
        },
        { $limit: 10 }
      ];
      
      const topPerformingStudents = await Enrollment.aggregate(topStudentsPipeline);
      
      // Format top students data
      var formattedTopStudents = topPerformingStudents.map(student => ({
        id: student._id,
        name: student.user?.fullName || 'Unknown User',
        email: student.user?.email || 'No email',
        totalEnrollments: student.totalEnrollments,
        completedCourses: student.completedCourses,
        averageProgress: student.averageProgress || 0,
        totalSpent: student.totalSpent || 0
      }));
    } catch (aggregateError) {
      console.log('Error in top students aggregation, using fallback:', aggregateError.message);
      formattedTopStudents = [];
    }
    
    // Get enrollment trends (last 30 days)
    try {
      const enrollmentTrends = await Enrollment.aggregate([
        {
          $match: {
            enrollmentDate: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
          }
        },
        {
          $group: {
            _id: {
              $dateToString: { format: '%Y-%m-%d', date: '$enrollmentDate' }
            },
            enrollments: { $sum: 1 },
            completions: {
              $sum: {
                $cond: [{ $eq: ['$completionStatus', 'completed'] }, 1, 0]
              }
            }
          }
        },
        { $sort: { '_id': 1 } }
      ]);
      
      // Format enrollment trends
      var formattedTrends = enrollmentTrends.map(trend => ({
        date: trend._id,
        enrollments: trend.enrollments,
        completions: trend.completions
      }));
    } catch (trendError) {
      console.log('Error in enrollment trends aggregation, using fallback:', trendError.message);
      formattedTrends = [];
    }
    
    // Get student activity stats
    const dailyActive = await User.countDocuments({
      role: 'student',
      lastLogin: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
    });
    
    const weeklyActive = await User.countDocuments({
      role: 'student',
      $or: [
        { lastLogin: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
        { createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } }
      ]
    });
    
    const monthlyActive = await User.countDocuments({
      role: 'student',
      $or: [
        { lastLogin: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } },
        { createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } }
      ]
    });
    
    // Calculate average session duration (simplified - would need actual session tracking)
    const avgSessionDuration = 45; // minutes - placeholder
    
    // Calculate total study hours (simplified)
    const totalStudyHours = Math.round((totalEnrollments * 2.5)); // hours - placeholder
    
    sendSuccess(res, {
      totalStudents,
      activeStudents,
      inactiveStudents,
      newStudentsThisMonth,
      averageEnrollmentsPerStudent,
      topPerformingStudents: formattedTopStudents,
      enrollmentTrends: formattedTrends,
      studentActivityStats: {
        dailyActiveStudents: dailyActive,
        weeklyActiveStudents: weeklyActive,
        monthlyActiveStudents: monthlyActive,
        avgSessionDuration,
        totalStudyHours
      }
    }, 'Student analytics retrieved successfully');
  } catch (error) {
    console.error('Error in getStudentAnalytics:', error);
    sendError(res, 'Failed to retrieve student analytics', 500, error.message);
  }
};

// Delete a student and all related data
const deleteStudent = async (req, res) => {
  try {
    const { id } = req.params;
    
    // First, try to find and delete from Firebase
    let firebaseDeleted = false;
    let mongoDeleted = false;
    let deletedUserData = null;
    
    try {
      // Try to delete from Firebase
      await admin.auth().deleteUser(id);
      firebaseDeleted = true;
      console.log(`Firebase user ${id} deleted successfully`);
    } catch (firebaseError) {
      console.log(`Firebase user ${id} not found or deletion failed:`, firebaseError.message);
      // Continue with MongoDB deletion
    }
    
    // Find the user in MongoDB to get complete data before deletion
    const mongoUser = await User.findOne({ 
      $or: [
        { _id: id },
        { firebaseUid: id }
      ]
    }).select('-password');
    
    if (mongoUser) {
      deletedUserData = {
        id: mongoUser._id,
        firebaseUid: mongoUser.firebaseUid,
        fullName: mongoUser.fullName,
        email: mongoUser.email,
        role: mongoUser.role,
        createdAt: mongoUser.createdAt
      };
      
      // Delete all related data in proper order to maintain referential integrity
      
      // 1. Delete enrollments
      const enrollmentCount = await Enrollment.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${enrollmentCount.deletedCount} enrollments for user ${id}`);
      
      // 2. Delete payments
      const paymentCount = await Payment.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${paymentCount.deletedCount} payments for user ${id}`);
      
      // 3. Delete exam results
      const resultCount = await Result.deleteMany({ userId: mongoUser._id });
      console.log(`Deleted ${resultCount.deletedCount} exam results for user ${id}`);
      
      // 4. Finally delete the user
      await User.findByIdAndDelete(mongoUser._id);
      mongoDeleted = true;
      console.log(`MongoDB user ${id} deleted successfully`);
    }
    
    if (!firebaseDeleted && !mongoDeleted) {
      return sendError(res, 'Student not found in either Firebase or MongoDB', 404);
    }
    
    sendSuccess(res, {
      id,
      firebaseDeleted,
      mongoDeleted,
      deletedUserData,
      message: `Student deleted successfully from ${firebaseDeleted ? 'Firebase' : ''}${firebaseDeleted && mongoDeleted ? ' and ' : ''}${mongoDeleted ? 'MongoDB' : ''}`
    }, 'Student deleted successfully');
  } catch (error) {
    console.error('Error in deleteStudent:', error);
    sendError(res, 'Failed to delete student', 500, error.message);
  }
};

module.exports = {
  getStudents,
  getStudentDetail,
  deleteStudent,
  getCourseStats,
  getPaymentStats,
  getExamStats,
  getStudentAnalytics,
  createAdmin,
  syncFirebaseUser,
  deleteUserSync,
  manualSyncAllUsers
};