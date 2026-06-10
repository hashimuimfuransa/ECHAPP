const LiveSession = require('../models/LiveSession');
const TeacherAssignment = require('../models/TeacherAssignment');
const Course = require('../models/Course');
const Section = require('../models/Section');
const Lesson = require('../models/Lesson');
const Enrollment = require('../models/Enrollment');
const User = require('../models/User');
const BBBService = require('../services/bbb.service');
const notificationController = require('./notification.controller');
const Notification = require('../models/Notification');
const { sendSuccess, sendError } = require('../utils/response.utils');

/**
 * Create a new live session with BBB meeting
 */
const createSession = async (req, res) => {
  try {
    const teacherId = req.user.id;
    const {
      courseId,
      sectionId,
      lessonId,
      title,
      description,
      scheduledAt,
      duration,
      maxParticipants,
      settings
    } = req.body;

    // Validate required fields
    if (!courseId || !sectionId || !title || !scheduledAt || !duration) {
      return sendError(res, 'Missing required fields: courseId, sectionId, title, scheduledAt, duration', 400);
    }

    // Verify teacher is assigned to this course
    const assignment = await TeacherAssignment.findOne({
      teacherId,
      courseId,
      isActive: true
    });

    if (!assignment) {
      return sendError(res, 'You are not assigned to teach this course', 403);
    }

    // Verify section and lesson exist and belong to course
    const section = await Section.findOne({ _id: sectionId, courseId });
    if (!section) {
      return sendError(res, 'Section not found or does not belong to this course', 404);
    }

    if (lessonId) {
      const lesson = await Lesson.findOne({ _id: lessonId, courseId, sectionId });
      if (!lesson) {
        return sendError(res, 'Lesson not found or does not belong to this section', 404);
      }
    }

    // Check if BBB is available
    const bbbAvailable = await BBBService.isAvailable();
    if (!bbbAvailable) {
      return sendError(res, 'BigBlueButton service is not available. Please try again later.', 503);
    }

    // Create BBB meeting
    const meetingId = `session_${Date.now()}_${teacherId.toString().slice(-6)}`;
    const bbbMeeting = await BBBService.createMeeting({
      name: title,
      meetingId: meetingId,
      duration: duration,
      maxParticipants: maxParticipants || 100,
      record: settings?.allowRecording !== false,
      muteOnStart: settings?.muteOnEntry !== false,
      welcomeMsg: description || `Welcome to ${title}`,
      meta: {
        courseId: courseId.toString(),
        teacherId: teacherId.toString(),
        sectionId: sectionId.toString(),
        lessonId: lessonId?.toString()
      }
    });

    // Create live session in database
    const scheduledDate = new Date(scheduledAt);
    const expectedEndTime = new Date(scheduledDate.getTime() + duration * 60000); // duration in minutes to milliseconds

    const liveSession = await LiveSession.create({
      teacherId,
      courseId,
      sectionId,
      lessonId,
      title,
      description,
      scheduledAt: scheduledDate,
      duration,
      expectedEndTime: expectedEndTime,
      maxParticipants: maxParticipants || 100,
      bbbMeetingId: bbbMeeting.meetingId,
      bbbInternalMeetingId: bbbMeeting.internalMeetingId,
      bbbModeratorPw: bbbMeeting.moderatorPw,
      bbbAttendeePw: bbbMeeting.attendeePw,
      settings: {
        enableChat: settings?.enableChat ?? true,
        enableWebcam: settings?.enableWebcam ?? true,
        muteOnEntry: settings?.muteOnEntry ?? true,
        allowRecording: settings?.allowRecording ?? true,
        waitingRoom: settings?.waitingRoom ?? false
      }
    });

    sendSuccess(res, {
      session: liveSession,
      bbb: {
        meetingId: bbbMeeting.meetingId,
        createTime: bbbMeeting.createTime
      }
    }, 'Live session created successfully', 201);
  } catch (error) {
    console.error('Create Live Session Error:', error);
    sendError(res, 'Failed to create live session', 500, error.message);
  }
};

