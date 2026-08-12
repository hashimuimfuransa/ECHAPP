const mongoose = require('mongoose');

/**
 * One row per push-notification *attempt*.
 *
 * Push failures used to be invisible: `sendPushNotification` swallows its own
 * errors so a dead token can never break the action that triggered it, which
 * also meant nobody could tell a delivered notification from one FCM rejected.
 * This collection is the audit trail behind the admin push report.
 *
 * Rows expire automatically after 30 days — this is operational telemetry, not
 * a permanent record, and the volume would otherwise grow without bound.
 */
const pushLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    index: true
  },
  title: {
    type: String,
    trim: true
  },
  message: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    // sent    – FCM accepted the message and returned a message id
    // failed  – FCM rejected it, or the send threw after all retries
    // skipped – never reached FCM (no token on file, or daily cap hit)
    enum: ['sent', 'failed', 'skipped'],
    required: true,
    index: true
  },
  /** FCM message id, only present on success. */
  messageId: {
    type: String
  },
  /** e.g. 'messaging/registration-token-not-registered', or 'no-token' / 'daily-limit'. */
  errorCode: {
    type: String,
    index: true
  },
  errorMessage: {
    type: String
  },
  /** How many sends were attempted, including retries. */
  attempts: {
    type: Number,
    default: 1
  },
  /** Last 12 characters of the token, enough to tell devices apart in the report. */
  tokenTail: {
    type: String
  },
  /** Where the token came from, so token-sync problems are diagnosable. */
  tokenSource: {
    type: String,
    enum: ['firestore', 'mongodb', 'none'],
    default: 'none'
  },
  createdAt: {
    type: Date,
    default: Date.now
    // Indexed below — the TTL and compound indexes cover it, and declaring
    // `index: true` here as well makes Mongoose warn about a duplicate.
  }
}, {
  timestamps: true
});

// Report queries are always "recent rows, optionally narrowed by status".
pushLogSchema.index({ createdAt: -1, status: 1 });

// Auto-delete after 30 days.
pushLogSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

/**
 * Fire-and-forget writer. Logging must never interfere with the send it is
 * recording, so every failure here is swallowed after a console warning.
 */
pushLogSchema.statics.record = function (entry) {
  return this.create(entry).catch((error) => {
    console.warn('Failed to write push log:', error.message);
  });
};

module.exports = mongoose.model('PushLog', pushLogSchema);
