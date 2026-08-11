const mongoose = require('mongoose');
const DirectConversation = require('../models/messaging/DirectConversation');
const DirectMessage = require('../models/messaging/DirectMessage');
const Notification = require('../models/Notification');
const notificationController = require('./notification.controller');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');
const {
  PUBLIC_USER_FIELDS,
  canMessage,
  listContactableUsers,
  toContact
} = require('../utils/messaging.utils');

/**
 * One-to-one messaging between people on the platform.
 *
 * Who may talk to whom lives in `messaging.utils.canMessage` — every write
 * path here re-checks it, so revoking access (an unenrolment, a block) takes
 * effect on the next message rather than only at conversation creation.
 */

const mapConversation = (conversation, userId) => {
  const other = (conversation.participants || []).find(
    (p) => String(p._id || p) !== String(userId)
  );
  const unreadEntry = (conversation.unread || []).find(
    (u) => String(u.userId) === String(userId)
  );
  const blockedByMe = (conversation.blockedBy || []).some(
    (b) => String(b) === String(userId)
  );

  return {
    id: String(conversation._id),
    contact: other && other.fullName ? toContact(other) : null,
    lastMessage: conversation.lastMessage
      ? {
          content: conversation.lastMessage.content || '',
          sentAt: conversation.lastMessage.sentAt,
          hasAttachment: Boolean(conversation.lastMessage.hasAttachment),
          isMine:
            String(conversation.lastMessage.senderId || '') === String(userId)
        }
      : null,
    lastMessageAt: conversation.lastMessageAt,
    unreadCount: unreadEntry ? unreadEntry.count : 0,
    isMuted: (conversation.mutedBy || []).some((m) => String(m) === String(userId)),
    isBlockedByMe: blockedByMe,
    /** True when either side has blocked — the composer stays disabled. */
    isBlocked: (conversation.blockedBy || []).length > 0
  };
};

const mapMessage = (message, userId) => ({
  id: String(message._id),
  content: message.isDeleted ? null : message.content || '',
  attachments: message.isDeleted ? [] : message.attachments || [],
  isMine: String(message.senderId && (message.senderId._id || message.senderId)) === String(userId),
  sender:
    message.senderId && message.senderId.fullName
      ? toContact(message.senderId)
      : null,
  context: message.context && message.context.label
    ? {
        courseId: message.context.courseId ? String(message.context.courseId) : null,
        label: message.context.label
      }
    : null,
  replyTo: message.replyTo
    ? {
        id: String(message.replyTo._id || message.replyTo),
        content: message.replyTo.content || null
      }
    : null,
  isRead: Boolean(message.readAt),
  isDeleted: Boolean(message.isDeleted),
  createdAt: message.createdAt
});

class MessagingController {
  /** People this user is allowed to start a conversation with. */
  async getContacts(req, res) {
    try {
      const { search = '', limit = 60 } = req.query;
      const users = await listContactableUsers(req.user, {
        search,
        limit: parseInt(limit, 10) || 60
      });

      // Surface who they already have a thread with, so the picker can show
      // "Recent" ahead of the full list.
      const existing = await DirectConversation.find({ participants: req.user._id })
        .select('participants lastMessageAt')
        .lean();
      const talkedTo = new Map();
      existing.forEach((c) => {
        const other = c.participants.find(
          (p) => String(p) !== String(req.user._id)
        );
        if (other) talkedTo.set(String(other), c.lastMessageAt);
      });

      const contacts = users.map((u) => ({
        ...toContact(u),
        hasConversation: talkedTo.has(String(u._id)),
        lastMessageAt: talkedTo.get(String(u._id)) || null
      }));

      contacts.sort((a, b) => {
        if (a.hasConversation !== b.hasConversation) return a.hasConversation ? -1 : 1;
        if (a.hasConversation && b.hasConversation) {
          return new Date(b.lastMessageAt) - new Date(a.lastMessageAt);
        }
        if (a.isTeacher !== b.isTeacher) return a.isTeacher ? -1 : 1;
        return a.fullName.localeCompare(b.fullName);
      });

      return sendSuccess(res, { contacts }, 'Contacts loaded');
    } catch (error) {
      console.error('Error loading messaging contacts:', error);
      return sendError(res, 'Failed to load contacts', 500, error.message);
    }
  }

  /** The inbox. */
  async listConversations(req, res) {
    try {
      const userId = req.user._id;

      const conversations = await DirectConversation.find({
        participants: userId,
        hiddenBy: { $ne: userId }
      })
        .sort({ lastMessageAt: -1 })
        .limit(100)
        .populate('participants', PUBLIC_USER_FIELDS)
        .lean();

      const mapped = conversations
        .map((c) => mapConversation(c, userId))
        .filter((c) => c.contact !== null);

      return sendSuccess(res, {
        conversations: mapped,
        totalUnread: mapped.reduce((sum, c) => sum + c.unreadCount, 0)
      }, 'Conversations loaded');
    } catch (error) {
      console.error('Error loading conversations:', error);
      return sendError(res, 'Failed to load conversations', 500, error.message);
    }
  }

