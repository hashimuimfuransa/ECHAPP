const mongoose = require('mongoose');
const CommunityMessage = require('../../models/community/CommunityMessage');
const StudyGroup = require('../../models/community/StudyGroup');
const CoursePresence = require('../../models/community/CoursePresence');
const DirectConversation = require('../../models/messaging/DirectConversation');
const DirectMessage = require('../../models/messaging/DirectMessage');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS } = require('../../utils/community.utils');

/**
 * Stable identifier for a chat room across all three kinds, so the app can key
 * one inbox and one sync stream off a single string.
 */
const roomKeys = {
  course: () => 'course',
  group: (groupId) => `group:${groupId}`,
  direct: (conversationId) => `direct:${conversationId}`
};

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

  /**
   * Everything the student can talk in, in one list: the public course room,
   * each of their study groups, and their direct conversations.
   *
   * The Chat tab shows all three together, so it needs them in a single shape
   * rather than three separate calls.
   */
  async getInbox(req, res) {
    try {
      const { courseId, userId, course } = req.community;
      const rooms = await buildInbox(courseId, userId, course);

      return sendSuccess(res, {
        rooms,
        totalUnread: rooms.reduce((sum, r) => sum + r.unreadCount, 0)
      }, 'Chat inbox loaded');
    } catch (error) {
      console.error('Error loading chat inbox:', error);
      return sendError(res, 'Failed to load your chats', 500, error.message);
    }
  }

  /**
   * Near-real-time delivery by long polling.
   *
   * The request is held open until something arrives in any of the caller's
   * rooms, or `wait` seconds elapse — so a message lands in about the time it
   * takes to write it, without a socket layer. The client re-requests
   * immediately with the returned cursor, making this a continuous stream of
   * short-lived requests.
   *
   * Chosen over SSE because Flutter web's HTTP client buffers streamed
   * responses rather than delivering them incrementally; a plain
   * request/response works identically on every platform.
   */
  async sync(req, res) {
    try {
      const { courseId, userId, course } = req.community;

      const waitSeconds = Math.min(30, Math.max(0, parseInt(req.query.wait, 10) || 0));
      const since = req.query.since ? new Date(req.query.since) : null;
      const cursor = since && !Number.isNaN(since.getTime())
        ? since
        : new Date(Date.now() - 60 * 1000);

      const deadline = Date.now() + waitSeconds * 1000;
      let clientGone = false;
      req.on('close', () => { clientGone = true; });

      // Poll the database rather than holding a change stream open per user:
      // one indexed query every 1.5s is cheap, and it works on any MongoDB
      // deployment (change streams need a replica set).
      const POLL_MS = 1500;

      while (true) {
        const payload = await collectSince(courseId, userId, cursor, course);

        if (payload.messages.length > 0 || Date.now() >= deadline || clientGone) {
          if (clientGone) return; // nothing to write to
          return sendSuccess(res, payload, 'Synced');
        }

        await new Promise((resolve) => setTimeout(resolve, POLL_MS));
      }
    } catch (error) {
      console.error('Error syncing chat:', error);
      if (!res.headersSent) {
        return sendError(res, 'Failed to sync chat', 500, error.message);
      }
    }
  }
}

// ─────────────────────────────────────────────
//  Inbox / sync helpers
// ─────────────────────────────────────────────

/** The caller's active study groups in this course. */
const myGroups = (courseId, userId) =>
  StudyGroup.find({
    courseId,
    isArchived: false,
    members: { $elemMatch: { userId, status: 'active' } }
  })
    .select('name')
    .lean();

/** The caller's direct conversations, newest first. */
const myConversations = (userId) =>
  DirectConversation.find({ participants: userId, hiddenBy: { $ne: userId } })
    .sort({ lastMessageAt: -1 })
    .limit(50)
    .populate('participants', PUBLIC_USER_FIELDS)
    .lean();

const previewOf = (message) => {
  if (!message) return null;
  return {
    content: message.isDeleted ? 'Message removed' : (message.content || ''),
    senderName:
      message.senderId && message.senderId.fullName
        ? message.senderId.fullName
        : null,
    hasAttachment: (message.attachments || []).length > 0,
    sentAt: message.createdAt
  };
};

