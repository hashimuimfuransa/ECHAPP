const Section = require('../models/Section');
const Lesson = require('../models/Lesson');
const Enrollment = require('../models/Enrollment');
const Quiz = require('../models/Quiz');
const Result = require('../models/Result');
const LiveSession = require('../models/LiveSession');

/**
 * Build a full chapter/lesson completion breakdown for one student in one course.
 * Returns null if the student is not enrolled in the course.
 */
const getStudentCourseProgress = async (courseId, studentId) => {
  const enrollment = await Enrollment.findOne({ userId: studentId, courseId })
    .populate('userId', 'fullName email phone avatar');

  if (!enrollment) {
    return null;
  }

  // Result has no courseId field - quiz results are linked via examId -> Quiz.courseId
  const courseQuizzes = await Quiz.find({ courseId }).select('_id');
  const quizIds = courseQuizzes.map((q) => q._id);

  const quizResults = await Result.find({
    userId: studentId,
    examId: { $in: quizIds }
  })
    .populate('examId', 'title sectionId type passingScore')
    .sort({ submittedAt: -1 });

  const sections = await Section.find({ courseId }).sort({ order: 1 });
  const lessons = await Lesson.find({ courseId }).sort({ order: 1 });
  const completedLessonIds = new Set((enrollment.completedLessons || []).map((id) => id.toString()));

  const sectionProgress = sections.map((section) => {
    const sectionLessons = lessons.filter((l) => l.sectionId.toString() === section._id.toString());
    const lessonsDetail = sectionLessons.map((l) => ({
      lessonId: l._id,
      title: l.title,
      order: l.order,
      completed: completedLessonIds.has(l._id.toString())
    }));
    const completedCount = lessonsDetail.filter((l) => l.completed).length;

    return {
      sectionId: section._id,
      sectionTitle: section.title,
      order: section.order,
      totalLessons: sectionLessons.length,
      completedLessons: completedCount,
      progress: sectionLessons.length > 0
        ? Math.round((completedCount / sectionLessons.length) * 100)
        : 0,
      lessons: lessonsDetail
    };
  });

  const completedLessons = lessons
    .filter((l) => completedLessonIds.has(l._id.toString()))
    .map((l) => ({ lessonId: l._id, title: l.title, sectionId: l.sectionId }));

  const courseSessions = await LiveSession.find({ courseId, status: 'ended' })
    .select('_id title scheduledAt');

  return {
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
      passedQuizzes: quizResults.filter((r) => r.passed).length
    },
    sectionProgress,
    quizHistory: quizResults.map((r) => ({
      quizId: r.examId?._id,
      quizTitle: r.examId?.title,
      score: r.score,
      passed: r.passed,
      submittedAt: r.submittedAt,
      timeSpent: r.timeSpent
    })),
    completedLessons,
    availableSessions: courseSessions
  };
};

module.exports = { getStudentCourseProgress };
