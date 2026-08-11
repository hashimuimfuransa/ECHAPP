const express = require('express');
const router = express.Router();

const { protect } = require('../middleware/auth.middleware');
const { loadCommunityContext, requireCommunityTeacher } = require('../middleware/community.middleware');

const communityController = require('../controllers/community/community.controller');
const discussionController = require('../controllers/community/discussion.controller');
const groupController = require('../controllers/community/group.controller');
const assignmentController = require('../controllers/community/assignment.controller');
const chatController = require('../controllers/community/chat.controller');
const resourceController = require('../controllers/community/resource.controller');
const sessionController = require('../controllers/community/session.controller');

/**
 * Course Community API — every route lives under a course, and
 * `loadCommunityContext` decides whether the caller is a member, and whether
 * they hold teacher powers, before any handler runs.
 *
 * Mounted at /api/community
 */
router.use('/:courseId', protect, loadCommunityContext);

// ── Dashboard, people & presence ────────────────────────────────
router.get('/:courseId/overview', communityController.getOverview);
router.get('/:courseId/members', communityController.getMembers);
router.get('/:courseId/members/:memberId', communityController.getMemberProfile);
router.post('/:courseId/presence/ping', communityController.ping);
router.patch('/:courseId/presence/visibility', communityController.setPresenceVisibility);

// ── Find study partners ─────────────────────────────────────────
router.get('/:courseId/partners', communityController.listStudyPartners);
router.put('/:courseId/partners/me', communityController.upsertStudyPartnerProfile);
router.delete('/:courseId/partners/me', communityController.removeStudyPartnerProfile);

// ── Discussions, questions, help & announcements ────────────────
router.get('/:courseId/posts', discussionController.listPosts);
router.post('/:courseId/posts', discussionController.createPost);
router.get('/:courseId/posts/:postId', discussionController.getPost);
router.put('/:courseId/posts/:postId', discussionController.updatePost);
router.delete('/:courseId/posts/:postId', discussionController.deletePost);
router.post('/:courseId/posts/:postId/like', discussionController.toggleLike);
router.post('/:courseId/posts/:postId/replies', discussionController.addReply);
router.delete('/:courseId/posts/:postId/replies/:replyId', discussionController.deleteReply);
router.post('/:courseId/posts/:postId/replies/:replyId/like', discussionController.toggleLike);
router.post('/:courseId/posts/:postId/replies/:replyId/accept', discussionController.acceptReply);
router.patch(
  '/:courseId/posts/:postId/moderate',
  requireCommunityTeacher,
  discussionController.moderatePost
);

// ── Study groups ────────────────────────────────────────────────
router.get('/:courseId/groups', groupController.listGroups);
router.post('/:courseId/groups', groupController.createGroup);
router.get('/:courseId/groups/:groupId', groupController.getGroup);
router.put('/:courseId/groups/:groupId', groupController.updateGroup);
router.delete('/:courseId/groups/:groupId', groupController.deleteGroup);
router.post('/:courseId/groups/:groupId/join', groupController.joinGroup);
router.post('/:courseId/groups/:groupId/leave', groupController.leaveGroup);
router.post('/:courseId/groups/:groupId/invite', groupController.inviteMembers);
router.delete('/:courseId/groups/:groupId/members/:memberId', groupController.removeMember);
router.post('/:courseId/groups/:groupId/tasks', groupController.addTask);
router.patch('/:courseId/groups/:groupId/tasks/:taskId', groupController.updateTask);
router.delete('/:courseId/groups/:groupId/tasks/:taskId', groupController.deleteTask);

// ── Chat (course room + per-group rooms) ────────────────────────
router.get('/:courseId/chat/unread', chatController.getUnreadCounts);
router.get('/:courseId/chat/messages', chatController.listMessages);
router.post('/:courseId/chat/messages', chatController.sendMessage);
router.delete('/:courseId/chat/messages/:messageId', chatController.deleteMessage);
router.get('/:courseId/groups/:groupId/chat/messages', chatController.listMessages);
router.post('/:courseId/groups/:groupId/chat/messages', chatController.sendMessage);

// ── Assignments & submissions ───────────────────────────────────
router.get('/:courseId/assignments', assignmentController.listAssignments);
router.post(
  '/:courseId/assignments',
  requireCommunityTeacher,
  assignmentController.createAssignment
);
router.get('/:courseId/assignments/:assignmentId', assignmentController.getAssignment);
router.put(
  '/:courseId/assignments/:assignmentId',
  requireCommunityTeacher,
  assignmentController.updateAssignment
);
router.delete(
  '/:courseId/assignments/:assignmentId',
  requireCommunityTeacher,
  assignmentController.deleteAssignment
);
router.post('/:courseId/assignments/:assignmentId/submit', assignmentController.submit);
router.get(
  '/:courseId/submissions',
  requireCommunityTeacher,
  assignmentController.listSubmissions
);
router.patch(
  '/:courseId/submissions/:submissionId/grade',
  requireCommunityTeacher,
  assignmentController.gradeSubmission
);

// ── Shared resources ────────────────────────────────────────────
router.get('/:courseId/resources', resourceController.listResources);
router.post('/:courseId/resources', resourceController.createResource);
router.delete('/:courseId/resources/:resourceId', resourceController.deleteResource);
router.post('/:courseId/resources/:resourceId/like', resourceController.toggleResourceLike);
router.patch(
  '/:courseId/resources/:resourceId/approve',
  requireCommunityTeacher,
  resourceController.approveResource
);

// ── Study sessions (BigBlueButton-backed peer meetings) ─────────
router.get('/:courseId/sessions', sessionController.listSessions);
router.post('/:courseId/sessions', sessionController.createSession);
router.get('/:courseId/sessions/:sessionId', sessionController.getSession);
router.put('/:courseId/sessions/:sessionId', sessionController.updateSession);
router.delete('/:courseId/sessions/:sessionId', sessionController.cancelSession);
// RSVP ("I'm coming") is separate from actually entering the room
router.post('/:courseId/sessions/:sessionId/rsvp', sessionController.rsvp);
// Returns a BBB join URL — the organiser's first call opens the room
router.post('/:courseId/sessions/:sessionId/join', sessionController.join);
router.post('/:courseId/sessions/:sessionId/end', sessionController.end);
router.get('/:courseId/sessions/:sessionId/recording', sessionController.getRecording);

module.exports = router;
