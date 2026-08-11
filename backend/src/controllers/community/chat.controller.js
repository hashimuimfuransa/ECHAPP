const mongoose = require('mongoose');
const CommunityMessage = require('../../models/community/CommunityMessage');
const StudyGroup = require('../../models/community/StudyGroup');
const CoursePresence = require('../../models/community/CoursePresence');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS } = require('../../utils/community.utils');

const mapMessage = (msg, userId) => ({
  id: String(msg._id),
  scope: msg.scope,
  groupId: msg.groupId ? String(msg.groupId) : null,
  content: msg.isDeleted ? null : msg.content,
  attachments: msg.isDeleted ? [] : (msg.attachments || []),
  sender: msg.senderId
    ? {
        id: String(msg.senderId._id || msg.senderId),
        fullName: msg.senderId.fullName || 'ECH Student',
        avatar: msg.senderId.avatar || null,
        role: msg.senderId.role || msg.senderRole
      }
    : null,
  senderRole: msg.senderRole,
  isTeacher: msg.senderRole === 'instructor' || msg.senderRole === 'admin',
  isMine: String(msg.senderId && (msg.senderId._id || msg.senderId)) === String(userId),
  isDeleted: msg.isDeleted,
  replyTo: msg.replyTo
    ? {
        id: String(msg.replyTo._id || msg.replyTo),
        content: msg.replyTo.content || null,
        senderName: msg.replyTo.senderId && msg.replyTo.senderId.fullName
          ? msg.replyTo.senderId.fullName
          : null
      }
    : null,
  createdAt: msg.createdAt
});

/**
 * Resolves the chat room from the request and makes sure the caller is
 * allowed in it. Course chat is open to every community member; group chat
 * is restricted to active members of that group (teachers may read along).
 */
const resolveRoom = async (req) => {
  const { courseId, userId, isTeacher } = req.community;
  const groupId = req.params.groupId || req.query.groupId || req.body.groupId || null;

  if (!groupId) {
    return { scope: 'course', groupId: null, courseId };
  }
  if (!mongoose.Types.ObjectId.isValid(groupId)) {
    return { error: { message: 'A valid group ID is required', status: 400 } };
  }

  const group = await StudyGroup.findOne({ _id: groupId, courseId }).select('members').lean();
  if (!group) return { error: { message: 'Study group not found', status: 404 } };

  const isMember = group.members.some(
    (m) => String(m.userId) === String(userId) && m.status === 'active'
  );
  if (!isMember && !isTeacher) {
    return { error: { message: 'You are not a member of this group', status: 403 } };
  }

  return { scope: 'group', groupId, courseId };
};

class ChatController {
  /** Newest-first page of messages; the app reverses for display. */
  async listMessages(req, res) {
    try {
      const { userId } = req.community;
      const room = await resolveRoom(req);
      if (room.error) {
        return room.error.status === 403
          ? sendForbidden(res, room.error.message)
          : room.error.status === 404
            ? sendNotFound(res, room.error.message)
            : sendError(res, room.error.message, room.error.status);
      }

      const { before, limit = 40 } = req.query;
      const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 40));

      const query = { courseId: room.courseId, scope: room.scope, groupId: room.groupId };
      if (before) {
        const beforeDate = new Date(before);
        if (!Number.isNaN(beforeDate.getTime())) query.createdAt = { $lt: beforeDate };
      }

      const messages = await CommunityMessage.find(query)
        .sort({ createdAt: -1 })
        .limit(limitNum)
        .populate('senderId', PUBLIC_USER_FIELDS)
        .populate({
          path: 'replyTo',
          select: 'content senderId',
          populate: { path: 'senderId', select: 'fullName' }
        })
        .lean();

      // Mark what we just handed over as read for this user.
      CommunityMessage.updateMany(
        {
          _id: { $in: messages.map((m) => m._id) },
          senderId: { $ne: userId },
          readBy: { $ne: userId }
        },
        { $addToSet: { readBy: userId } }
      ).catch((e) => console.error('Failed to mark chat as read:', e.message));

      CoursePresence.touch(room.courseId, userId, 'chat').catch(() => {});

