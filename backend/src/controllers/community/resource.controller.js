const mongoose = require('mongoose');
const CommunityResource = require('../../models/community/CommunityResource');
const StudySession = require('../../models/community/StudySession');
const StudyGroup = require('../../models/community/StudyGroup');
const User = require('../../models/User');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS, toPublicMember } = require('../../utils/community.utils');
const CommunityNotificationService = require('../../services/community-notification.service');

const RESOURCE_TYPES = ['document', 'link', 'video', 'note'];

const mapResource = (r, userId) => ({
  id: String(r._id),
  title: r.title,
  description: r.description || '',
  type: r.type,
  source: r.source,
  url: r.url || null,
  body: r.body || null,
  fileName: r.fileName || null,
  mimeType: r.mimeType || null,
  size: r.size || null,
  uploadedBy: r.uploadedBy && r.uploadedBy.fullName ? toPublicMember(r.uploadedBy) : null,
  isApproved: r.isApproved,
  isMine: String(r.uploadedBy && (r.uploadedBy._id || r.uploadedBy)) === String(userId),
  likeCount: (r.likes || []).length,
  isLikedByMe: (r.likes || []).some((l) => String(l) === String(userId)),
  downloadCount: r.downloadCount || 0,
  createdAt: r.createdAt
});

const mapSession = (s, userId) => ({
  id: String(s._id),
  topic: s.topic,
  description: s.description || '',
  scheduledAt: s.scheduledAt,
  durationMinutes: s.durationMinutes,
  agenda: s.agenda || [],
  maxParticipants: s.maxParticipants,
  participantCount: (s.participants || []).length,
  participants: (s.participants || []).map((p) =>
    p.userId && p.userId.fullName ? toPublicMember(p.userId) : { id: String(p.userId) }
  ),
  isJoined: (s.participants || []).some(
    (p) => String(p.userId && (p.userId._id || p.userId)) === String(userId)
  ),
  meetingLink: s.meetingLink || null,
  status: s.status,
  group: s.groupId && s.groupId.name ? { id: String(s.groupId._id), name: s.groupId.name } : null,
  organiser: s.createdBy && s.createdBy.fullName ? toPublicMember(s.createdBy) : null,
  isMine: String(s.createdBy && (s.createdBy._id || s.createdBy)) === String(userId),
  isPast: new Date(s.scheduledAt) < new Date(),
  createdAt: s.createdAt
});