/**
 * Get sessions for a teacher
 */
const getTeacherSessions = async (req, res) => {
  try {
    const teacherId = req.user.id;
    const { status, page = 1, limit = 20 } = req.query;

    const query = { teacherId };
    if (status) {
      query.status = status;
    }

    const sessions = await LiveSession.find(query)
      .populate('courseId', 'title thumbnail')
      .populate('sectionId', 'title')
      .populate('lessonId', 'title')
      .sort({ scheduledAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await LiveSession.countDocuments(query);

    // Add BBB URLs to each session
    const sessionsWithUrls = await Promise.all(sessions.map(async (session) => {
      const sessionObj = session.toObject();
      
      // Generate URLs if session has BBB meeting
      if (session.bbbMeetingId && session.status !== 'cancelled') {
        sessionObj.bbbModeratorUrl = await BBBService.getJoinUrl({
          fullName: req.user.fullName || 'Teacher',
          meetingId: session.bbbMeetingId,
          password: session.bbbModeratorPw || '',
          userId: teacherId,
          isModerator: true
        });
        
        sessionObj.bbbAttendeeUrl = null; // Only generated when student joins
      }
      
      return sessionObj;
    }));

    sendSuccess(res, {
      sessions: sessionsWithUrls,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Teacher sessions retrieved successfully');
  } catch (error) {
    console.error('Get Teacher Sessions Error:', error);
    sendError(res, 'Failed to retrieve sessions', 500, error.message);
  }
};

/**
 * Get sessions for a course (for students enrolled in the course)
 */
const getCourseSessions = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;
    const { status = 'scheduled', page = 1, limit = 20 } = req.query;

    // Check if user is enrolled in the course
    const enrollment = await Enrollment.findOne({ userId, courseId });
    if (!enrollment) {
      return sendError(res, 'You are not enrolled in this course', 403);
    }

    const query = { courseId };
    
    // For upcoming sessions, include both 'scheduled' and 'live' so active sessions surface
    if (status === 'scheduled') {
      query.status = { $in: ['scheduled', 'live'] };
      query.scheduledAt = { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }; // Include sessions from last 24h
    } else {
      query.status = status;
    }

    const sessions = await LiveSession.find(query)
      .populate('teacherId', 'fullName avatar')
      .populate('sectionId', 'title')
      .populate('lessonId', 'title')
      .sort({ scheduledAt: 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await LiveSession.countDocuments(query);

    // For students, only include necessary info (no moderator URLs)
    const sanitizedSessions = await Promise.all(sessions.map(async (session) => {
      const sessionObj = session.toObject();
      delete sessionObj.bbbModeratorUrl;
      delete sessionObj.bbbModeratorPw;
      
      // Generate attendee URL if session is live or scheduled and has BBB meeting
      if (session.bbbMeetingId && (session.status === 'scheduled' || session.status === 'live')) {
        sessionObj.joinUrl = await BBBService.getJoinUrl({
          fullName: req.user.fullName || 'Student',
          meetingId: session.bbbMeetingId,
          password: session.bbbAttendeePw || '',
          userId: userId,
          isModerator: false
        });
      }
      
      return sessionObj;
    }));

    sendSuccess(res, {
      sessions: sanitizedSessions,
      totalPages: Math.ceil(total / limit),
      currentPage: Number(page),
      total
    }, 'Course sessions retrieved successfully');
  } catch (error) {
    console.error('Get Course Sessions Error:', error);
    sendError(res, 'Failed to retrieve course sessions', 500, error.message);
  }
};

/**
 * Join a live session
 */
const joinSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    const session = await LiveSession.findById(sessionId)
      .populate('teacherId', 'fullName')
      .populate('courseId', 'title');

    if (!session) {
      return sendError(res, 'Session not found', 404);
    }

    // Check if session is cancelled
    if (session.status === 'cancelled') {
      return sendError(res, 'This session has been cancelled', 400);
    }

    // Get user info
    const user = await User.findById(userId).select('fullName');

    let joinUrl;
    let isModerator = false;

    // Teacher/Moderator join
    const teacherId = session.teacherId._id ? session.teacherId._id.toString() : session.teacherId.toString();
    if (userRole === 'instructor' && teacherId === userId) {
      isModerator = true;

      // Check if BBB meeting is still alive; re-create if it has expired on the BBB server
      const meetingInfo = await BBBService.getMeetingInfo(session.bbbMeetingId, session.bbbModeratorPw || '');
      if (!meetingInfo.success || !meetingInfo.isRunning) {
        console.log(`BBB meeting ${session.bbbMeetingId} is not running — re-creating for session ${sessionId}`);
        const newMeeting = await BBBService.createMeeting({
          name: session.title,
          meetingId: session.bbbMeetingId, // reuse same ID so existing join links stay consistent
          duration: session.duration,
          maxParticipants: session.maxParticipants || 100,
          record: session.settings?.allowRecording !== false,
          muteOnStart: session.settings?.muteOnEntry !== false,
          welcomeMsg: session.description || `Welcome to ${session.title}`,
          meta: {
            courseId: session.courseId._id ? session.courseId._id.toString() : session.courseId.toString(),
            teacherId: teacherId,
            sectionId: session.sectionId ? session.sectionId.toString() : ''
          }
        });
        // Persist any updated passwords returned by BBB
        session.bbbModeratorPw = newMeeting.moderatorPw || session.bbbModeratorPw;
        session.bbbAttendeePw = newMeeting.attendeePw || session.bbbAttendeePw;
        session.bbbInternalMeetingId = newMeeting.internalMeetingId || session.bbbInternalMeetingId;
      }

      joinUrl = await BBBService.getJoinUrl({
        fullName: user.fullName || 'Teacher',
        meetingId: session.bbbMeetingId,
        password: session.bbbModeratorPw || '',
        userId: userId,
        isModerator: true
      });

      // Update session status to live
      session.status = 'live';
      await session.save();
    } 
    // Student join
    else {
      // Check enrollment for students
      const enrollment = await Enrollment.findOne({ userId, courseId: session.courseId });
      if (!enrollment) {
        return sendError(res, 'You must be enrolled in this course to join', 403);
      }

      joinUrl = await BBBService.getJoinUrl({
        fullName: user.fullName || 'Student',
        meetingId: session.bbbMeetingId,
        password: session.bbbAttendeePw || '',
        userId: userId,
        isModerator: false
      });
    }

    sendSuccess(res, {
      joinUrl,
      isModerator,
      session: {
        id: session._id,
        title: session.title,
        status: session.status,
        courseName: session.courseId.title,
        scheduledAt: session.scheduledAt
      }
    }, 'Join URL generated successfully');
  } catch (error) {
    console.error('Join Session Error:', error);
    sendError(res, 'Failed to generate join URL', 500, error.message);
  }
};

/**
 * End a live session (teacher only)
 */
const endSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const teacherId = req.user.id;

    const session = await LiveSession.findOne({
      _id: sessionId,
      teacherId
    });

    if (!session) {
      return sendError(res, 'Session not found or you are not the teacher', 404);
    }

    if (session.status === 'ended' || session.status === 'cancelled') {
      return sendError(res, 'Session is already ended or cancelled', 400);
    }

    // End BBB meeting if it exists
    if (session.bbbMeetingId && session.bbbModeratorPw) {
      try {
        await BBBService.endMeeting(session.bbbMeetingId, session.bbbModeratorPw);
      } catch (bbbError) {
        console.warn('BBB End Meeting Warning:', bbbError.message);
        // Continue even if BBB end fails - meeting might have already ended
      }
    }

    // Update session status
    session.status = 'ended';
    session.endedAt = new Date();
    await session.save();

    // Notify enrolled students who missed the session (fire-and-forget)
    _notifyMissedSession(session, 'ended').catch(e =>
      console.warn('Missed-session notification error:', e.message)
    );

    // Try to get recording info
    try {
      const recordings = await BBBService.getRecordings(session.bbbMeetingId);
      if (recordings && recordings.length > 0) {
        const recording = recordings[0];
        session.recordingUrl = recording.playback;
        session.recordingDuration = recording.duration;
        session.recordingFormat = recording.playbackType || 'video';
        await session.save();
      }
    } catch (recError) {
      console.warn('Get Recording Warning:', recError.message);
    }

    sendSuccess(res, {
      session: {
        id: session._id,
        status: session.status,
        endedAt: session.endedAt,
        recordingUrl: session.recordingUrl
      }
    }, 'Session ended successfully');
  } catch (error) {
    console.error('End Session Error:', error);
    sendError(res, 'Failed to end session', 500, error.message);
  }
};