      return sendSuccess(res, {
        messages: messages.reverse().map((m) => mapMessage(m, userId)),
        hasMore: messages.length === limitNum
      }, 'Messages loaded');
    } catch (error) {
      console.error('Error loading chat messages:', error);
      return sendError(res, 'Failed to load messages', 500, error.message);
    }
  }

  async sendMessage(req, res) {
    try {
      const { userId, role } = req.community;
      const room = await resolveRoom(req);
      if (room.error) {
        return room.error.status === 403
          ? sendForbidden(res, room.error.message)
          : room.error.status === 404
            ? sendNotFound(res, room.error.message)
            : sendError(res, room.error.message, room.error.status);
      }

      const { content = '', attachments = [], replyTo = null } = req.body;

      if (!content.trim() && (!Array.isArray(attachments) || attachments.length === 0)) {
        return sendError(res, 'Write a message or attach a file', 400);
      }

      const message = await CommunityMessage.create({
        courseId: room.courseId,
        scope: room.scope,
        groupId: room.groupId,
        senderId: userId,
        senderRole: role === 'admin' ? 'admin' : role === 'instructor' ? 'instructor' : 'student',
        content: content.trim(),
        attachments: Array.isArray(attachments) ? attachments : [],
        replyTo: replyTo && mongoose.Types.ObjectId.isValid(replyTo) ? replyTo : null,
        readBy: [userId]
      });

      if (room.scope === 'group') {
        StudyGroup.findByIdAndUpdate(room.groupId, {
          $set: { lastActivityAt: new Date() }
        }).catch(() => {});
      }
      CoursePresence.touch(room.courseId, userId, 'chat').catch(() => {});

      const populated = await CommunityMessage.findById(message._id)
        .populate('senderId', PUBLIC_USER_FIELDS)
        .populate({
          path: 'replyTo',
          select: 'content senderId',
          populate: { path: 'senderId', select: 'fullName' }
        })
        .lean();

      return sendSuccess(res, mapMessage(populated, userId), 'Message sent', 201);
    } catch (error) {
      console.error('Error sending chat message:', error);
      return sendError(res, 'Failed to send message', 500, error.message);
    }
  }

  /** Soft delete so the thread keeps its shape ("message deleted"). */
  async deleteMessage(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { messageId } = req.params;

      const message = await CommunityMessage.findOne({ _id: messageId, courseId });
      if (!message) return sendNotFound(res, 'Message not found');

      if (String(message.senderId) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'You can only delete your own messages');
      }

      message.isDeleted = true;
      message.content = '';
      message.attachments = [];
      await message.save();

      return sendSuccess(res, null, 'Message deleted');
    } catch (error) {
      console.error('Error deleting chat message:', error);
      return sendError(res, 'Failed to delete message', 500, error.message);
    }
  }

  /** Unread badge counts for the course room and each of my groups. */
  async getUnreadCounts(req, res) {
    try {
      const { courseId, userId } = req.community;

      const myGroups = await StudyGroup.find({
        courseId,
        isArchived: false,
        members: { $elemMatch: { userId, status: 'active' } }
      })
        .select('_id')
        .lean();

      const groupIds = myGroups.map((g) => g._id);

      const [courseUnread, groupUnread] = await Promise.all([
        CommunityMessage.countDocuments({
          courseId,
          scope: 'course',
          isDeleted: false,
          senderId: { $ne: userId },
          readBy: { $ne: userId }
        }),
        CommunityMessage.aggregate([
          {
            $match: {
              scope: 'group',
              groupId: { $in: groupIds },
              isDeleted: false,
              senderId: { $ne: new mongoose.Types.ObjectId(String(userId)) },
              readBy: { $ne: new mongoose.Types.ObjectId(String(userId)) }
            }
          },
          { $group: { _id: '$groupId', count: { $sum: 1 } } }
        ])
      ]);

      const groups = {};
      groupUnread.forEach((g) => { groups[String(g._id)] = g.count; });

      return sendSuccess(res, {
        course: courseUnread,
        groups,
        total: courseUnread + groupUnread.reduce((sum, g) => sum + g.count, 0)
      }, 'Unread counts loaded');
    } catch (error) {
      console.error('Error loading unread counts:', error);
      return sendError(res, 'Failed to load unread counts', 500, error.message);
    }
  }
}

module.exports = new ChatController();