  /**
   * Open (or resume) a conversation with someone. Idempotent — tapping
   * "Message" repeatedly always lands on the same thread.
   *
   * Returns the first page of messages alongside the conversation. The app
   * opens a chat with only a user id in hand, and making it round-trip twice
   * (resolve, then fetch) doubled the time to first paint on a cold backend.
   */
  async openConversation(req, res) {
    try {
      const userId = req.user._id;
      const { userId: targetId } = req.body;

      const permission = await canMessage(req.user, targetId);
      if (!permission.allowed) {
        return sendForbidden(res, permission.reason);
      }

      const conversation = await DirectConversation.findOrCreate(userId, targetId);

      // Re-opening a thread the user had hidden brings it back.
      if ((conversation.hiddenBy || []).some((h) => String(h) === String(userId))) {
        conversation.hiddenBy = conversation.hiddenBy.filter(
          (h) => String(h) !== String(userId)
        );
        await conversation.save();
      }

      const [populated, messages] = await Promise.all([
        DirectConversation.findById(conversation._id)
          .populate('participants', PUBLIC_USER_FIELDS)
          .lean(),
        DirectMessage.find({ conversationId: conversation._id })
          .sort({ createdAt: -1 })
          .limit(40)
          .populate('senderId', PUBLIC_USER_FIELDS)
          .populate({ path: 'replyTo', select: 'content' })
          .lean()
      ]);

      // Opening the thread clears its unread badge — same as listMessages.
      if (messages.length > 0) {
        Promise.all([
          DirectMessage.updateMany(
            { conversationId: conversation._id, recipientId: userId, readAt: null },
            { $set: { readAt: new Date() } }
          ),
          DirectConversation.updateOne(
            { _id: conversation._id, 'unread.userId': userId },
            { $set: { 'unread.$.count': 0 } }
          )
        ]).catch((e) => console.error('Failed to clear unread on open:', e.message));
      }

      return sendSuccess(res, {
        conversation: mapConversation(populated, userId),
        messages: messages.reverse().map((m) => mapMessage(m, userId)),
        hasMore: messages.length === 40
      }, 'Conversation ready');
    } catch (error) {
      console.error('Error opening conversation:', error);
      return sendError(res, 'Failed to open the conversation', 500, error.message);
    }
  }

  /** Messages in a thread, newest-first page, returned oldest-first. */
  async listMessages(req, res) {
    try {
      const userId = req.user._id;
      const { conversationId } = req.params;
      const { before, limit = 40 } = req.query;

      if (!mongoose.Types.ObjectId.isValid(conversationId)) {
        return sendError(res, 'A valid conversation ID is required', 400);
      }

      const conversation = await DirectConversation.findOne({
        _id: conversationId,
        participants: userId
      })
        .populate('participants', PUBLIC_USER_FIELDS)
        .lean();

      if (!conversation) return sendNotFound(res, 'Conversation not found');

      const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 40));
      const query = { conversationId };
      if (before) {
        const beforeDate = new Date(before);
        if (!Number.isNaN(beforeDate.getTime())) query.createdAt = { $lt: beforeDate };
      }

      const messages = await DirectMessage.find(query)
        .sort({ createdAt: -1 })
        .limit(limitNum)
        .populate('senderId', PUBLIC_USER_FIELDS)
        .populate({ path: 'replyTo', select: 'content' })
        .lean();

      // Opening the thread clears its unread badge.
      await Promise.all([
        DirectMessage.updateMany(
          { conversationId, recipientId: userId, readAt: null },
          { $set: { readAt: new Date() } }
        ),
        DirectConversation.updateOne(
          { _id: conversationId, 'unread.userId': userId },
          { $set: { 'unread.$.count': 0 } }
        )
      ]);