/**
 * Cancel a scheduled session (teacher only)
 */
const cancelSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const teacherId = req.user.id;

    const session = await LiveSession.findOne({
      _id: sessionId,
      teacherId
    });

    if (!session) {
      return sendError(res, 'Session not found or you are not the teacher', 404);
    }

    if (session.status !== 'scheduled') {
      return sendError(res, 'Only scheduled sessions can be cancelled', 400);
    }

    session.status = 'cancelled';
    await session.save();

    // Notify enrolled students that the session was cancelled (fire-and-forget)
    _notifyMissedSession(session, 'cancelled').catch(e =>
      console.warn('Cancelled-session notification error:', e.message)
    );

    sendSuccess(res, {
      session: {
        id: session._id,
        status: session.status
      }
    }, 'Session cancelled successfully');
  } catch (error) {
    console.error('Cancel Session Error:', error);
    sendError(res, 'Failed to cancel session', 500, error.message);
  }
};

/**
 * Delete a session (teacher only) - works for any status
 */
const deleteSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const teacherId = req.user.id;

    const session = await LiveSession.findOne({
      _id: sessionId,
      teacherId
    });

    if (!session) {
      return sendError(res, 'Session not found or you are not the teacher', 404);
    }

    // If session is live, end the BBB meeting first
    if (session.status === 'live' && session.bbbMeetingId && session.bbbModeratorPw) {
      try {
        await BBBService.endMeeting(session.bbbMeetingId, session.bbbModeratorPw);
      } catch (bbbError) {
        console.warn('BBB End Meeting Warning (session delete):', bbbError.message);
        // Continue even if BBB end fails
      }
    }

    // Delete the session from database
    await LiveSession.deleteOne({ _id: sessionId, teacherId });

    sendSuccess(res, {
      deleted: true,
      sessionId: sessionId
    }, 'Session deleted successfully');
  } catch (error) {
    console.error('Delete Session Error:', error);
    sendError(res, 'Failed to delete session', 500, error.message);
  }
};

