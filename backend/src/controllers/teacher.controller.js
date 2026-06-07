const TeacherAssignment = require('../models/TeacherAssignment');
const Course = require('../models/Course');
const Section = require('../models/Section');
const Lesson = require('../models/Lesson');
const Enrollment = require('../models/Enrollment');
const User = require('../models/User');
const Quiz = require('../models/Quiz');
const Result = require('../models/Result');
const { sendSuccess, sendError } = require('../utils/response.utils');

/**
 * Get all courses assigned to the current teacher
 */
const getAssignedCourses = async (req, res) => {
  try {
    const teacherId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    // Find active assignments
    const assignments = await TeacherAssignment.find({
      teacherId,
      isActive: true
    })
      .populate({
        path: 'courseId',
        populate: { path: 'category', select: 'name' }
      })
      .sort({ assignedAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    // Get enrollment counts for each course
    const coursesWithStats = await Promise.all(
      assignments.map(async (assignment) => {
        const course = assignment.courseId;
        if (!course) return null;

        const enrollmentCount = await Enrollment.countDocuments({ courseId: course._id });
        const activeStudents = await Enrollment.countDocuments({
          courseId: course._id,
          completionStatus: { $in: ['enrolled', 'in-progress'] }
        });
        const completedStudents = await Enrollment.countDocuments({
          courseId: course._id,
          completionStatus: 'completed'
        });

        // Get upcoming live sessions count
        const LiveSession = require('../models/LiveSession');
        const upcomingSessions = await LiveSession.countDocuments({
          courseId: course._id,
          teacherId,
          status: 'scheduled',
          scheduledAt: { $gte: new Date() }
        });

        return {
          assignmentId: assignment._id,
          assignedAt: assignment.assignedAt,
          notes: assignment.notes,
          course: {
            id: course._id,
            title: course.title,
            description: course.description,
            thumbnail: course.thumbnail,
            level: course.level,
            price: course.price,
            isPublished: course.isPublished,
            category: course.category,
            enrollmentCount,
            activeStudents,
            completedStudents,
            upcomingSessions
          }
        };
      })
    );

    // Filter out null entries (deleted courses)
    const validCourses = coursesWithStats.filter(c => c !== null);
    const total = await TeacherAssignment.countDocuments({ teacherId, isActive: true });

    sendSuccess(res, {
      courses: validCourses,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Assigned courses retrieved successfully');
  } catch (error) {
    console.error('Get Assigned Courses Error:', error);
    sendError(res, 'Failed to retrieve assigned courses', 500, error.message);
  }
};

/**
 * Get detailed content of a course (sections and lessons)
 */
const getCourseContent = async (req, res) => {
  try {
    const teacherId = req.user.id;
    const { courseId } = req.params;

    // Verify teacher is assigned to this course
    const assignment = await TeacherAssignment.findOne({
      teacherId,
      courseId,
      isActive: true
    });

    if (!assignment) {
      return sendError(res, 'You are not assigned to teach this course', 403);
    }

    // Get course details
    const course = await Course.findById(courseId)
      .populate('category', 'name')
      .select('-__v');

    if (!course) {
      return sendError(res, 'Course not found', 404);
    }

    // Get sections with lessons
    const sections = await Section.find({ courseId }).sort({ order: 1 });
    
    const sectionsWithLessons = await Promise.all(
      sections.map(async (section) => {
        const lessons = await Lesson.find({ sectionId: section._id })
          .sort({ order: 1 })
          .select('-__v');

        // Get live sessions count per lesson
        const LiveSession = require('../models/LiveSession');
        const lessonsWithSessions = await Promise.all(
          lessons.map(async (lesson) => {
            const sessionCount = await LiveSession.countDocuments({
              lessonId: lesson._id,
              status: { $in: ['scheduled', 'live', 'ended'] }
            });
            
            const hasRecording = await LiveSession.exists({
              lessonId: lesson._id,
              status: 'ended',
              recordingUrl: { $ne: null }
            });

            return {
              ...lesson.toObject(),
              liveSessionCount: sessionCount,
              hasRecording: !!hasRecording
            };
          })
        );

        return {
          ...section.toObject(),
          lessons: lessonsWithSessions
        };
      })
    );

    // Get enrollment stats
    const enrollmentStats = await Enrollment.aggregate([
      { $match: { courseId: course._id } },
      {
        $group: {
          _id: '$completionStatus',
          count: { $sum: 1 },
          avgProgress: { $avg: '$progress' }
        }
      }
    ]);

    const stats = {
      totalEnrolled: await Enrollment.countDocuments({ courseId }),
      inProgress: enrollmentStats.find(s => s._id === 'in-progress')?.count || 0,
      completed: enrollmentStats.find(s => s._id === 'completed')?.count || 0,
      averageProgress: enrollmentStats.length > 0 
        ? Math.round(enrollmentStats.reduce((acc, s) => acc + (s.avgProgress || 0), 0) / enrollmentStats.length)
        : 0
    };

    sendSuccess(res, {
      course: {
        ...course.toObject(),
        stats
      },
      sections: sectionsWithLessons
    }, 'Course content retrieved successfully');
  } catch (error) {
    console.error('Get Course Content Error:', error);
    sendError(res, 'Failed to retrieve course content', 500, error.message);
  }
};

/**
 * Get all students enrolled in a specific course
 */
const getCourseStudents = async (req, res) => {
  try {
    const teacherId = req.user.id;
    const { courseId } = req.params;
    const { status, page = 1, limit = 20, search } = req.query;

    // Verify teacher is assigned to this course
    const assignment = await TeacherAssignment.findOne({
      teacherId,
      courseId,
      isActive: true
    });

    if (!assignment) {
      return sendError(res, 'You are not assigned to teach this course', 403);
    }

    // Build enrollment query
    const enrollmentQuery = { courseId };
    if (status) {
      enrollmentQuery.completionStatus = status;
    }

    // Get enrollments with user details
    let enrollmentsQuery = Enrollment.find(enrollmentQuery)
      .populate({
        path: 'userId',
        select: 'fullName email phone avatar lastActive isActive'
      })
      .sort({ enrollmentDate: -1 });

    // Apply search if provided
    if (search) {
      const users = await User.find({
        $or: [
          { fullName: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } }
        ]
      }).select('_id');
      
      enrollmentQuery.userId = { $in: users.map(u => u._id) };
      enrollmentsQuery = Enrollment.find(enrollmentQuery)
        .populate({
          path: 'userId',
          select: 'fullName email phone avatar lastActive isActive'
        })
        .sort({ enrollmentDate: -1 });
    }

    const enrollments = await enrollmentsQuery
      .limit(limit * 1)
      .skip((page - 1) * limit);

    // Get student performance data
    const studentsWithPerformance = await Promise.all(
      enrollments.map(async (enrollment) => {
        if (!enrollment.userId) return null;

        // Get quiz results for this course
        const quizResults = await Result.find({
          userId: enrollment.userId._id,
          courseId
        }).populate('quizId', 'title').sort({ submittedAt: -1 });

        // Calculate average score
        const avgScore = quizResults.length > 0
          ? quizResults.reduce((acc, r) => acc + (r.score || 0), 0) / quizResults.length
          : 0;

        // Get completed lessons count
        const completedLessonsCount = enrollment.completedLessons?.length || 0;
        
        // Get total lessons count for the course
        const totalLessons = await Lesson.countDocuments({ courseId });

        return {
          enrollmentId: enrollment._id,
          enrollmentDate: enrollment.enrollmentDate,
          completionStatus: enrollment.completionStatus,
          progress: enrollment.progress,
          certificateEligible: enrollment.certificateEligible,
          completedLessonsCount,
          totalLessons,
          quizAttempts: quizResults.length,
          averageQuizScore: Math.round(avgScore * 100) / 100,
          lastActivity: enrollment.userId.lastActive,
          student: {
            id: enrollment.userId._id,
            fullName: enrollment.userId.fullName,
            email: enrollment.userId.email,
            phone: enrollment.userId.phone,
            avatar: enrollment.userId.avatar,
            isActive: enrollment.userId.isActive
          }
        };
      })
    );

    // Filter out null entries
    const validStudents = studentsWithPerformance.filter(s => s !== null);
    const total = await Enrollment.countDocuments(enrollmentQuery);

    sendSuccess(res, {
      students: validStudents,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Course students retrieved successfully');
  } catch (error) {
    console.error('Get Course Students Error:', error);
    sendError(res, 'Failed to retrieve course students', 500, error.message);
  }
};

/**
 * Get detailed performance data for a specific student in a course
 */
const getStudentPerformance = async (req, res) => {
  try {
    const teacherId = req.user.id;
    const { courseId, studentId } = req.params;

    // Verify teacher is assigned to this course
    const assignment = await TeacherAssignment.findOne({
      teacherId,
      courseId,
      isActive: true
    });

    if (!assignment) {
      return sendError(res, 'You are not assigned to teach this course', 403);
    }

    // Get enrollment
    const enrollment = await Enrollment.findOne({
      userId: studentId,
      courseId
    }).populate('userId', 'fullName email phone avatar');

    if (!enrollment) {
      return sendError(res, 'Student not enrolled in this course', 404);
    }

    // Get all quiz results for this student in this course
    const quizResults = await Result.find({
      userId: studentId,
      courseId
    })
      .populate('quizId', 'title sectionId type passingScore')
      .sort({ submittedAt: -1 });

    // Get completed lessons details
    const completedLessons = await Lesson.find({
      _id: { $in: enrollment.completedLessons || [] }
    }).select('title sectionId order');

    // Get course sections for progress breakdown
    const sections = await Section.find({ courseId }).sort({ order: 1 });
    const lessons = await Lesson.find({ courseId }).sort({ order: 1 });

    // Calculate section-wise progress
    const sectionProgress = sections.map(section => {
      const sectionLessons = lessons.filter(l => l.sectionId.toString() === section._id.toString());
      const completedSectionLessons = enrollment.completedLessons?.filter(
        cl => sectionLessons.some(sl => sl._id.toString() === cl.toString())
      ).length || 0;
      
      return {
        sectionId: section._id,
        sectionTitle: section.title,
        totalLessons: sectionLessons.length,
        completedLessons: completedSectionLessons,
        progress: sectionLessons.length > 0 
          ? Math.round((completedSectionLessons / sectionLessons.length) * 100) 
          : 0
      };
    });

    // Get live session participation
    const LiveSession = require('../models/LiveSession');
    const courseSessions = await LiveSession.find({
      courseId,
      status: 'ended'
    }).select('_id title scheduledAt');

    sendSuccess(res, {
      student: {
        id: enrollment.userId._id,
        fullName: enrollment.userId.fullName,
        email: enrollment.userId.email,
        phone: enrollment.userId.phone,
        avatar: enrollment.userId.avatar
      },
      enrollment: {
        enrollmentDate: enrollment.enrollmentDate,
        completionStatus: enrollment.completionStatus,
        progress: enrollment.progress,
        certificateEligible: enrollment.certificateEligible
      },
      overallStats: {
        totalLessons: lessons.length,
        completedLessons: enrollment.completedLessons?.length || 0,
        overallProgress: enrollment.progress,
        quizAttempts: quizResults.length,
        averageQuizScore: quizResults.length > 0
          ? Math.round((quizResults.reduce((acc, r) => acc + (r.score || 0), 0) / quizResults.length) * 100) / 100
          : 0,
        passedQuizzes: quizResults.filter(r => r.passed).length
      },
      sectionProgress,
      quizHistory: quizResults.map(r => ({
        quizId: r.quizId?._id,
        quizTitle: r.quizId?.title,
        score: r.score,
        passed: r.passed,
        submittedAt: r.submittedAt,
        timeSpent: r.timeSpent
      })),
      completedLessons: completedLessons.map(l => ({
        lessonId: l._id,
        title: l.title,
        sectionId: l.sectionId
      })),
      availableSessions: courseSessions
    }, 'Student performance retrieved successfully');
  } catch (error) {
    console.error('Get Student Performance Error:', error);
    sendError(res, 'Failed to retrieve student performance', 500, error.message);
  }
};

/**
 * Get teacher dashboard statistics
 */
const getDashboardStats = async (req, res) => {
  try {
    const teacherId = req.user.id;

    // Get all active assignments
    const assignments = await TeacherAssignment.find({
      teacherId,
      isActive: true
    });

    const courseIds = assignments.map(a => a.courseId);

    // Calculate stats
    const totalCourses = assignments.length;
    
    const totalStudents = await Enrollment.countDocuments({
      courseId: { $in: courseIds }
    });

    const activeStudents = await Enrollment.countDocuments({
      courseId: { $in: courseIds },
      completionStatus: { $in: ['enrolled', 'in-progress'] }
    });

    // Get live session stats
    const LiveSession = require('../models/LiveSession');
    
    const upcomingSessions = await LiveSession.countDocuments({
      teacherId,
      status: 'scheduled',
      scheduledAt: { $gte: new Date() }
    });

    const totalSessions = await LiveSession.countDocuments({
      teacherId,
      status: { $in: ['live', 'ended'] }
    });

    const recentSessions = await LiveSession.find({
      teacherId,
      status: { $in: ['scheduled', 'live'] }
    })
      .populate('courseId', 'title')
      .sort({ scheduledAt: 1 })
      .limit(5);

    // Calculate total teaching hours from ended sessions
    const teachingHoursData = await LiveSession.aggregate([
      { $match: { teacherId: require('mongoose').Types.ObjectId(teacherId), status: 'ended' } },
      {
        $group: {
          _id: null,
          totalMinutes: { $sum: '$duration' },
          sessionCount: { $sum: 1 }
        }
      }
    ]);

    const totalTeachingHours = teachingHoursData.length > 0 
      ? Math.round(teachingHoursData[0].totalMinutes / 60 * 10) / 10 
      : 0;

    sendSuccess(res, {
      overview: {
        totalCourses,
        totalStudents,
        activeStudents,
        upcomingSessions,
        totalSessionsConducted: totalSessions,
        totalTeachingHours
      },
      recentSessions: recentSessions.map(s => ({
        id: s._id,
        title: s.title,
        courseName: s.courseId?.title,
        scheduledAt: s.scheduledAt,
        status: s.status,
        duration: s.duration
      })),
      courseIds // For quick reference
    }, 'Teacher dashboard stats retrieved successfully');
  } catch (error) {
    console.error('Get Teacher Dashboard Stats Error:', error);
    sendError(res, 'Failed to retrieve dashboard stats', 500, error.message);
  }
};

module.exports = {
  getAssignedCourses,
  getCourseContent,
  getCourseStudents,
  getStudentPerformance,
  getDashboardStats
};
