const mongoose = require('mongoose');
const User = require('../../models/User');
const Enrollment = require('../../models/Enrollment');
const CoursePresence = require('../../models/community/CoursePresence');
const CommunityPost = require('../../models/community/CommunityPost');
const StudyGroup = require('../../models/community/StudyGroup');
const CommunityAssignment = require('../../models/community/CommunityAssignment');
const CommunitySubmission = require('../../models/community/CommunitySubmission');
const StudySession = require('../../models/community/StudySession');
const StudyPartnerProfile = require('../../models/community/StudyPartnerProfile');
const CommunityMessage = require('../../models/community/CommunityMessage');
const { sendSuccess, sendError, sendNotFound } = require('../../utils/response.utils');
const {
  PUBLIC_USER_FIELDS,
  getStudentIds,
  getTeacherIds,
  getPresenceMap,
  toPublicMember
} = require('../../utils/community.utils');

class CommunityController {
  /**
   * Everything the Community dashboard needs in a single round trip:
   * headline counts, who is studying now, my groups, latest discussions,
   * open assignments and the next study session.
   */
  async getOverview(req, res) {
    try {
      const { courseId, course, userId, role, isTeacher } = req.community;

      const [studentIds, teacherIds] = await Promise.all([
        getStudentIds(courseId),
        getTeacherIds(courseId)
      ]);

      const activeCutoff = new Date(
        Date.now() - CoursePresence.ACTIVE_WINDOW_MINUTES * 60 * 1000
      );

      const [
        activeRows,
        teachers,
        myGroups,
        recentPosts,
        pinnedPosts,
        openAssignments,
        nextSession,
        unreadCourseChat
      ] = await Promise.all([
        CoursePresence.find({
          courseId,
          isVisible: true,
          lastSeenAt: { $gte: activeCutoff }
        })
          .sort({ lastSeenAt: -1 })
          .limit(12)
          .populate('userId', PUBLIC_USER_FIELDS)
          .lean(),

        User.find({ _id: { $in: teacherIds } }).select(PUBLIC_USER_FIELDS).lean(),

        StudyGroup.find({
          courseId,
          isArchived: false,
          members: { $elemMatch: { userId, status: 'active' } }
        })
          .sort({ lastActivityAt: -1 })
          .limit(5)
          .lean(),

        CommunityPost.find({ courseId, type: { $in: ['discussion', 'question'] } })
          .sort({ lastActivityAt: -1 })
          .limit(5)
          .populate('authorId', PUBLIC_USER_FIELDS)
          .lean(),

        CommunityPost.find({ courseId, isPinned: true })
          .sort({ lastActivityAt: -1 })
          .limit(3)
          .populate('authorId', PUBLIC_USER_FIELDS)
          .lean(),

        CommunityAssignment.find({
          courseId,
          isPublished: true,
          dueDate: { $gte: new Date() }
        })
          .sort({ dueDate: 1 })
          .limit(5)
          .lean(),

        StudySession.findOne({
          courseId,
          status: 'scheduled',
          scheduledAt: { $gte: new Date() }
        })
          .sort({ scheduledAt: 1 })
          .lean(),

        CommunityMessage.countDocuments({
          courseId,
          scope: 'course',
          isDeleted: false,
          senderId: { $ne: userId },
          readBy: { $ne: userId }
        })
      ]);

      // Pending items differ by role: teachers care about ungraded submissions,
      // students about assignments they have not submitted yet.
      let pendingSubmissions = 0;
      if (isTeacher) {
        pendingSubmissions = await CommunitySubmission.countDocuments({
          courseId,
          status: { $in: ['submitted', 'under_review'] }
        });
      } else {
        const submitted = await CommunitySubmission.find({
          courseId,
          members: userId
        })
          .select('assignmentId')
          .lean();
        const submittedIds = new Set(submitted.map((s) => String(s.assignmentId)));
        pendingSubmissions = openAssignments.filter(
          (a) => !submittedIds.has(String(a._id))
        ).length;
      }

      const activeMembers = activeRows
        .filter((row) => row.userId && String(row.userId._id) !== String(userId))
        .map((row) =>
          toPublicMember(row.userId, {
            status: 'active',
            lastSeenAt: row.lastSeenAt,
            minutesAgo: Math.max(
              0,
              Math.floor((Date.now() - new Date(row.lastSeenAt).getTime()) / 60000)
            )
          })
        );

      const mapPost = (p) => ({
        id: String(p._id),
        type: p.type,
        title: p.title,
        content: p.content,
        author: toPublicMember(p.authorId),
        authorRole: p.authorRole,
        replyCount: p.replies ? p.replies.length : 0,
        likeCount: p.likes ? p.likes.length : 0,
        isPinned: p.isPinned,
        isResolved: p.isResolved,
        hasTeacherAnswer: (p.replies || []).some(
          (r) => r.authorRole === 'instructor' || r.authorRole === 'admin'
        ),
        createdAt: p.createdAt,
        lastActivityAt: p.lastActivityAt
      });

      return sendSuccess(res, {
        course: {
          id: String(course._id),
          title: course.title,
          thumbnail: course.thumbnail || null,
          instructorName: course.instructorName || null
        },
        me: { id: String(userId), role, isTeacher },
        stats: {
          enrolledCount: studentIds.length,
          activeCount: activeRows.length,
          teacherCount: teacherIds.length,
          groupCount: await StudyGroup.countDocuments({ courseId, isArchived: false }),
          discussionCount: await CommunityPost.countDocuments({
            courseId,
            type: { $in: ['discussion', 'question'] }
          }),
          unreadChatCount: unreadCourseChat,
          pendingCount: pendingSubmissions
        },
        teachers: teachers.map((t) => toPublicMember(t)),
        activeMembers,
        myGroups: myGroups.map((g) => ({
          id: String(g._id),
          name: g.name,
          purpose: g.purpose,
          memberCount: g.members.filter((m) => m.status === 'active').length,
          maxMembers: g.maxMembers,
          openTaskCount: g.tasks.filter((t) => !t.isDone).length,
          taskCount: g.tasks.length,
          lastActivityAt: g.lastActivityAt
        })),
        pinnedPosts: pinnedPosts.map(mapPost),
        recentDiscussions: recentPosts.map(mapPost),
        upcomingAssignments: openAssignments.map((a) => ({
          id: String(a._id),
          title: a.title,
          type: a.type,
          dueDate: a.dueDate,
          maxMarks: a.maxMarks
        })),
        nextSession: nextSession
          ? {
              id: String(nextSession._id),
              topic: nextSession.topic,
              scheduledAt: nextSession.scheduledAt,
              participantCount: nextSession.participants.length
            }
          : null
      }, 'Community overview loaded');
    } catch (error) {
      console.error('Error loading community overview:', error);
      return sendError(res, 'Failed to load community overview', 500, error.message);
    }
  }

