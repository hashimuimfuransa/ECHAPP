const Notification = require('../models/Notification');
const notificationController = require('../controllers/notification.controller');

/**
 * Fan-out helper for course-community events.
 *
 * Every community notification carries `data.courseId` plus a `community`
 * payload so the app can deep-link straight back into the right tab
 * (discussions, a group, an assignment...) when the notification is tapped.
 *
 * All methods swallow their own errors: a failed notification must never roll
 * back the action that triggered it (posting, submitting, grading...).
 */
class CommunityNotificationService {
  /**
   * Notify a set of users, skipping the actor so nobody is told about their
   * own action. Runs sequentially-ish via Promise.allSettled to avoid one
   * dead FCM token failing the batch.
   */
  static async notifyMany(userIds, { title, message, type = 'info', data = {}, push = true, excludeUserId = null }) {
    try {
      const seen = new Set();
      const targets = (userIds || [])
        .map((id) => String(id))
        .filter((id) => {
          if (!id || id === 'null' || id === 'undefined') return false;
          if (excludeUserId && id === String(excludeUserId)) return false;
          if (seen.has(id)) return false;
          seen.add(id);
          return true;
        });

      if (targets.length === 0) return;

      await Promise.allSettled(
        targets.map(async (userId) => {
          await Notification.createNotification({ userId, title, message, type, data });
          if (push) {
            await notificationController.sendPushNotification(userId, title, message, data, true);
          }
        })
      );
    } catch (error) {
      console.error('Community notification fan-out failed:', error.message);
    }
  }

  static async notifyOne(userId, payload) {
    return this.notifyMany([userId], payload);
  }

  // ── Event helpers ───────────────────────────────────────────────

  static async announcementPosted({ recipientIds, courseId, courseTitle, title, authorName }) {
    return this.notifyMany(recipientIds, {
      title: '📢 New announcement',
      message: `${authorName} posted "${title}" in ${courseTitle}`,
      type: 'course',
      data: { courseId, community: { area: 'discussions' } }
    });
  }

  static async replyPosted({ recipientIds, courseId, postId, postTitle, replierName, isTeacher, excludeUserId }) {
    return this.notifyMany(recipientIds, {
      title: isTeacher ? '👨‍🏫 Teacher answered' : '💬 New reply',
      message: `${replierName} replied to "${postTitle}"`,
      type: 'info',
      data: { courseId, community: { area: 'discussions', postId } },
      excludeUserId
    });
  }

  static async groupInvitation({ recipientIds, courseId, groupId, groupName, inviterName }) {
    return this.notifyMany(recipientIds, {
      title: '👥 Study group invitation',
      message: `${inviterName} invited you to join "${groupName}"`,
      type: 'info',
      data: { courseId, community: { area: 'groups', groupId } }
    });
  }

  static async groupJoined({ recipientIds, courseId, groupId, groupName, memberName, excludeUserId }) {
    return this.notifyMany(recipientIds, {
      title: '👥 New group member',
      message: `${memberName} joined "${groupName}"`,
      type: 'info',
      data: { courseId, community: { area: 'groups', groupId } },
      excludeUserId
    });
  }

  static async assignmentPublished({ recipientIds, courseId, assignmentId, title, dueDate, isGroup }) {
    const due = dueDate ? new Date(dueDate).toDateString() : 'soon';
    return this.notifyMany(recipientIds, {
      title: '📋 New assignment',
      message: `${isGroup ? 'Group assignment' : 'Assignment'} "${title}" is due ${due}`,
      type: 'course',
      data: { courseId, community: { area: 'assignments', assignmentId } }
    });
  }

  static async submissionReceived({ recipientIds, courseId, assignmentId, assignmentTitle, submitterName }) {
    return this.notifyMany(recipientIds, {
      title: '📤 New submission',
      message: `${submitterName} submitted "${assignmentTitle}"`,
      type: 'info',
      data: { courseId, community: { area: 'assignments', assignmentId } }
    });
  }

  static async submissionGraded({ recipientIds, courseId, assignmentId, assignmentTitle, score, maxMarks }) {
    return this.notifyMany(recipientIds, {
      title: '⭐ Assignment returned',
      message: `Your work on "${assignmentTitle}" was graded: ${score}/${maxMarks}`,
      type: 'success',
      data: { courseId, community: { area: 'assignments', assignmentId } }
    });
  }

  static async sessionScheduled({ recipientIds, courseId, sessionId, topic, scheduledAt, organiserName, excludeUserId }) {
    const when = scheduledAt ? new Date(scheduledAt).toLocaleString() : 'soon';
    return this.notifyMany(recipientIds, {
      title: '📅 Study session scheduled',
      message: `${organiserName} scheduled "${topic}" for ${when}`,
      type: 'reminder',
      data: { courseId, community: { area: 'sessions', sessionId } },
      excludeUserId
    });
  }

  static async helpRequestPosted({ recipientIds, courseId, postId, askerName, excludeUserId }) {
    return this.notifyMany(recipientIds, {
      title: '🆘 Someone needs help',
      message: `${askerName} asked a question in your course community`,
      type: 'info',
      data: { courseId, community: { area: 'help', postId } },
      excludeUserId,
      push: false // peers get this in-app only, to keep push volume sane
    });
  }
}

module.exports = CommunityNotificationService;