/**
 * Get session recordings
 */
const getSessionRecordings = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    const session = await LiveSession.findById(sessionId)
      .populate('courseId', 'title');

    if (!session) {
      return sendError(res, 'Session not found', 404);
    }

    // Check permissions
    if (userRole !== 'instructor' || session.teacherId.toString() !== userId) {
      const enrollment = await Enrollment.findOne({ userId, courseId: session.courseId });
      if (!enrollment) {
        return sendError(res, 'You do not have access to this recording', 403);
      }
    }

    // If we already have recording URL stored, return it
    if (session.recordingUrl) {
      return sendSuccess(res, {
        recordingUrl: session.recordingUrl,
        duration: session.recordingDuration,
        format: session.recordingFormat,
        sessionTitle: session.title
      }, 'Recording retrieved successfully');
    }

    // Otherwise, try to fetch from BBB
    try {
      const recordings = await BBBService.getRecordings(session.bbbMeetingId);
      
      if (recordings && recordings.length > 0) {
        const recording = recordings[0];
        
        // Update session with recording info
        session.recordingUrl = recording.playback;
        session.recordingDuration = recording.duration;
        session.recordingFormat = recording.playbackType || 'video';
        await session.save();

        return sendSuccess(res, {
          recordingUrl: recording.playback,
          duration: recording.duration,
          format: recording.playbackType || 'video',
          sessionTitle: session.title
        }, 'Recording retrieved successfully');
      } else {
        return sendError(res, 'Recording not available yet. Please check back later.', 404);
      }
    } catch (error) {
      console.error('Get Recording Error:', error);
      return sendError(res, 'Failed to retrieve recording', 500, error.message);
    }
  } catch (error) {
    console.error('Get Session Recordings Error:', error);
    sendError(res, 'Failed to retrieve recordings', 500, error.message);
  }
};