  /**
   * The "Students learning now" directory. Sorted so active members surface
   * first, then most recently seen, then alphabetically.
   */
  async getMembers(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { search = '', filter = 'all', page = 1, limit = 30 } = req.query;

      const pageNum = Math.max(1, parseInt(page, 10) || 1);
      const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 30));

      const [studentIds, teacherIds] = await Promise.all([
        getStudentIds(courseId),
        getTeacherIds(courseId)
      ]);

      let candidateIds = [...new Set([...studentIds, ...teacherIds])];

      const userQuery = { _id: { $in: candidateIds }, isActive: true };
      if (search.trim()) {
        userQuery.fullName = { $regex: search.trim(), $options: 'i' };
      }

      const users = await User.find(userQuery).select(PUBLIC_USER_FIELDS).lean();
      const presence = await getPresenceMap(courseId, users.map((u) => u._id));

      const teacherSet = new Set(teacherIds);
      let members = users.map((u) =>
        toPublicMember(u, presence[String(u._id)], {
          isTeacher: teacherSet.has(String(u._id)),
          isMe: String(u._id) === String(userId)
        })
      );

      if (filter === 'active') {
        members = members.filter((m) => m.presence.status === 'active');
      } else if (filter === 'teachers') {
        members = members.filter((m) => m.isTeacher);
      } else if (filter === 'students') {
        members = members.filter((m) => !m.isTeacher);
      }

      const rank = { active: 0, recent: 1, offline: 2 };
      members.sort((a, b) => {
        const byStatus = rank[a.presence.status] - rank[b.presence.status];
        if (byStatus !== 0) return byStatus;
        const aSeen = a.presence.lastSeenAt ? new Date(a.presence.lastSeenAt).getTime() : 0;
        const bSeen = b.presence.lastSeenAt ? new Date(b.presence.lastSeenAt).getTime() : 0;
        if (bSeen !== aSeen) return bSeen - aSeen;
        return a.fullName.localeCompare(b.fullName);
      });

      const total = members.length;
      const start = (pageNum - 1) * limitNum;

      return sendSuccess(res, {
        members: members.slice(start, start + limitNum),
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          totalPages: Math.ceil(total / limitNum) || 1
        },
        counts: {
          enrolled: studentIds.length,
          active: members.filter((m) => m.presence.status === 'active').length,
          teachers: teacherIds.length
        }
      }, 'Community members loaded');
    } catch (error) {
      console.error('Error loading community members:', error);
      return sendError(res, 'Failed to load community members', 500, error.message);
    }
  }

  /**
   * A member's public course profile. Shows what they are studying and how
   * they participate — never precise activity or contact details.
   */
  async getMemberProfile(req, res) {
    try {
      const { courseId } = req.community;
      const { memberId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(memberId)) {
        return sendError(res, 'A valid member ID is required', 400);
      }

      const user = await User.findById(memberId).select(PUBLIC_USER_FIELDS).lean();
      if (!user) return sendNotFound(res, 'Member not found');

      const [enrollment, teacherIds, groups, postCount, replyCount, partnerProfile, otherCourses] =
        await Promise.all([
          Enrollment.findOne({ userId: memberId, courseId }).select('progress enrollmentDate').lean(),
          getTeacherIds(courseId),
          StudyGroup.find({
            courseId,
            isArchived: false,
            members: { $elemMatch: { userId: memberId, status: 'active' } }
          })
            .select('name purpose members')
            .lean(),
          CommunityPost.countDocuments({ courseId, authorId: memberId }),
          CommunityPost.countDocuments({ courseId, 'replies.authorId': memberId }),
          StudyPartnerProfile.findOne({ courseId, userId: memberId, isActive: true }).lean(),
          Enrollment.countDocuments({ userId: memberId })
        ]);

      const presence = await getPresenceMap(courseId, [memberId]);
      const isTeacher = teacherIds.includes(String(memberId));

      if (!enrollment && !isTeacher) {
        return sendNotFound(res, 'This member is not part of this course community');
      }

      return sendSuccess(res, {
        ...toPublicMember(user, presence[String(memberId)], { isTeacher }),
        currentlyStudying: req.community.course.title,
        enrolledCoursesCount: otherCourses,
        progress: enrollment ? enrollment.progress : null,
        joinedCourseAt: enrollment ? enrollment.enrollmentDate : null,
        groupCount: groups.length,
        groups: groups.map((g) => ({
          id: String(g._id),
          name: g.name,
          purpose: g.purpose,
          memberCount: g.members.filter((m) => m.status === 'active').length
        })),
        contributions: { posts: postCount, replies: replyCount },
        lookingForPartner: partnerProfile
          ? {
              goal: partnerProfile.goal,
              topics: partnerProfile.topics,
              availability: partnerProfile.availability,
              note: partnerProfile.note
            }
          : null
      }, 'Member profile loaded');
    } catch (error) {
      console.error('Error loading member profile:', error);
      return sendError(res, 'Failed to load member profile', 500, error.message);
    }
  }

  /** Heartbeat from the app while a member has the community/course open. */
  async ping(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { area = 'community' } = req.body;

      const allowed = ['community', 'lesson', 'group', 'chat', 'assignment'];
      await CoursePresence.touch(
        courseId,
        userId,
        allowed.includes(area) ? area : 'community'
      );

      const activeCount = await CoursePresence.activeCount(courseId);
      return sendSuccess(res, { activeCount }, 'Presence updated');
    } catch (error) {
      console.error('Error updating presence:', error);
      return sendError(res, 'Failed to update presence', 500, error.message);
    }
  }

  /** Lets a member hide from (or return to) the "studying now" list. */
  async setPresenceVisibility(req, res) {
    try {
      const { courseId, userId } = req.community;
      const isVisible = req.body.isVisible !== false;

      await CoursePresence.findOneAndUpdate(
        { courseId, userId },
        { $set: { isVisible, lastSeenAt: new Date() } },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );

      return sendSuccess(res, { isVisible }, 'Visibility updated');
    } catch (error) {
      console.error('Error updating presence visibility:', error);
      return sendError(res, 'Failed to update visibility', 500, error.message);
    }
  }

  // ── Find study partners ─────────────────────────────────────────

  async listStudyPartners(req, res) {
    try {
      const { courseId, userId } = req.community;

      const profiles = await StudyPartnerProfile.find({ courseId, isActive: true })
        .sort({ updatedAt: -1 })
        .limit(60)
        .populate('userId', PUBLIC_USER_FIELDS)
        .lean();

      const visible = profiles.filter((p) => p.userId);
      const presence = await getPresenceMap(courseId, visible.map((p) => p.userId._id));

      return sendSuccess(res, {
        partners: visible
          .filter((p) => String(p.userId._id) !== String(userId))
          .map((p) => ({
            id: String(p._id),
            member: toPublicMember(p.userId, presence[String(p.userId._id)]),
            goal: p.goal,
            topics: p.topics,
            availability: p.availability,
            note: p.note,
            updatedAt: p.updatedAt
          })),
        myProfile: visible
          .filter((p) => String(p.userId._id) === String(userId))
          .map((p) => ({
            id: String(p._id),
            goal: p.goal,
            topics: p.topics,
            availability: p.availability,
            note: p.note,
            isActive: p.isActive
          }))[0] || null
      }, 'Study partners loaded');
    } catch (error) {
      console.error('Error loading study partners:', error);
      return sendError(res, 'Failed to load study partners', 500, error.message);
    }
  }

  /** Publish or update my own "looking for a study partner" card. */
  async upsertStudyPartnerProfile(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { goal, topics = [], availability = [], note, isActive = true } = req.body;

      const profile = await StudyPartnerProfile.findOneAndUpdate(
        { courseId, userId },
        {
          $set: {
            goal: (goal || '').trim(),
            topics: Array.isArray(topics) ? topics.slice(0, 10) : [],
            availability: Array.isArray(availability) ? availability : [],
            note: (note || '').trim(),
            isActive: isActive !== false
          }
        },
        { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true }
      ).lean();

      return sendSuccess(res, {
        id: String(profile._id),
        goal: profile.goal,
        topics: profile.topics,
        availability: profile.availability,
        note: profile.note,
        isActive: profile.isActive
      }, 'Study partner profile saved');
    } catch (error) {
      console.error('Error saving study partner profile:', error);
      return sendError(res, 'Failed to save study partner profile', 500, error.message);
    }
  }

  async removeStudyPartnerProfile(req, res) {
    try {
      const { courseId, userId } = req.community;
      await StudyPartnerProfile.findOneAndUpdate(
        { courseId, userId },
        { $set: { isActive: false } }
      );
      return sendSuccess(res, null, 'You are no longer listed as looking for a partner');
    } catch (error) {
      console.error('Error removing study partner profile:', error);
      return sendError(res, 'Failed to update study partner profile', 500, error.message);
    }
  }
}

module.exports = new CommunityController();