/** Builds the unified room list shown in the Chat tab. */
async function buildInbox(courseId, userId, course) {
  const [groups, conversations] = await Promise.all([
    myGroups(courseId, userId),
    myConversations(userId)
  ]);

  const groupIds = groups.map((g) => g._id);

  const [courseLast, courseUnread, groupLasts, groupUnreads] = await Promise.all([
    CommunityMessage.findOne({ courseId, scope: 'course', isDeleted: false })
      .sort({ createdAt: -1 })
      .populate('senderId', PUBLIC_USER_FIELDS)
      .lean(),
    CommunityMessage.countDocuments({
      courseId,
      scope: 'course',
      isDeleted: false,
      senderId: { $ne: userId },
      readBy: { $ne: userId }
    }),
    CommunityMessage.aggregate([
      { $match: { scope: 'group', groupId: { $in: groupIds }, isDeleted: false } },
      { $sort: { createdAt: -1 } },
      { $group: { _id: '$groupId', message: { $first: '$$ROOT' } } }
    ]),
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

  const groupLastMap = {};
  groupLasts.forEach((g) => { groupLastMap[String(g._id)] = g.message; });
  const groupUnreadMap = {};
  groupUnreads.forEach((g) => { groupUnreadMap[String(g._id)] = g.count; });

  const rooms = [];

  // 1. The public course room — always present, always first.
  rooms.push({
    key: roomKeys.course(),
    type: 'course',
    title: course && course.title ? course.title : 'Course chat',
    subtitle: 'Everyone in this course',
    lastMessage: previewOf(courseLast),
    lastMessageAt: courseLast ? courseLast.createdAt : null,
    unreadCount: courseUnread,
    groupId: null,
    conversationId: null,
    contact: null
  });

  // 2. My study groups.
  groups.forEach((group) => {
    const last = groupLastMap[String(group._id)];
    rooms.push({
      key: roomKeys.group(group._id),
      type: 'group',
      title: group.name,
      subtitle: 'Study group',
      lastMessage: previewOf(last),
      lastMessageAt: last ? last.createdAt : null,
      unreadCount: groupUnreadMap[String(group._id)] || 0,
      groupId: String(group._id),
      conversationId: null,
      contact: null
    });
  });

  // 3. Direct conversations.
  conversations.forEach((conversation) => {
    const other = (conversation.participants || []).find(
      (p) => String(p._id) !== String(userId)
    );
    if (!other) return;

    const unreadEntry = (conversation.unread || []).find(
      (u) => String(u.userId) === String(userId)
    );

    rooms.push({
      key: roomKeys.direct(conversation._id),
      type: 'direct',
      title: other.fullName || 'ECH User',
      subtitle:
        other.role === 'admin'
          ? 'ECH Support'
          : other.role === 'instructor'
            ? 'Teacher'
            : 'Student',
      lastMessage: conversation.lastMessage && conversation.lastMessage.sentAt
        ? {
            content: conversation.lastMessage.content || '',
            senderName:
              String(conversation.lastMessage.senderId || '') === String(userId)
                ? 'You'
                : other.fullName,
            hasAttachment: Boolean(conversation.lastMessage.hasAttachment),
            sentAt: conversation.lastMessage.sentAt
          }
        : null,
      lastMessageAt: conversation.lastMessageAt,
      unreadCount: unreadEntry ? unreadEntry.count : 0,
      groupId: null,
      conversationId: String(conversation._id),
      contact: {
        id: String(other._id),
        fullName: other.fullName || 'ECH User',
        avatar: other.avatar || null,
        role: other.role || 'student',
        isTeacher: other.role === 'instructor' || other.role === 'admin'
      }
    });
  });

  // Rooms with activity float up; the course room holds its place when quiet.
  rooms.sort((a, b) => {
    if (a.type === 'course' && !a.lastMessageAt) return -1;
    if (b.type === 'course' && !b.lastMessageAt) return 1;
    const aAt = a.lastMessageAt ? new Date(a.lastMessageAt).getTime() : 0;
    const bAt = b.lastMessageAt ? new Date(b.lastMessageAt).getTime() : 0;
    return bAt - aAt;
  });

  return rooms;
}

/**
 * Collects every message across the caller's rooms newer than `cursor`,
 * tagged with the room it belongs to.
 */
async function collectSince(courseId, userId, cursor, course) {
  const [groups, conversations] = await Promise.all([
    myGroups(courseId, userId),
    DirectConversation.find({ participants: userId }).select('_id').lean()
  ]);

  const groupIds = groups.map((g) => g._id);
  const conversationIds = conversations.map((c) => c._id);

  const [communityMessages, directMessages] = await Promise.all([
    CommunityMessage.find({
      createdAt: { $gt: cursor },
      $or: [
        { courseId, scope: 'course' },
        { scope: 'group', groupId: { $in: groupIds } }
      ]
    })
      .sort({ createdAt: 1 })
      .limit(100)
      .populate('senderId', PUBLIC_USER_FIELDS)
      .lean(),
    DirectMessage.find({
      conversationId: { $in: conversationIds },
      createdAt: { $gt: cursor }
    })
      .sort({ createdAt: 1 })
      .limit(100)
      .populate('senderId', PUBLIC_USER_FIELDS)
      .lean()
  ]);

  const messages = [
    ...communityMessages.map((m) => ({
      roomKey:
        m.scope === 'group' ? roomKeys.group(m.groupId) : roomKeys.course(),
      roomType: m.scope,
      id: String(m._id),
      content: m.isDeleted ? null : m.content,
      senderId: String(m.senderId && (m.senderId._id || m.senderId)),
      senderName: m.senderId && m.senderId.fullName ? m.senderId.fullName : null,
      senderAvatar: m.senderId && m.senderId.avatar ? m.senderId.avatar : null,
      isMine: String(m.senderId && (m.senderId._id || m.senderId)) === String(userId),
      hasAttachment: (m.attachments || []).length > 0,
      createdAt: m.createdAt
    })),
    ...directMessages.map((m) => ({
      roomKey: roomKeys.direct(m.conversationId),
      roomType: 'direct',
      id: String(m._id),
      content: m.isDeleted ? null : m.content,
      senderId: String(m.senderId && (m.senderId._id || m.senderId)),
      senderName: m.senderId && m.senderId.fullName ? m.senderId.fullName : null,
      senderAvatar: m.senderId && m.senderId.avatar ? m.senderId.avatar : null,
      isMine: String(m.senderId && (m.senderId._id || m.senderId)) === String(userId),
      hasAttachment: (m.attachments || []).length > 0,
      createdAt: m.createdAt
    }))
  ].sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));

  // Only rebuild the (heavier) inbox when something actually moved.
  const rooms = messages.length > 0 ? await buildInbox(courseId, userId, course) : [];

  const newest = messages.length > 0
    ? messages[messages.length - 1].createdAt
    : cursor;

  return {
    cursor: new Date(newest).toISOString(),
    messages,
    rooms,
    totalUnread: rooms.reduce((sum, r) => sum + r.unreadCount, 0)
  };
}

module.exports = new ChatController();
