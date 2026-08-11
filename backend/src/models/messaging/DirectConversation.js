const mongoose = require('mongoose');

/**
 * A one-to-one conversation between two people on the platform.
 *
 * `participantKey` is the sorted pair of user ids and carries a unique index,
 * which is what guarantees a single conversation per pair no matter how many
 * times either side taps "Message" — cheaper and more reliable than trying to
 * match on the unordered `participants` array.
 */
const directConversationSchema = new mongoose.Schema({
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }],
  participantKey: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  lastMessage: {
    content: { type: String, default: '' },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },
    sentAt: { type: Date, default: null },
    hasAttachment: { type: Boolean, default: false }
  },
  lastMessageAt: {
    type: Date,
    default: Date.now
  },
  /** Per-participant unread tally, so the inbox needs no extra aggregation. */
  unread: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    count: { type: Number, default: 0 }
  }],
  /** Blocking is one-directional and mutual in effect: either side blocking stops the thread. */
  blockedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  /** Muted participants still receive messages, just no push notification. */
  mutedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  /** Hidden from this user's inbox until the next message arrives. */
  hiddenBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }]
}, {
  timestamps: true
});

directConversationSchema.index({ participants: 1, lastMessageAt: -1 });

/** Canonical key for a pair, order-independent. */
directConversationSchema.statics.keyFor = function (userA, userB) {
  return [String(userA), String(userB)].sort().join(':');
};

/**
 * Fetch the pair's conversation, creating it on first contact.
 *
 * Uses an upsert on the unique key so two people tapping "Message" at the same
 * moment cannot produce two threads.
 */
directConversationSchema.statics.findOrCreate = async function (userA, userB) {
  const key = this.keyFor(userA, userB);
  return this.findOneAndUpdate(
    { participantKey: key },
    {
      $setOnInsert: {
        participantKey: key,
        participants: [userA, userB],
        lastMessageAt: new Date(),
        unread: [
          { userId: userA, count: 0 },
          { userId: userB, count: 0 }
        ]
      }
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
};

directConversationSchema.methods.otherParticipant = function (userId) {
  return this.participants.find((p) => String(p._id || p) !== String(userId));
};

directConversationSchema.methods.unreadFor = function (userId) {
  const entry = (this.unread || []).find((u) => String(u.userId) === String(userId));
  return entry ? entry.count : 0;
};

directConversationSchema.methods.isBlocked = function () {
  return (this.blockedBy || []).length > 0;
};

module.exports = mongoose.model('DirectConversation', directConversationSchema);
