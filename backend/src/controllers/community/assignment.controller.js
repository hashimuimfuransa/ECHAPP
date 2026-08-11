const mongoose = require('mongoose');
const CommunityAssignment = require('../../models/community/CommunityAssignment');
const CommunitySubmission = require('../../models/community/CommunitySubmission');
const StudyGroup = require('../../models/community/StudyGroup');
const User = require('../../models/User');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS, getStudentIds, getTeacherIds, toPublicMember } = require('../../utils/community.utils');
const CommunityNotificationService = require('../../services/community-notification.service');

const mapAssignment = (a) => ({
  id: String(a._id),
  title: a.title,
  description: a.description || '',
  type: a.type,
  minGroupSize: a.minGroupSize,
  maxGroupSize: a.maxGroupSize,
  dueDate: a.dueDate,
  maxMarks: a.maxMarks,
  attachments: a.attachments || [],
  allowLateSubmission: a.allowLateSubmission,
  isPublished: a.isPublished,
  isOverdue: new Date(a.dueDate) < new Date(),
  createdAt: a.createdAt
});

const mapSubmission = (s) => ({
  id: String(s._id),
  assignmentId: String(s.assignmentId._id || s.assignmentId),
  group: s.groupId && s.groupId.name
    ? { id: String(s.groupId._id), name: s.groupId.name }
    : (s.groupId ? { id: String(s.groupId), name: null } : null),
  submittedBy: s.submittedBy && s.submittedBy.fullName ? toPublicMember(s.submittedBy) : null,
  members: (s.members || []).map((m) => (m && m.fullName ? toPublicMember(m) : { id: String(m) })),
  comment: s.comment || '',
  files: s.files || [],
  status: s.status,
  isLate: s.isLate,
  submittedAt: s.submittedAt,
  grade: s.grade && s.grade.gradedAt
    ? {
        score: s.grade.score,
        feedback: s.grade.feedback || '',
        gradedAt: s.grade.gradedAt,
        gradedBy: s.grade.gradedBy && s.grade.gradedBy.fullName
          ? toPublicMember(s.grade.gradedBy)
          : null
      }
    : null
});