/**
 * Get session attendance details
 */
const getSessionAttendance = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    const session = await LiveSession.findById(sessionId)
      .populate('teacherId', 'fullName email')
      .populate('courseId', 'title')
      .populate('sectionId', 'title')
      .populate('attendedAt.userId', 'fullName email avatar');

    if (!session) {
      return sendError(res, 'Session not found', 404);
    }

    // Check access - only teacher of this session or admin can view attendance
    const sessionTeacherId = session.teacherId._id ? session.teacherId._id.toString() : session.teacherId.toString();
    if (userRole !== 'admin' && sessionTeacherId !== userId) {
      return sendError(res, 'You do not have permission to view this session attendance', 403);
    }

    // Get all enrolled students for this course
    const Enrollment = require('../models/Enrollment');
    const enrolledStudents = await Enrollment.find({ courseId: session.courseId._id })
      .populate('userId', 'fullName email avatar')
      .sort({ 'userId.fullName': 1 });

    // Get attended student IDs from attendedAt array
    const attendedStudentIds = (session.attendedAt || [])
      .filter(a => a.userId != null) // Filter out null userIds
      .map(a => {
        return a.userId._id ? a.userId._id.toString() : a.userId.toString();
      });

    // Separate attended and not attended students
    const attendedStudents = enrolledStudents.filter(e => {
      if (!e.userId) return false; // Skip if userId is null
      const studentId = e.userId._id ? e.userId._id.toString() : e.userId.toString();
      return attendedStudentIds.includes(studentId);
    });

    const notAttendedStudents = enrolledStudents.filter(e => {
      if (!e.userId) return true; // Count as not attended if userId is null
      const studentId = e.userId._id ? e.userId._id.toString() : e.userId.toString();
      return !attendedStudentIds.includes(studentId);
    });

    // Add attendance details to attended students
    const attendedWithDetails = attendedStudents.map(e => {
      const studentId = e.userId._id ? e.userId._id.toString() : e.userId.toString();
      const attendanceRecord = (session.attendedAt || [])
        .filter(a => a.userId != null) // Filter out null userIds
        .find(a => {
          const recordUserId = a.userId._id ? a.userId._id.toString() : a.userId.toString();
          return recordUserId === studentId;
        });
      return {
        student: e.userId,
        joinedAt: attendanceRecord?.joinedAt,
        duration: attendanceRecord?.duration || 0
      };
    });

    sendSuccess(res, {
      session: {
        id: session._id,
        title: session.title,
        scheduledAt: session.scheduledAt,
        expectedEndTime: session.expectedEndTime,
        status: session.status,
        course: session.courseId,
        section: session.sectionId,
        teacher: session.teacherId
      },
      totalEnrolled: enrolledStudents.length,
      totalAttended: attendedStudents.length,
      attendedStudents: attendedWithDetails,
      notAttendedStudents: notAttendedStudents.map(e => e.userId),
      attendanceRate: enrolledStudents.length > 0 
        ? Math.round((attendedStudents.length / enrolledStudents.length) * 100) 
        : 0
    }, 'Session attendance retrieved successfully');
  } catch (error) {
    console.error('Get Session Attendance Error:', error);
    sendError(res, 'Failed to retrieve session attendance', 500, error.message);
  }
};

/**
 * Get live sessions for a specific lesson
 */
