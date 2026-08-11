const mongoose = require('mongoose');
const CommunityPost = require('../../models/community/CommunityPost');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS, getCourseMemberIds, getTeacherIds } = require('../../utils/community.utils');
const CommunityNotificationService = require('../../services/community-notification.service');

const POST_TYPES = ['discussion', 'question', 'announcement', 'help'];
const HELP_CATEGORIES = [
  'concept', 'assignment', 'question', 'study_partner', 'technical', 'resource', 'teacher'
];

/** Shared shape for a post in list responses (replies omitted for payload size). */
const mapPost = (post, userId) => ({
  id: String(post._id),
  type: post.type,
  helpCategory: post.helpCategory || null,
  title: post.title || null,
  content: post.content,
  attachments: post.attachments || [],
  tags: post.tags || [],
  author: post.authorId
    ? {
        id: String(post.authorId._id || post.authorId),
        fullName: post.authorId.fullName || 'ECH Student',
        avatar: post.authorId.avatar || null,
        role: post.authorId.role || post.authorRole
      }
    : null,
  authorRole: post.authorRole,
  replyCount: (post.replies || []).length,
  likeCount: (post.likes || []).length,
  isLikedByMe: (post.likes || []).some((l) => String(l) === String(userId)),
  hasTeacherAnswer: (post.replies || []).some(
    (r) => r.authorRole === 'instructor' || r.authorRole === 'admin'
  ),
  isPinned: post.isPinned,
  isResolved: post.isResolved,
  isClosed: post.isClosed,
  viewCount: post.viewCount || 0,
  createdAt: post.createdAt,
  lastActivityAt: post.lastActivityAt
});

const mapReply = (reply, userId) => ({
  id: String(reply._id),
  content: reply.content,
  author: reply.authorId
    ? {
        id: String(reply.authorId._id || reply.authorId),
        fullName: reply.authorId.fullName || 'ECH Student',
        avatar: reply.authorId.avatar || null,
        role: reply.authorId.role || reply.authorRole
      }
    : null,
  authorRole: reply.authorRole,
  isTeacherAnswer: reply.authorRole === 'instructor' || reply.authorRole === 'admin',
  isAccepted: reply.isAccepted,
  isEdited: reply.isEdited,
  likeCount: (reply.likes || []).length,
  isLikedByMe: (reply.likes || []).some((l) => String(l) === String(userId)),
  createdAt: reply.createdAt
});

class DiscussionController {
  /** Feed of discussions / questions / announcements / help requests. */
  async listPosts(req, res) {
    try {
      const { courseId, userId } = req.community;
      const {
        type,
        helpCategory,
        search = '',
        unanswered,
        mine,
        page = 1,
        limit = 20
      } = req.query;

      const pageNum = Math.max(1, parseInt(page, 10) || 1);
      const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));

      const query = { courseId };
      if (type && POST_TYPES.includes(type)) query.type = type;
      if (helpCategory && HELP_CATEGORIES.includes(helpCategory)) query.helpCategory = helpCategory;
      if (mine === 'true') query.authorId = userId;
      if (unanswered === 'true') query.replies = { $size: 0 };
      if (search.trim()) {
        const rx = { $regex: search.trim(), $options: 'i' };
        query.$or = [{ title: rx }, { content: rx }, { tags: rx }];
      }

      const [posts, total] = await Promise.all([
        CommunityPost.find(query)
          .sort({ isPinned: -1, lastActivityAt: -1 })
          .skip((pageNum - 1) * limitNum)
          .limit(limitNum)
          .populate('authorId', PUBLIC_USER_FIELDS)
          .lean(),
        CommunityPost.countDocuments(query)
      ]);