class AssignmentController {
  /**
   * Assignment list. Students see published work plus their own submission
   * status; teachers additionally see how many submissions await review.
   */
  async listAssignments(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { status = 'all' } = req.query;

      const query = { courseId };
      if (!isTeacher) query.isPublished = true;

      const assignments = await CommunityAssignment.find(query).sort({ dueDate: 1 }).lean();
      const assignmentIds = assignments.map((a) => a._id);

      let mySubmissions = [];
      let counts = {};

      if (isTeacher) {
        const grouped = await CommunitySubmission.aggregate([
          { $match: { assignmentId: { $in: assignmentIds } } },
          {
            $group: {
              _id: '$assignmentId',
              total: { $sum: 1 },
              pending: {
                $sum: { $cond: [{ $in: ['$status', ['submitted', 'under_review']] }, 1, 0] }
              }
            }
          }
        ]);
        grouped.forEach((g) => {
          counts[String(g._id)] = { total: g.total, pending: g.pending };
        });
      } else {
        mySubmissions = await CommunitySubmission.find({
          assignmentId: { $in: assignmentIds },
          members: userId
        })
          .populate('groupId', 'name')
          .lean();
      }

      const submissionByAssignment = {};
      mySubmissions.forEach((s) => {
        submissionByAssignment[String(s.assignmentId)] = s;
      });

      // A student's group for a given assignment decides whether they can submit.
      const myGroups = isTeacher
        ? []
        : await StudyGroup.find({
            courseId,
            isArchived: false,
            members: { $elemMatch: { userId, status: 'active' } }
          })
            .select('name assignmentId members maxMembers')
            .lean();

      let items = assignments.map((a) => {
        const mine = submissionByAssignment[String(a._id)];
        const linkedGroup = myGroups.find((g) => String(g.assignmentId) === String(a._id))
          || (a.type === 'group' ? myGroups[0] : null);

        return {
          ...mapAssignment(a),
          mySubmission: mine ? mapSubmission(mine) : null,
          submissionCounts: counts[String(a._id)] || { total: 0, pending: 0 },
          myGroup: linkedGroup
            ? {
                id: String(linkedGroup._id),
                name: linkedGroup.name,
                memberCount: linkedGroup.members.filter((m) => m.status === 'active').length
              }
            : null,
          needsGroup: !isTeacher && a.type === 'group' && !linkedGroup && !mine
        };
      });

      if (status === 'pending') {
        items = items.filter((i) => (isTeacher ? i.submissionCounts.pending > 0 : !i.mySubmission));
      } else if (status === 'graded') {
        items = items.filter((i) => (isTeacher ? i.submissionCounts.pending === 0 : i.mySubmission && i.mySubmission.grade));
      } else if (status === 'upcoming') {
        items = items.filter((i) => !i.isOverdue);
      }

      return sendSuccess(res, { assignments: items }, 'Assignments loaded');
    } catch (error) {
      console.error('Error listing assignments:', error);
      return sendError(res, 'Failed to load assignments', 500, error.message);
    }
  }

  async getAssignment(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { assignmentId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(assignmentId)) {
        return sendError(res, 'A valid assignment ID is required', 400);
      }

      const assignment = await CommunityAssignment.findOne({ _id: assignmentId, courseId }).lean();
      if (!assignment) return sendNotFound(res, 'Assignment not found');
      if (!assignment.isPublished && !isTeacher) {
        return sendNotFound(res, 'Assignment not found');
      }

      const submissionQuery = { assignmentId };
      if (!isTeacher) submissionQuery.members = userId;

      const submissions = await CommunitySubmission.find(submissionQuery)
        .sort({ submittedAt: -1 })
        .populate('groupId', 'name')
        .populate('submittedBy', PUBLIC_USER_FIELDS)
        .populate('members', PUBLIC_USER_FIELDS)
        .populate('grade.gradedBy', PUBLIC_USER_FIELDS)
        .lean();

      let stats = null;
      if (isTeacher) {
        const studentIds = await getStudentIds(courseId);
        const submittedMembers = new Set();
        submissions.forEach((s) => (s.members || []).forEach((m) => submittedMembers.add(String(m._id || m))));
        stats = {
          enrolledCount: studentIds.length,
          submissionCount: submissions.length,
          submittedStudentCount: submittedMembers.size,
          pendingReview: submissions.filter((s) => s.status !== 'returned').length,
          graded: submissions.filter((s) => s.grade && s.grade.gradedAt).length
        };
      }

      return sendSuccess(res, {
        ...mapAssignment(assignment),
        submissions: submissions.map(mapSubmission),
        stats
      }, 'Assignment loaded');
    } catch (error) {
      console.error('Error loading assignment:', error);
      return sendError(res, 'Failed to load assignment', 500, error.message);
    }
  }

  /** Teacher publishes coursework into the community. */
  async createAssignment(req, res) {
    try {
      const { courseId, userId } = req.community;
      const {
        title,
        description = '',
        type = 'individual',
        minGroupSize = 2,
        maxGroupSize = 6,
        dueDate,
        maxMarks = 20,
        attachments = [],
        allowLateSubmission = false,
        isPublished = true
      } = req.body;

      if (!title || !title.trim()) return sendError(res, 'Assignment title is required', 400);
      if (!dueDate) return sendError(res, 'A due date is required', 400);

      const parsedDue = new Date(dueDate);
      if (Number.isNaN(parsedDue.getTime())) {
        return sendError(res, 'The due date is not a valid date', 400);
      }

      const assignment = await CommunityAssignment.create({
        courseId,
        createdBy: userId,
        title: title.trim(),
        description: (description || '').trim(),
        type: type === 'group' ? 'group' : 'individual',
        minGroupSize: Math.max(1, parseInt(minGroupSize, 10) || 2),
        maxGroupSize: Math.max(1, parseInt(maxGroupSize, 10) || 6),
        dueDate: parsedDue,
        maxMarks: Math.max(1, parseInt(maxMarks, 10) || 20),
        attachments: Array.isArray(attachments) ? attachments : [],
        allowLateSubmission: Boolean(allowLateSubmission),
        isPublished: isPublished !== false
      });

      if (assignment.isPublished) {
        getStudentIds(courseId).then((ids) =>
          CommunityNotificationService.assignmentPublished({
            recipientIds: ids,
            courseId,
            assignmentId: String(assignment._id),
            title: assignment.title,
            dueDate: assignment.dueDate,
            isGroup: assignment.type === 'group'
          })
        );
      }

      return sendSuccess(res, mapAssignment(assignment.toObject()), 'Assignment published', 201);
    } catch (error) {
      console.error('Error creating assignment:', error);
      return sendError(res, 'Failed to create assignment', 500, error.message);
    }
  }

  async updateAssignment(req, res) {
    try {
      const { courseId } = req.community;
      const { assignmentId } = req.params;
      const body = req.body;

      const assignment = await CommunityAssignment.findOne({ _id: assignmentId, courseId });
      if (!assignment) return sendNotFound(res, 'Assignment not found');

      const wasPublished = assignment.isPublished;

      if (body.title !== undefined && body.title.trim()) assignment.title = body.title.trim();
      if (body.description !== undefined) assignment.description = (body.description || '').trim();
      if (body.dueDate !== undefined) {
        const parsed = new Date(body.dueDate);
        if (Number.isNaN(parsed.getTime())) return sendError(res, 'The due date is not a valid date', 400);
        assignment.dueDate = parsed;
      }
      if (body.maxMarks !== undefined) assignment.maxMarks = Math.max(1, parseInt(body.maxMarks, 10) || assignment.maxMarks);
      if (body.type !== undefined) assignment.type = body.type === 'group' ? 'group' : 'individual';
      if (body.minGroupSize !== undefined) assignment.minGroupSize = Math.max(1, parseInt(body.minGroupSize, 10) || assignment.minGroupSize);
      if (body.maxGroupSize !== undefined) assignment.maxGroupSize = Math.max(1, parseInt(body.maxGroupSize, 10) || assignment.maxGroupSize);
      if (body.allowLateSubmission !== undefined) assignment.allowLateSubmission = Boolean(body.allowLateSubmission);
      if (Array.isArray(body.attachments)) assignment.attachments = body.attachments;
      if (body.isPublished !== undefined) assignment.isPublished = Boolean(body.isPublished);

      await assignment.save();

      // Publishing a previously-hidden assignment still notifies the class.
      if (!wasPublished && assignment.isPublished) {
        getStudentIds(courseId).then((ids) =>
          CommunityNotificationService.assignmentPublished({
            recipientIds: ids,
            courseId,
            assignmentId: String(assignment._id),
            title: assignment.title,
            dueDate: assignment.dueDate,
            isGroup: assignment.type === 'group'
          })
        );
      }

      return sendSuccess(res, mapAssignment(assignment.toObject()), 'Assignment updated');
    } catch (error) {
      console.error('Error updating assignment:', error);
      return sendError(res, 'Failed to update assignment', 500, error.message);
    }
  }

  async deleteAssignment(req, res) {
    try {
      const { courseId } = req.community;
      const { assignmentId } = req.params;

      const assignment = await CommunityAssignment.findOneAndDelete({ _id: assignmentId, courseId });
      if (!assignment) return sendNotFound(res, 'Assignment not found');

      await CommunitySubmission.deleteMany({ assignmentId });
      return sendSuccess(res, null, 'Assignment deleted');
    } catch (error) {
      console.error('Error deleting assignment:', error);
      return sendError(res, 'Failed to delete assignment', 500, error.message);
    }
  }

  /**
   * Student (or group) submits work. For group assignments the caller must be
   * an active member of the group they are submitting for, and the whole group
   * is recorded as the submission's members so everyone gets the grade.
   */
  async submit(req, res) {
    try {
      const { courseId, userId, isStudent } = req.community;
      const { assignmentId } = req.params;
      const { groupId = null, comment = '', files = [] } = req.body;

      if (!isStudent) {
        return sendForbidden(res, 'Only students can submit assignments');
      }

      const assignment = await CommunityAssignment.findOne({
        _id: assignmentId,
        courseId,
        isPublished: true
      });
      if (!assignment) return sendNotFound(res, 'Assignment not found');

      const isLate = new Date() > new Date(assignment.dueDate);
      if (isLate && !assignment.allowLateSubmission) {
        return sendError(res, 'The deadline for this assignment has passed', 400);
      }
      if (!Array.isArray(files) || files.length === 0) {
        return sendError(res, 'Attach at least one file before submitting', 400);
      }

      let members = [userId];
      let resolvedGroupId = null;

      if (assignment.type === 'group') {
        if (!groupId || !mongoose.Types.ObjectId.isValid(groupId)) {
          return sendError(res, 'Select the group you are submitting for', 400);
        }
        const group = await StudyGroup.findOne({ _id: groupId, courseId, isArchived: false });
        if (!group) return sendNotFound(res, 'Study group not found');
        if (!group.isActiveMember(userId)) {
          return sendForbidden(res, 'You are not a member of that group');
        }
        const active = group.members.filter((m) => m.status === 'active');
        if (active.length < assignment.minGroupSize) {
          return sendError(
            res,
            `This assignment needs at least ${assignment.minGroupSize} group members`,
            400
          );
        }
        members = active.map((m) => m.userId);
        resolvedGroupId = group._id;
      }

      // Re-submitting replaces the previous attempt and reopens it for review.
      const filter = assignment.type === 'group'
        ? { assignmentId, groupId: resolvedGroupId }
        : { assignmentId, groupId: null, submittedBy: userId };

      const submission = await CommunitySubmission.findOneAndUpdate(
        filter,
        {
          $set: {
            assignmentId,
            courseId,
            groupId: resolvedGroupId,
            submittedBy: userId,
            members,
            comment: (comment || '').trim(),
            files,
            status: 'submitted',
            isLate,
            submittedAt: new Date(),
            grade: { score: null, feedback: '', gradedBy: null, gradedAt: null }
          }
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );

      const [submitter, teacherIds] = await Promise.all([
        User.findById(userId).select('fullName').lean(),
        getTeacherIds(courseId)
      ]);

      CommunityNotificationService.submissionReceived({
        recipientIds: teacherIds,
        courseId,
        assignmentId: String(assignmentId),
        assignmentTitle: assignment.title,
        submitterName: submitter ? submitter.fullName : 'A student'
      });

      const populated = await CommunitySubmission.findById(submission._id)
        .populate('groupId', 'name')
        .populate('submittedBy', PUBLIC_USER_FIELDS)
        .populate('members', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(res, mapSubmission(populated), 'Work submitted to your teacher', 201);
    } catch (error) {
      console.error('Error submitting assignment:', error);
      return sendError(res, 'Failed to submit assignment', 500, error.message);
    }
  }

  /** Teacher review queue across the whole course. */
  async listSubmissions(req, res) {
    try {
      const { courseId } = req.community;
      const { status, assignmentId } = req.query;

      const query = { courseId };
      if (status && ['submitted', 'under_review', 'returned'].includes(status)) query.status = status;
      if (assignmentId && mongoose.Types.ObjectId.isValid(assignmentId)) query.assignmentId = assignmentId;

      const submissions = await CommunitySubmission.find(query)
        .sort({ submittedAt: -1 })
        .limit(200)
        .populate('assignmentId', 'title maxMarks dueDate type')
        .populate('groupId', 'name')
        .populate('submittedBy', PUBLIC_USER_FIELDS)
        .populate('members', PUBLIC_USER_FIELDS)
        .populate('grade.gradedBy', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(res, {
        submissions: submissions.map((s) => ({
          ...mapSubmission(s),
          assignment: s.assignmentId && s.assignmentId.title
            ? {
                id: String(s.assignmentId._id),
                title: s.assignmentId.title,
                maxMarks: s.assignmentId.maxMarks,
                dueDate: s.assignmentId.dueDate,
                type: s.assignmentId.type
              }
            : null
        }))
      }, 'Submissions loaded');
    } catch (error) {
      console.error('Error listing submissions:', error);
      return sendError(res, 'Failed to load submissions', 500, error.message);
    }
  }

  /** Teacher grades a submission; every member of the group is notified. */
  async gradeSubmission(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { submissionId } = req.params;
      const { score, feedback = '', status = 'returned' } = req.body;

      const submission = await CommunitySubmission.findOne({ _id: submissionId, courseId })
        .populate('assignmentId', 'title maxMarks');
      if (!submission) return sendNotFound(res, 'Submission not found');

      const maxMarks = submission.assignmentId ? submission.assignmentId.maxMarks : 100;
      const parsedScore = Number(score);

      if (status === 'returned') {
        if (Number.isNaN(parsedScore)) return sendError(res, 'A numeric score is required', 400);
        if (parsedScore < 0 || parsedScore > maxMarks) {
          return sendError(res, `Score must be between 0 and ${maxMarks}`, 400);
        }
        submission.grade = {
          score: parsedScore,
          feedback: (feedback || '').trim(),
          gradedBy: userId,
          gradedAt: new Date()
        };
        submission.status = 'returned';
      } else {
        submission.status = 'under_review';
      }

      await submission.save();

      if (submission.status === 'returned') {
        CommunityNotificationService.submissionGraded({
          recipientIds: submission.members.map(String),
          courseId,
          assignmentId: String(submission.assignmentId._id || submission.assignmentId),
          assignmentTitle: submission.assignmentId ? submission.assignmentId.title : 'your assignment',
          score: parsedScore,
          maxMarks
        });
      }

      const populated = await CommunitySubmission.findById(submission._id)
        .populate('groupId', 'name')
        .populate('submittedBy', PUBLIC_USER_FIELDS)
        .populate('members', PUBLIC_USER_FIELDS)
        .populate('grade.gradedBy', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(res, mapSubmission(populated), 'Submission updated');
    } catch (error) {
      console.error('Error grading submission:', error);
      return sendError(res, 'Failed to grade submission', 500, error.message);
    }
  }
}

module.exports = new AssignmentController();