      return sendSuccess(res, {
        conversation: mapConversation(conversation, userId),
        messages: messages.reverse().map((m) => mapMessage(m, userId)),
        hasMore: messages.length === limitNum
      }, 'Messages loaded');
    } catch (error) {
      console.error('Error loading direct messages:', error);
      return sendError(res, 'Failed to load messages', 500, error.message);
    }
  }

  async sendMessage(req, res) {
    try {
      const userId = req.user._id;
      const { conversationId } = req.params;
      const { content = '', attachments = [], replyTo = null, context = null } = req.body;

      if (!content.trim() && (!Array.isArray(attachments) || attachments.length === 0)) {
        return sendError(res, 'Write a message or attach a file', 400);
      }

      const conversation = await DirectConversation.findOne({
        _id: conversationId,
        participants: userId
      });
      if (!conversation) return sendNotFound(res, 'Conversation not found');

      if ((conversation.blockedBy || []).length > 0) {
        const blockedByMe = conversation.blockedBy.some(
          (b) => String(b) === String(userId)
        );
        return sendForbidden(
          res,
          blockedByMe
            ? 'Unblock this person to send them a message'
            : 'You can no longer send messages in this conversation'
        );
      }

      const recipientId = conversation.participants.find(
        (p) => String(p) !== String(userId)
      );

      // Re-check on every send: an unenrolment should end the ability to
      // message, not just the ability to start.
      const permission = await canMessage(req.user, recipientId);
      if (!permission.allowed) {
        return sendForbidden(res, permission.reason);
      }

      const message = await DirectMessage.create({
        conversationId,
        senderId: userId,
        recipientId,
        content: content.trim(),
        attachments: Array.isArray(attachments) ? attachments : [],
        replyTo: replyTo && mongoose.Types.ObjectId.isValid(replyTo) ? replyTo : null,
        context: context && context.label
          ? {
              courseId:
                context.courseId && mongoose.Types.ObjectId.isValid(context.courseId)
                  ? context.courseId
                  : null,
              label: String(context.label).slice(0, 120)
            }
          : undefined
      });

      const preview = content.trim().slice(0, 140);
      conversation.lastMessage = {
        content: preview,
        senderId: userId,
        sentAt: new Date(),
        hasAttachment: Array.isArray(attachments) && attachments.length > 0
      };
      conversation.lastMessageAt = new Date();
      // A new message pulls the thread back into the recipient's inbox.
      conversation.hiddenBy = (conversation.hiddenBy || []).filter(
        (h) => String(h) !== String(recipientId)
      );

      const unreadEntry = conversation.unread.find(
        (u) => String(u.userId) === String(recipientId)
      );
      if (unreadEntry) unreadEntry.count += 1;
      else conversation.unread.push({ userId: recipientId, count: 1 });

      await conversation.save();

      // Notify unless the recipient muted this thread.
      const isMuted = (conversation.mutedBy || []).some(
        (m) => String(m) === String(recipientId)
      );
      if (!isMuted) {
        const body = preview || 'Sent an attachment';
        Notification.createNotification({
          userId: recipientId,
          title: `💬 ${req.user.fullName || 'Someone'}`,
          message: body,
          type: 'info',
          data: {
            messaging: {
              conversationId: String(conversation._id),
              senderId: String(userId)
            }
          }
        }).catch((e) => console.error('DM notification failed:', e.message));

        notificationController
          .sendPushNotification(
            recipientId,
            req.user.fullName || 'New message',
            body,
            { messaging: { conversationId: String(conversation._id) } },
            true
          )
          .catch((e) => console.error('DM push failed:', e.message));
      }

      const populated = await DirectMessage.findById(message._id)
        .populate('senderId', PUBLIC_USER_FIELDS)
        .populate({ path: 'replyTo', select: 'content' })
        .lean();

      return sendSuccess(res, mapMessage(populated, userId), 'Message sent', 201);
    } catch (error) {
      console.error('Error sending direct message:', error);
      return sendError(res, 'Failed to send the message', 500, error.message);
    }
  }

  /** Soft delete so the thread keeps its shape. */
  async deleteMessage(req, res) {
    try {
      const userId = req.user._id;
      const { messageId } = req.params;

      const message = await DirectMessage.findById(messageId);
      if (!message) return sendNotFound(res, 'Message not found');
      if (String(message.senderId) !== String(userId) && req.user.role !== 'admin') {
        return sendForbidden(res, 'You can only delete your own messages');
      }

      message.isDeleted = true;
      message.content = '';
      message.attachments = [];
      await message.save();

      return sendSuccess(res, null, 'Message deleted');
    } catch (error) {
      console.error('Error deleting direct message:', error);
      return sendError(res, 'Failed to delete the message', 500, error.message);
    }
  }

  /** Badge count for the whole inbox. */
  async getUnreadCount(req, res) {
    try {
      const conversations = await DirectConversation.find({
        participants: req.user._id,
        hiddenBy: { $ne: req.user._id }
      })
        .select('unread')
        .lean();

      const total = conversations.reduce((sum, c) => {
        const entry = (c.unread || []).find(
          (u) => String(u.userId) === String(req.user._id)
        );
        return sum + (entry ? entry.count : 0);
      }, 0);

      return sendSuccess(res, { unreadCount: total }, 'Unread count loaded');
    } catch (error) {
      console.error('Error loading unread message count:', error);
      return sendError(res, 'Failed to load unread count', 500, error.message);
    }
  }

  /** Block, unblock, mute or hide a conversation. */
  async updateConversation(req, res) {
    try {
      const userId = req.user._id;
      const { conversationId } = req.params;
      const { blocked, muted, hidden } = req.body;

      const conversation = await DirectConversation.findOne({
        _id: conversationId,
        participants: userId
      });
      if (!conversation) return sendNotFound(res, 'Conversation not found');

      const toggle = (list, on) => {
        const current = (conversation[list] || []).filter(
          (v) => String(v) !== String(userId)
        );
        conversation[list] = on ? [...current, userId] : current;
      };

      if (blocked !== undefined) toggle('blockedBy', Boolean(blocked));
      if (muted !== undefined) toggle('mutedBy', Boolean(muted));
      if (hidden !== undefined) toggle('hiddenBy', Boolean(hidden));

      await conversation.save();

      const populated = await DirectConversation.findById(conversation._id)
        .populate('participants', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(res, mapConversation(populated, userId), 'Conversation updated');
    } catch (error) {
      console.error('Error updating conversation:', error);
      return sendError(res, 'Failed to update the conversation', 500, error.message);
    }
  }
}

module.exports = new MessagingController();