      return sendSuccess(res, {
        posts: posts.map((p) => mapPost(p, userId)),
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          totalPages: Math.ceil(total / limitNum) || 1
        }
      }, 'Posts loaded');
    } catch (error) {
      console.error('Error listing community posts:', error);
      return sendError(res, 'Failed to load posts', 500, error.message);
    }
  }

  /** A single post with its full reply thread. */
  async getPost(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { postId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(postId)) {
        return sendError(res, 'A valid post ID is required', 400);
      }

      const post = await CommunityPost.findOneAndUpdate(
        { _id: postId, courseId },
        { $inc: { viewCount: 1 } },
        { new: true }
      )
        .populate('authorId', PUBLIC_USER_FIELDS)
        .populate('replies.authorId', PUBLIC_USER_FIELDS)
        .lean();

      if (!post) return sendNotFound(res, 'Post not found');

      // Accepted and teacher answers float to the top of the thread.
      const replies = (post.replies || []).slice().sort((a, b) => {
        if (a.isAccepted !== b.isAccepted) return a.isAccepted ? -1 : 1;
        const aTeacher = a.authorRole === 'instructor' || a.authorRole === 'admin';
        const bTeacher = b.authorRole === 'instructor' || b.authorRole === 'admin';
        if (aTeacher !== bTeacher) return aTeacher ? -1 : 1;
        return new Date(a.createdAt) - new Date(b.createdAt);
      });

      return sendSuccess(res, {
        ...mapPost(post, userId),
        replies: replies.map((r) => mapReply(r, userId))
      }, 'Post loaded');
    } catch (error) {
      console.error('Error loading community post:', error);
      return sendError(res, 'Failed to load post', 500, error.message);
    }
  }

  /**
   * Create a discussion, question, help request or announcement.
   * Announcements are teacher-only and notify the whole course.
   */
  async createPost(req, res) {
    try {
      const { courseId, userId, role, isTeacher, course } = req.community;
      const { type = 'discussion', title, content, helpCategory, tags = [], attachments = [] } = req.body;

      if (!content || !content.trim()) {
        return sendError(res, 'Post content is required', 400);
      }
      if (!POST_TYPES.includes(type)) {
        return sendError(res, 'Unknown post type', 400);
      }
      if (type === 'announcement' && !isTeacher) {
        return sendForbidden(res, 'Only the course teacher can post announcements');
      }

      const post = await CommunityPost.create({
        courseId,
        authorId: userId,
        authorRole: role === 'admin' ? 'admin' : role === 'instructor' ? 'instructor' : 'student',
        type,
        title: (title || '').trim() || null,
        content: content.trim(),
        helpCategory: type === 'help' && HELP_CATEGORIES.includes(helpCategory) ? helpCategory : null,
        tags: Array.isArray(tags) ? tags.slice(0, 8).map((t) => String(t).trim()).filter(Boolean) : [],
        attachments: Array.isArray(attachments) ? attachments : [],
        lastActivityAt: new Date()
      });

      const populated = await CommunityPost.findById(post._id)
        .populate('authorId', PUBLIC_USER_FIELDS)
        .lean();

      // Fan-out (fire and forget — never block the response on notifications)
      const authorName = populated.authorId ? populated.authorId.fullName : 'Someone';
      if (type === 'announcement') {
        getCourseMemberIds(courseId).then((ids) =>
          CommunityNotificationService.announcementPosted({
            recipientIds: ids.filter((id) => id !== String(userId)),
            courseId,
            courseTitle: course.title,
            title: post.title || 'Announcement',
            authorName
          })
        );
      } else if (type === 'help' || type === 'question') {
        getTeacherIds(courseId).then((ids) =>
          CommunityNotificationService.helpRequestPosted({
            recipientIds: ids,
            courseId,
            postId: String(post._id),
            askerName: authorName,
            excludeUserId: userId
          })
        );
      }

      return sendSuccess(res, mapPost(populated, userId), 'Post created', 201);
    } catch (error) {
      console.error('Error creating community post:', error);
      return sendError(res, 'Failed to create post', 500, error.message);
    }
  }

  async updatePost(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { postId } = req.params;
      const { title, content, tags } = req.body;

      const post = await CommunityPost.findOne({ _id: postId, courseId });
      if (!post) return sendNotFound(res, 'Post not found');

      if (String(post.authorId) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'You can only edit your own posts');
      }

      if (title !== undefined) post.title = (title || '').trim() || null;
      if (content !== undefined && content.trim()) post.content = content.trim();
      if (Array.isArray(tags)) post.tags = tags.slice(0, 8).map((t) => String(t).trim()).filter(Boolean);
      post.lastActivityAt = new Date();
      await post.save();

      const populated = await CommunityPost.findById(post._id)
        .populate('authorId', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(res, mapPost(populated, userId), 'Post updated');
    } catch (error) {
      console.error('Error updating community post:', error);
      return sendError(res, 'Failed to update post', 500, error.message);
    }
  }

  async deletePost(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { postId } = req.params;

      const post = await CommunityPost.findOne({ _id: postId, courseId });
      if (!post) return sendNotFound(res, 'Post not found');

      if (String(post.authorId) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'You can only delete your own posts');
      }

      await post.deleteOne();
      return sendSuccess(res, null, 'Post deleted');
    } catch (error) {
      console.error('Error deleting community post:', error);
      return sendError(res, 'Failed to delete post', 500, error.message);
    }
  }

  /** Reply to a post. Teacher replies are badged as official guidance. */
  async addReply(req, res) {
    try {
      const { courseId, userId, role, isTeacher } = req.community;
      const { postId } = req.params;
      const { content } = req.body;

      if (!content || !content.trim()) {
        return sendError(res, 'Reply content is required', 400);
      }

      const post = await CommunityPost.findOne({ _id: postId, courseId });
      if (!post) return sendNotFound(res, 'Post not found');
      if (post.isClosed && !isTeacher) {
        return sendForbidden(res, 'This discussion has been closed');
      }

      post.replies.push({
        authorId: userId,
        authorRole: role === 'admin' ? 'admin' : role === 'instructor' ? 'instructor' : 'student',
        content: content.trim()
      });
      post.lastActivityAt = new Date();
      await post.save();

      const populated = await CommunityPost.findById(post._id)
        .populate('replies.authorId', PUBLIC_USER_FIELDS)
        .lean();
      const created = populated.replies[populated.replies.length - 1];

      // Everyone already in the thread hears about the new reply.
      const participantIds = [
        String(post.authorId),
        ...post.replies.map((r) => String(r.authorId))
      ];
      CommunityNotificationService.replyPosted({
        recipientIds: participantIds,
        courseId,
        postId: String(post._id),
        postTitle: post.title || 'a discussion',
        replierName: created.authorId ? created.authorId.fullName : 'Someone',
        isTeacher,
        excludeUserId: userId
      });

      return sendSuccess(res, mapReply(created, userId), 'Reply posted', 201);
    } catch (error) {
      console.error('Error adding reply:', error);
      return sendError(res, 'Failed to post reply', 500, error.message);
    }
  }

  async deleteReply(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { postId, replyId } = req.params;

      const post = await CommunityPost.findOne({ _id: postId, courseId });
      if (!post) return sendNotFound(res, 'Post not found');

      const reply = post.replies.id(replyId);
      if (!reply) return sendNotFound(res, 'Reply not found');

      if (String(reply.authorId) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'You can only delete your own replies');
      }

      reply.deleteOne();
      await post.save();
      return sendSuccess(res, null, 'Reply deleted');
    } catch (error) {
      console.error('Error deleting reply:', error);
      return sendError(res, 'Failed to delete reply', 500, error.message);
    }
  }

  /** Toggle a like on a post, or on one of its replies when `replyId` is given. */
  async toggleLike(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { postId, replyId } = req.params;

      const post = await CommunityPost.findOne({ _id: postId, courseId });
      if (!post) return sendNotFound(res, 'Post not found');

      const target = replyId ? post.replies.id(replyId) : post;
      if (!target) return sendNotFound(res, 'Reply not found');

      const index = target.likes.findIndex((l) => String(l) === String(userId));
      if (index >= 0) target.likes.splice(index, 1);
      else target.likes.push(userId);

      await post.save();
      return sendSuccess(res, {
        liked: index < 0,
        likeCount: target.likes.length
      }, index < 0 ? 'Liked' : 'Like removed');
    } catch (error) {
      console.error('Error toggling like:', error);
      return sendError(res, 'Failed to update like', 500, error.message);
    }
  }

  /** Author or teacher marks the reply that actually answered the question. */
  async acceptReply(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { postId, replyId } = req.params;

      const post = await CommunityPost.findOne({ _id: postId, courseId });
      if (!post) return sendNotFound(res, 'Post not found');

      if (String(post.authorId) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the author or the teacher can accept an answer');
      }

      const reply = post.replies.id(replyId);
      if (!reply) return sendNotFound(res, 'Reply not found');

      const wasAccepted = reply.isAccepted;
      post.replies.forEach((r) => { r.isAccepted = false; });
      reply.isAccepted = !wasAccepted;
      post.isResolved = !wasAccepted;
      await post.save();

      return sendSuccess(res, {
        accepted: reply.isAccepted,
        isResolved: post.isResolved
      }, reply.isAccepted ? 'Answer accepted' : 'Acceptance removed');
    } catch (error) {
      console.error('Error accepting reply:', error);
      return sendError(res, 'Failed to accept answer', 500, error.message);
    }
  }

  /** Teacher-only moderation: pin, close or resolve a thread. */
  async moderatePost(req, res) {
    try {
      const { courseId } = req.community;
      const { postId } = req.params;
      const { isPinned, isClosed, isResolved } = req.body;

      const update = {};
      if (isPinned !== undefined) update.isPinned = Boolean(isPinned);
      if (isClosed !== undefined) update.isClosed = Boolean(isClosed);
      if (isResolved !== undefined) update.isResolved = Boolean(isResolved);

      if (Object.keys(update).length === 0) {
        return sendError(res, 'Nothing to update', 400);
      }

      const post = await CommunityPost.findOneAndUpdate(
        { _id: postId, courseId },
        { $set: update },
        { new: true }
      ).lean();

      if (!post) return sendNotFound(res, 'Post not found');

      return sendSuccess(res, {
        id: String(post._id),
        isPinned: post.isPinned,
        isClosed: post.isClosed,
        isResolved: post.isResolved
      }, 'Post updated');
    } catch (error) {
      console.error('Error moderating post:', error);
      return sendError(res, 'Failed to update post', 500, error.message);
    }
  }
}

module.exports = new DiscussionController();
