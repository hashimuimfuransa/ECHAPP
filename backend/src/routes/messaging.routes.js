const express = require('express');
const router = express.Router();

const { protect } = require('../middleware/auth.middleware');
const messagingController = require('../controllers/messaging.controller');

/**
 * One-to-one messaging. Mounted at /api/messages.
 *
 * Not scoped to a course: a conversation outlives any single course, so the
 * inbox spans everything. Who may message whom is enforced per-request in
 * `messaging.utils.canMessage`.
 */
router.use(protect);

// Who I can start a conversation with
router.get('/contacts', messagingController.getContacts);

// Inbox
router.get('/conversations', messagingController.listConversations);
router.post('/conversations', messagingController.openConversation);
router.get('/conversations/:conversationId/messages', messagingController.listMessages);
router.post('/conversations/:conversationId/messages', messagingController.sendMessage);
router.patch('/conversations/:conversationId', messagingController.updateConversation);

router.delete('/messages/:messageId', messagingController.deleteMessage);
router.get('/unread', messagingController.getUnreadCount);

module.exports = router;