const getLessonSessions = async (req, res) => {
  try {
    const { lessonId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    const lesson = await Lesson.findById(lessonId);
    if (!lesson) {
      return sendError(res, 'Lesson not found', 404);
    }

    // Check access
    if (userRole !== 'instructor') {
      const enrollment = await Enrollment.findOne({ userId, courseId: lesson.courseId });
      if (!enrollment) {
        return sendError(res, 'You do not have access to this lesson', 403);
      }
    }

    const sessions = await LiveSession.find({
      lessonId,
      status: { $in: ['scheduled', 'live', 'ended'] }
    })
      .populate('teacherId', 'fullName avatar')
      .populate('sectionId', 'title')
      .sort({ scheduledAt: -1 });

    // Sanitize based on user role
    const sanitizedSessions = await Promise.all(sessions.map(async (session) => {
      const sessionObj = session.toObject();
      
      // Handle populated teacherId
      const sessionTeacherId = session.teacherId._id ? session.teacherId._id.toString() : session.teacherId.toString();
      
      // Only teachers see moderator info
      if (userRole !== 'instructor' || sessionTeacherId !== userId) {
        delete sessionObj.bbbModeratorUrl;
        delete sessionObj.bbbModeratorPw;
        
        // Add attendee join URL for scheduled/live sessions
        if ((session.status === 'scheduled' || session.status === 'live') && session.bbbMeetingId) {
          sessionObj.joinUrl = await BBBService.getJoinUrl({
            fullName: req.user.fullName || 'Student',
            meetingId: session.bbbMeetingId,
            password: session.bbbAttendeePw || '',
            userId: userId,
            isModerator: false
          });
        }
      }
      
      return sessionObj;
    }));

    sendSuccess(res, {
      sessions: sanitizedSessions
    }, 'Lesson sessions retrieved successfully');
  } catch (error) {
    console.error('Get Lesson Sessions Error:', error);
    sendError(res, 'Failed to retrieve lesson sessions', 500, error.message);
  }
};

/**
 * Internal helper: notify enrolled students about a missed or cancelled session.
 * @param {Object} session - LiveSession mongoose document
 * @param {'ended'|'cancelled'} reason
 */
async function _notifyMissedSession(session, reason) {
  const courseId = session.courseId._id
    ? session.courseId._id.toString()
    : session.courseId.toString();

  // All students enrolled in this course
  const enrollments = await Enrollment.find({ courseId }).select('userId');
  if (!enrollments.length) return;

  const courseTitle = session.courseId.title || 'your course';
  const sessionTitle = session.title;

  for (const enrollment of enrollments) {
    const userId = enrollment.userId.toString();
    try {
      if (reason === 'ended') {
        const title = `You missed a live session 📺`;
        const message = `"${sessionTitle}" from ${courseTitle} has ended. Check the course for recordings or upcoming sessions.`;
        await notificationController.sendPushNotification(
          userId, title, message,
          { route: '/my-courses', type: 'missed_session' },
          true
        );
        await Notification.createNotification({
          userId,
          title,
          message,
          type: 'missed_session',
          data: { relatedId: session._id.toString(), relatedModel: 'LiveSession' }
        });
      } else if (reason === 'cancelled') {
        const title = `Live session cancelled`;
        const message = `"${sessionTitle}" from ${courseTitle} has been cancelled. Check the course for rescheduled sessions.`;
        await notificationController.sendPushNotification(
          userId, title, message,
          { route: '/my-courses', type: 'session_cancelled' },
          true
        );
        await Notification.createNotification({
          userId,
          title,
          message,
          type: 'session_cancelled',
          data: { relatedId: session._id.toString(), relatedModel: 'LiveSession' }
        });
      }
    } catch (err) {
      console.warn(`Failed to notify user ${userId}:`, err.message);
    }
  }
}

module.exports = {
  createSession,
  getTeacherSessions,
  getCourseSessions,
  getSessionAttendance,
  joinSession,
  endSession,
  cancelSession,
  deleteSession,
  getSessionRecordings,
  getLessonSessions
};
