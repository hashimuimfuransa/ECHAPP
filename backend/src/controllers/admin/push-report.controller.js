const PushLog = require('../../models/PushLog');
const { sendSuccess, sendError } = require('../../utils/response.utils');

/**
 * Push delivery report for administrators.
 *
 * `sendPushNotification` deliberately swallows its own errors so a dead token
 * can never break the action that triggered it. That makes silent failure the
 * default, so every attempt is written to PushLog and surfaced here: what was
 * delivered, what FCM rejected and why, and what never left the server.
 */

/** Human wording for the error codes an admin will actually see. */
const ERROR_EXPLANATIONS = {
  'no-token': 'The user has no FCM token — they have never opened the app on a device, or the token was cleared after a failure.',
  'daily-limit': 'Skipped by the daily notification cap for this user.',
  'user-not-found': 'No user record matched the id the notification was sent to.',
  'messaging/registration-token-not-registered': 'The device token is no longer valid — the app was uninstalled, or the token was rotated. It has been cleared; the user must reopen the app.',
  'messaging/invalid-registration-token': 'The stored token is malformed and has been cleared.',
  'messaging/mismatched-credential': 'The token belongs to a different Firebase project than the server credentials.',
  'messaging/invalid-payload': 'FCM rejected the message contents (for example a non-string value in the data payload).',
  'messaging/invalid-argument': 'FCM rejected the message contents (for example a non-string value in the data payload).',
  'messaging/server-unavailable': 'FCM was temporarily unavailable and the retries were exhausted.',
  'messaging/internal-error': 'FCM returned an internal error and the retries were exhausted.',
  'messaging/third-party-auth-error': 'APNs credentials are missing or invalid for this iOS device.',
  'internal-error': 'The server threw before the message could be sent.',
  'unknown-error': 'The send failed without reporting an error code.'
};

const explain = (code) => ERROR_EXPLANATIONS[code] || null;

const mapLog = (log) => ({
  id: String(log._id),
  userId: log.userId ? String(log.userId._id || log.userId) : null,
  userName: log.userId && log.userId.fullName ? log.userId.fullName : null,
  userEmail: log.userId && log.userId.email ? log.userId.email : null,
  title: log.title || '',
  message: log.message || '',
  status: log.status,
  messageId: log.messageId || null,
  errorCode: log.errorCode || null,
  errorMessage: log.errorMessage || null,
  explanation: explain(log.errorCode),
  attempts: log.attempts || 0,
  tokenTail: log.tokenTail || null,
  tokenSource: log.tokenSource || 'none',
  timestamp: log.createdAt
});

class AdminPushReportController {
  /**
   * Summary + paginated log of push attempts.
   *
   * Query: `days` (default 7), `status` ('sent'|'failed'|'skipped'|'all'),
   * `search` (title, message or error code), `page`, `limit`.
   *
   * Summary counts always cover the whole window regardless of the status
   * filter, so the totals stay stable while an admin drills into failures.
   */
  async report(req, res) {
    try {
      const days = Math.min(Math.max(parseInt(req.query.days, 10) || 7, 1), 90);
      const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
      const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 200);
      const status = req.query.status && req.query.status !== 'all' ? req.query.status : null;
      const search = (req.query.search || '').trim();

      const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
      const windowFilter = { createdAt: { $gte: since } };

      const listFilter = { ...windowFilter };
      if (status) listFilter.status = status;
      if (search) {
        const rx = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
        listFilter.$or = [{ title: rx }, { message: rx }, { errorCode: rx }];
      }

      const [statusCounts, errorCounts, daily, total, logs] = await Promise.all([
        PushLog.aggregate([
          { $match: windowFilter },
          { $group: { _id: '$status', count: { $sum: 1 } } }
        ]),
        PushLog.aggregate([
          { $match: { ...windowFilter, status: { $in: ['failed', 'skipped'] } } },
          { $group: { _id: { code: '$errorCode', status: '$status' }, count: { $sum: 1 } } },
          { $sort: { count: -1 } },
          { $limit: 12 }
        ]),
        PushLog.aggregate([
          { $match: windowFilter },
          {
            $group: {
              _id: {
                day: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
                status: '$status'
              },
              count: { $sum: 1 }
            }
          },
          { $sort: { '_id.day': 1 } }
        ]),
        PushLog.countDocuments(listFilter),
        PushLog.find(listFilter)
          .populate('userId', 'fullName email')
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit)
          .lean()
      ]);

      const counts = { sent: 0, failed: 0, skipped: 0 };
      statusCounts.forEach((row) => {
        if (row._id in counts) counts[row._id] = row.count;
      });
      const attempted = counts.sent + counts.failed + counts.skipped;

      // Collapse the per-day aggregate into one row per day for charting.
      const byDay = {};
      daily.forEach((row) => {
        const day = row._id.day;
        byDay[day] = byDay[day] || { date: day, sent: 0, failed: 0, skipped: 0 };
        byDay[day][row._id.status] = row.count;
      });

      return sendSuccess(res, {
        window: { days, since },
        summary: {
          total: attempted,
          sent: counts.sent,
          failed: counts.failed,
          skipped: counts.skipped,
          // Share of attempts FCM actually accepted. Skipped rows count against
          // it on purpose: from the user's side, a skipped push is a push they
          // never got.
          deliveryRate: attempted > 0 ? Number(((counts.sent / attempted) * 100).toFixed(1)) : 0
        },
        breakdown: errorCounts.map((row) => ({
          code: row._id.code || 'unknown-error',
          status: row._id.status,
          count: row.count,
          explanation: explain(row._id.code)
        })),
        daily: Object.values(byDay),
        logs: logs.map(mapLog),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.max(Math.ceil(total / limit), 1),
          hasMore: page * limit < total
        }
      }, 'Push delivery report retrieved successfully');
    } catch (error) {
      console.error('Error building push report:', error);
      return sendError(res, 'Failed to build the push delivery report', 500, error.message);
    }
  }
}

module.exports = new AdminPushReportController();