class ResourceController {
  /** Split feed: teacher-published resources vs peer-shared ones. */
  async listResources(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { source, type, search = '' } = req.query;

      const query = { courseId };
      if (source === 'teacher' || source === 'student') query.source = source;
      if (type && RESOURCE_TYPES.includes(type)) query.type = type;
      if (search.trim()) {
        const rx = { $regex: search.trim(), $options: 'i' };
        query.$or = [{ title: rx }, { description: rx }];
      }

      const resources = await CommunityResource.find(query)
        .sort({ createdAt: -1 })
        .limit(200)
        .populate('uploadedBy', PUBLIC_USER_FIELDS)
        .lean();

      const mapped = resources.map((r) => mapResource(r, userId));

      return sendSuccess(res, {
        teacherResources: mapped.filter((r) => r.source === 'teacher'),
        studentResources: mapped.filter((r) => r.source === 'student'),
        total: mapped.length
      }, 'Resources loaded');
    } catch (error) {
      console.error('Error listing community resources:', error);
      return sendError(res, 'Failed to load resources', 500, error.message);
    }
  }

  /**
   * Share a resource. Teacher uploads land in the authoritative section and
   * are approved on the spot; student uploads wait for teacher approval.
   */
  async createResource(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const {
        title,
        description = '',
        type = 'link',
        url = '',
        body = '',
        fileName,
        mimeType,
        size
      } = req.body;

      if (!title || !title.trim()) return sendError(res, 'Resource title is required', 400);
      if (!RESOURCE_TYPES.includes(type)) return sendError(res, 'Unknown resource type', 400);
      if (type !== 'note' && !url.trim()) {
        return sendError(res, 'A link or file URL is required', 400);
      }
      if (type === 'note' && !body.trim()) {
        return sendError(res, 'Write something in the note', 400);
      }

      const resource = await CommunityResource.create({
        courseId,
        uploadedBy: userId,
        source: isTeacher ? 'teacher' : 'student',
        title: title.trim(),
        description: (description || '').trim(),
        type,
        url: (url || '').trim(),
        body: (body || '').trim(),
        fileName: fileName || null,
        mimeType: mimeType || null,
        size: size || null,
        isApproved: isTeacher,
        approvedBy: isTeacher ? userId : null
      });

      const populated = await CommunityResource.findById(resource._id)
        .populate('uploadedBy', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(
        res,
        mapResource(populated, userId),
        isTeacher ? 'Resource shared with the class' : 'Resource shared — a teacher will review it',
        201
      );
    } catch (error) {
      console.error('Error creating community resource:', error);
      return sendError(res, 'Failed to share resource', 500, error.message);
    }
  }

  async deleteResource(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { resourceId } = req.params;

      const resource = await CommunityResource.findOne({ _id: resourceId, courseId });
      if (!resource) return sendNotFound(res, 'Resource not found');
      if (String(resource.uploadedBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'You can only remove resources you shared');
      }

      await resource.deleteOne();
      return sendSuccess(res, null, 'Resource removed');
    } catch (error) {
      console.error('Error deleting community resource:', error);
      return sendError(res, 'Failed to remove resource', 500, error.message);
    }
  }

  /** Teacher quality control over peer-shared material. */
  async approveResource(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { resourceId } = req.params;
      const isApproved = req.body.isApproved !== false;

      const resource = await CommunityResource.findOneAndUpdate(
        { _id: resourceId, courseId },
        { $set: { isApproved, approvedBy: isApproved ? userId : null } },
        { new: true }
      ).lean();

      if (!resource) return sendNotFound(res, 'Resource not found');

      return sendSuccess(res, {
        id: String(resource._id),
        isApproved: resource.isApproved
      }, isApproved ? 'Resource approved' : 'Approval removed');
    } catch (error) {
      console.error('Error approving community resource:', error);
      return sendError(res, 'Failed to update resource', 500, error.message);
    }
  }

  async toggleResourceLike(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { resourceId } = req.params;

      const resource = await CommunityResource.findOne({ _id: resourceId, courseId });
      if (!resource) return sendNotFound(res, 'Resource not found');

      const index = resource.likes.findIndex((l) => String(l) === String(userId));
      if (index >= 0) resource.likes.splice(index, 1);
      else resource.likes.push(userId);
      await resource.save();

      return sendSuccess(res, {
        liked: index < 0,
        likeCount: resource.likes.length
      }, index < 0 ? 'Liked' : 'Like removed');
    } catch (error) {
      console.error('Error liking community resource:', error);
      return sendError(res, 'Failed to update like', 500, error.message);
    }
  }

  // ── Study sessions ─────────────────────────────────────────────

  async listSessions(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { scope = 'upcoming', groupId } = req.query;

      const query = { courseId };
      if (groupId && mongoose.Types.ObjectId.isValid(groupId)) query.groupId = groupId;

      if (scope === 'upcoming') {
        query.scheduledAt = { $gte: new Date() };
        query.status = 'scheduled';
      } else if (scope === 'past') {
        query.scheduledAt = { $lt: new Date() };
      } else if (scope === 'mine') {
        query.$or = [{ createdBy: userId }, { 'participants.userId': userId }];
      }

      const sessions = await StudySession.find(query)
        .sort({ scheduledAt: scope === 'past' ? -1 : 1 })
        .limit(100)
        .populate('createdBy', PUBLIC_USER_FIELDS)
        .populate('participants.userId', PUBLIC_USER_FIELDS)
        .populate('groupId', 'name')
        .lean();

      return sendSuccess(res, {
        sessions: sessions.map((s) => mapSession(s, userId))
      }, 'Study sessions loaded');
    } catch (error) {
      console.error('Error listing study sessions:', error);
      return sendError(res, 'Failed to load study sessions', 500, error.message);
    }
  }

  /**
   * Create a study session. Group sessions notify that group; open course
   * sessions stay quiet until people opt in, so the class is not spammed.
   */
  async createSession(req, res) {
    try {
      const { courseId, userId } = req.community;
      const {
        topic,
        description = '',
        scheduledAt,
        durationMinutes = 60,
        agenda = [],
        maxParticipants = 10,
        meetingLink = '',
        groupId = null
      } = req.body;

      if (!topic || !topic.trim()) return sendError(res, 'A session topic is required', 400);
      if (!scheduledAt) return sendError(res, 'Pick a date and time for the session', 400);

      const when = new Date(scheduledAt);
      if (Number.isNaN(when.getTime())) return sendError(res, 'That date and time is not valid', 400);

      let resolvedGroupId = null;
      if (groupId && mongoose.Types.ObjectId.isValid(groupId)) {
        const group = await StudyGroup.findOne({ _id: groupId, courseId, isArchived: false });
        if (!group) return sendNotFound(res, 'Study group not found');
        if (!group.isActiveMember(userId) && !req.community.isTeacher) {
          return sendForbidden(res, 'You are not a member of that group');
        }
        resolvedGroupId = group._id;
      }

      const session = await StudySession.create({
        courseId,
        groupId: resolvedGroupId,
        createdBy: userId,
        topic: topic.trim(),
        description: (description || '').trim(),
        scheduledAt: when,
        durationMinutes: Math.max(10, parseInt(durationMinutes, 10) || 60),
        agenda: Array.isArray(agenda)
          ? agenda.map((a) => String(a).trim()).filter(Boolean).slice(0, 20)
          : [],
        maxParticipants: Math.max(2, parseInt(maxParticipants, 10) || 10),
        meetingLink: (meetingLink || '').trim(),
        participants: [{ userId, joinedAt: new Date() }]
      });

      const organiser = await User.findById(userId).select('fullName').lean();
      const recipientIds = resolvedGroupId
        ? (await StudyGroup.findById(resolvedGroupId).select('members').lean()).members
            .filter((m) => m.status === 'active')
            .map((m) => String(m.userId))
        : [];

      if (recipientIds.length) {
        CommunityNotificationService.sessionScheduled({
          recipientIds,
          courseId,
          sessionId: String(session._id),
          topic: session.topic,
          scheduledAt: session.scheduledAt,
          organiserName: organiser ? organiser.fullName : 'A classmate',
          excludeUserId: userId
        });
      }

      const populated = await StudySession.findById(session._id)
        .populate('createdBy', PUBLIC_USER_FIELDS)
        .populate('participants.userId', PUBLIC_USER_FIELDS)
        .populate('groupId', 'name')
        .lean();

      return sendSuccess(res, mapSession(populated, userId), 'Study session created', 201);
    } catch (error) {
      console.error('Error creating study session:', error);
      return sendError(res, 'Failed to create study session', 500, error.message);
    }
  }

  async joinSession(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { sessionId } = req.params;

      const session = await StudySession.findOne({ _id: sessionId, courseId, status: 'scheduled' });
      if (!session) return sendNotFound(res, 'Study session not found');

      const already = session.participants.some((p) => String(p.userId) === String(userId));
      if (already) {
        session.participants = session.participants.filter(
          (p) => String(p.userId) !== String(userId)
        );
      } else {
        if (session.participants.length >= session.maxParticipants) {
          return sendError(res, 'This session is already full', 400);
        }
        session.participants.push({ userId, joinedAt: new Date() });
      }

      await session.save();
      return sendSuccess(res, {
        joined: !already,
        participantCount: session.participants.length
      }, already ? 'You left the session' : 'You joined the session');
    } catch (error) {
      console.error('Error joining study session:', error);
      return sendError(res, 'Failed to update session', 500, error.message);
    }
  }

  async updateSession(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;
      const { topic, description, scheduledAt, durationMinutes, agenda, meetingLink, status } = req.body;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');
      if (String(session.createdBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the organiser can change this session');
      }

      if (topic !== undefined && topic.trim()) session.topic = topic.trim();
      if (description !== undefined) session.description = (description || '').trim();
      if (scheduledAt !== undefined) {
        const when = new Date(scheduledAt);
        if (Number.isNaN(when.getTime())) return sendError(res, 'That date and time is not valid', 400);
        session.scheduledAt = when;
      }
      if (durationMinutes !== undefined) {
        session.durationMinutes = Math.max(10, parseInt(durationMinutes, 10) || session.durationMinutes);
      }
      if (Array.isArray(agenda)) {
        session.agenda = agenda.map((a) => String(a).trim()).filter(Boolean).slice(0, 20);
      }
      if (meetingLink !== undefined) session.meetingLink = (meetingLink || '').trim();
      if (status && ['scheduled', 'cancelled', 'completed'].includes(status)) session.status = status;

      await session.save();

      const populated = await StudySession.findById(session._id)
        .populate('createdBy', PUBLIC_USER_FIELDS)
        .populate('participants.userId', PUBLIC_USER_FIELDS)
        .populate('groupId', 'name')
        .lean();

      return sendSuccess(res, mapSession(populated, userId), 'Session updated');
    } catch (error) {
      console.error('Error updating study session:', error);
      return sendError(res, 'Failed to update session', 500, error.message);
    }
  }

  async deleteSession(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');
      if (String(session.createdBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the organiser can cancel this session');
      }

      session.status = 'cancelled';
      await session.save();
      return sendSuccess(res, null, 'Session cancelled');
    } catch (error) {
      console.error('Error cancelling study session:', error);
      return sendError(res, 'Failed to cancel session', 500, error.message);
    }
  }
}

module.exports = new ResourceController();
