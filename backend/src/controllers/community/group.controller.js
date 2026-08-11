const mongoose = require('mongoose');
const StudyGroup = require('../../models/community/StudyGroup');
const CommunitySubmission = require('../../models/community/CommunitySubmission');
const StudySession = require('../../models/community/StudySession');
const User = require('../../models/User');
const Enrollment = require('../../models/Enrollment');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS, getPresenceMap, toPublicMember } = require('../../utils/community.utils');
const CommunityNotificationService = require('../../services/community-notification.service');

const PURPOSES = ['exam_prep', 'assignment', 'revision', 'project', 'practice', 'general'];

const activeMembers = (group) => group.members.filter((m) => m.status === 'active');

/** Members whose user document was removed are skipped rather than crashing. */
const memberIdOf = (member) => {
  if (!member || !member.userId) return null;
  return String(member.userId._id || member.userId);
};

const mapGroupSummary = (group, userId) => {
  const active = (group.members || []).filter((m) => m.status === 'active' && m.userId);
  const mine = (group.members || []).find((m) => memberIdOf(m) === String(userId));
  return {
    id: String(group._id),
    name: group.name,
    purpose: group.purpose,
    description: group.description || '',
    memberCount: active.length,
    maxMembers: group.maxMembers,
    isOpen: group.isOpen,
    isFull: active.length >= group.maxMembers,
    taskCount: (group.tasks || []).length,
    openTaskCount: (group.tasks || []).filter((t) => !t.isDone).length,
    myStatus: mine ? mine.status : null,
    myRole: mine ? mine.role : null,
    assignmentId: group.assignmentId ? String(group.assignmentId) : null,
    lastActivityAt: group.lastActivityAt,
    createdAt: group.createdAt,
    memberPreview: active.slice(0, 5).map((m) =>
      m.userId && m.userId.fullName
        ? { id: String(m.userId._id), fullName: m.userId.fullName, avatar: m.userId.avatar || null }
        : { id: String(m.userId), fullName: 'ECH Student', avatar: null }
    )
  };
};

class GroupController {
  /** All groups in the course, with `mine=true` narrowing to my own. */
  async listGroups(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { mine, search = '', purpose, openOnly } = req.query;

      const query = { courseId, isArchived: false };
      if (mine === 'true') {
        query.members = { $elemMatch: { userId, status: 'active' } };
      }
      if (purpose && PURPOSES.includes(purpose)) query.purpose = purpose;
      if (search.trim()) query.name = { $regex: search.trim(), $options: 'i' };

      let groups = await StudyGroup.find(query)
        .sort({ lastActivityAt: -1 })
        .limit(100)
        .populate('members.userId', PUBLIC_USER_FIELDS)
        .lean();

      if (openOnly === 'true') {
        groups = groups.filter(
          (g) => g.isOpen && g.members.filter((m) => m.status === 'active').length < g.maxMembers
        );
      }

      return sendSuccess(res, {
        groups: groups.map((g) => mapGroupSummary(g, userId))
      }, 'Groups loaded');
    } catch (error) {
      console.error('Error listing study groups:', error);
      return sendError(res, 'Failed to load study groups', 500, error.message);
    }
  }

  /** Full group workspace: members, tasks, submissions and sessions. */
  async getGroup(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(groupId)) {
        return sendError(res, 'A valid group ID is required', 400);
      }

      const group = await StudyGroup.findOne({ _id: groupId, courseId })
        .populate('members.userId', PUBLIC_USER_FIELDS)
        .populate('tasks.assignedTo', PUBLIC_USER_FIELDS)
        .lean();

      if (!group) return sendNotFound(res, 'Study group not found');

      const membership = group.members.find(
        (m) => memberIdOf(m) === String(userId)
      );
      const isMember = membership && membership.status === 'active';

      // Teachers can inspect any group in their course; students need to belong
      // to it (or have a pending invite) before seeing tasks and files.
      if (!isMember && !isTeacher && !(membership && membership.status === 'invited')) {
        return sendForbidden(res, 'You are not a member of this group');
      }

      const presentMembers = group.members.filter((m) => m.userId);
      const memberIds = presentMembers.map((m) => m.userId._id || m.userId);
      const [presence, submissions, sessions] = await Promise.all([
        getPresenceMap(courseId, memberIds),
        CommunitySubmission.find({ groupId })
          .sort({ submittedAt: -1 })
          .populate('assignmentId', 'title maxMarks dueDate type')
          .lean(),
        StudySession.find({ groupId, status: 'scheduled' })
          .sort({ scheduledAt: 1 })
          .limit(10)
          .lean()
      ]);

      return sendSuccess(res, {
        ...mapGroupSummary(group, userId),
        canManage: Boolean(
          (membership && membership.role === 'owner' && membership.status === 'active') || isTeacher
        ),
        isTeacherView: Boolean(isTeacher && !isMember),
        members: presentMembers.map((m) => ({
          ...toPublicMember(m.userId, presence[String(m.userId._id || m.userId)]),
          groupRole: m.role,
          status: m.status,
          joinedAt: m.joinedAt
        })),
        tasks: (group.tasks || [])
          .slice()
          .sort((a, b) => Number(a.isDone) - Number(b.isDone) || new Date(a.createdAt) - new Date(b.createdAt))
          .map((t) => ({
            id: String(t._id),
            title: t.title,
            description: t.description || '',
            isDone: t.isDone,
            dueDate: t.dueDate,
            assignedTo: (t.assignedTo || []).map((u) => toPublicMember(u)),
            completedBy: t.completedBy ? String(t.completedBy) : null,
            completedAt: t.completedAt,
            createdAt: t.createdAt
          })),
        submissions: submissions.map((s) => ({
          id: String(s._id),
          assignment: s.assignmentId
            ? {
                id: String(s.assignmentId._id),
                title: s.assignmentId.title,
                maxMarks: s.assignmentId.maxMarks,
                dueDate: s.assignmentId.dueDate,
                type: s.assignmentId.type
              }
            : null,
          status: s.status,
          submittedAt: s.submittedAt,
          isLate: s.isLate,
          files: s.files,
          comment: s.comment,
          grade: s.grade && s.grade.gradedAt ? s.grade : null
        })),
        sessions: sessions.map((s) => ({
          id: String(s._id),
          topic: s.topic,
          scheduledAt: s.scheduledAt,
          durationMinutes: s.durationMinutes,
          participantCount: s.participants.length,
          meetingLink: s.meetingLink || null
        }))
      }, 'Group loaded');
    } catch (error) {
      console.error('Error loading study group:', error);
      return sendError(res, 'Failed to load study group', 500, error.message);
    }
  }

  /** Create a group; the creator becomes the owner, invitees get a pending invite. */
  async createGroup(req, res) {
    try {
      const { courseId, userId, course } = req.community;
      const {
        name,
        purpose = 'general',
        description = '',
        maxMembers = 6,
        inviteUserIds = [],
        isOpen = true,
        assignmentId = null
      } = req.body;

      if (!name || !name.trim()) {
        return sendError(res, 'Group name is required', 400);
      }

      const cap = Math.min(50, Math.max(2, parseInt(maxMembers, 10) || 6));

      // Only people actually enrolled in this course can be invited.
      const validInviteIds = Array.isArray(inviteUserIds)
        ? inviteUserIds.filter((id) => mongoose.Types.ObjectId.isValid(id) && String(id) !== String(userId))
        : [];
      const enrolledInvites = validInviteIds.length
        ? (await Enrollment.find({ courseId, userId: { $in: validInviteIds } }).select('userId').lean())
            .map((e) => String(e.userId))
        : [];

      const members = [{ userId, role: 'owner', status: 'active', joinedAt: new Date() }];
      enrolledInvites.slice(0, cap - 1).forEach((id) => {
        members.push({ userId: id, role: 'member', status: 'invited' });
      });

      const group = await StudyGroup.create({
        courseId,
        name: name.trim(),
        purpose: PURPOSES.includes(purpose) ? purpose : 'general',
        description: (description || '').trim(),
        createdBy: userId,
        maxMembers: cap,
        members,
        isOpen: isOpen !== false,
        assignmentId: assignmentId && mongoose.Types.ObjectId.isValid(assignmentId) ? assignmentId : null,
        lastActivityAt: new Date()
      });

      if (enrolledInvites.length) {
        const inviter = await User.findById(userId).select('fullName').lean();
        CommunityNotificationService.groupInvitation({
          recipientIds: enrolledInvites,
          courseId,
          groupId: String(group._id),
          groupName: group.name,
          inviterName: inviter ? inviter.fullName : 'A classmate'
        });
      }

      const populated = await StudyGroup.findById(group._id)
        .populate('members.userId', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(res, mapGroupSummary(populated, userId), `"${group.name}" created in ${course.title}`, 201);
    } catch (error) {
      console.error('Error creating study group:', error);
      return sendError(res, 'Failed to create study group', 500, error.message);
    }
  }

  async updateGroup(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId } = req.params;
      const { name, purpose, description, maxMembers, isOpen, isArchived } = req.body;

      const group = await StudyGroup.findOne({ _id: groupId, courseId });
      if (!group) return sendNotFound(res, 'Study group not found');
      if (!group.isOwner(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the group owner can change these settings');
      }

      if (name !== undefined && name.trim()) group.name = name.trim();
      if (purpose !== undefined && PURPOSES.includes(purpose)) group.purpose = purpose;
      if (description !== undefined) group.description = (description || '').trim();
      if (maxMembers !== undefined) {
        const cap = Math.min(50, Math.max(2, parseInt(maxMembers, 10) || group.maxMembers));
        if (cap < activeMembers(group).length) {
          return sendError(res, 'The new limit is below the current member count', 400);
        }
        group.maxMembers = cap;
      }
      if (isOpen !== undefined) group.isOpen = Boolean(isOpen);
      if (isArchived !== undefined) group.isArchived = Boolean(isArchived);
      group.lastActivityAt = new Date();
      await group.save();

      const populated = await StudyGroup.findById(group._id)
        .populate('members.userId', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(res, mapGroupSummary(populated, userId), 'Group updated');
    } catch (error) {
      console.error('Error updating study group:', error);
      return sendError(res, 'Failed to update study group', 500, error.message);
    }
  }

  async deleteGroup(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId } = req.params;

      const group = await StudyGroup.findOne({ _id: groupId, courseId });
      if (!group) return sendNotFound(res, 'Study group not found');
      if (!group.isOwner(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the group owner can delete this group');
      }

      // Archive rather than destroy so submissions keep pointing at something real.
      group.isArchived = true;
      await group.save();
      return sendSuccess(res, null, 'Group archived');
    } catch (error) {
      console.error('Error deleting study group:', error);
      return sendError(res, 'Failed to delete study group', 500, error.message);
    }
  }

  /** Join an open group, or accept a pending invite. */
  async joinGroup(req, res) {
    try {
      const { courseId, userId, isStudent } = req.community;
      const { groupId } = req.params;

      if (!isStudent) {
        return sendForbidden(res, 'Only students can join study groups');
      }

      const group = await StudyGroup.findOne({ _id: groupId, courseId, isArchived: false });
      if (!group) return sendNotFound(res, 'Study group not found');

      const existing = group.members.find((m) => String(m.userId) === String(userId));
      if (existing && existing.status === 'active') {
        return sendError(res, 'You are already a member of this group', 400);
      }
      if (activeMembers(group).length >= group.maxMembers) {
        return sendError(res, 'This group is already full', 400);
      }

      if (existing) {
        // Accepting an invite, or rejoining after leaving
        if (existing.status === 'invited' || existing.status === 'left' || group.isOpen) {
          existing.status = 'active';
          existing.joinedAt = new Date();
        } else {
          existing.status = 'requested';
        }
      } else if (group.isOpen) {
        group.members.push({ userId, role: 'member', status: 'active', joinedAt: new Date() });
      } else {
        group.members.push({ userId, role: 'member', status: 'requested' });
      }

      group.lastActivityAt = new Date();
      await group.save();

      const me = group.members.find((m) => String(m.userId) === String(userId));
      if (me.status === 'active') {
        const user = await User.findById(userId).select('fullName').lean();
        CommunityNotificationService.groupJoined({
          recipientIds: activeMembers(group).map((m) => String(m.userId)),
          courseId,
          groupId: String(group._id),
          groupName: group.name,
          memberName: user ? user.fullName : 'A classmate',
          excludeUserId: userId
        });
      }

      return sendSuccess(res, { status: me.status }, me.status === 'active' ? 'You joined the group' : 'Join request sent');
    } catch (error) {
      console.error('Error joining study group:', error);
      return sendError(res, 'Failed to join study group', 500, error.message);
    }
  }

  async leaveGroup(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { groupId } = req.params;

      const group = await StudyGroup.findOne({ _id: groupId, courseId });
      if (!group) return sendNotFound(res, 'Study group not found');

      const membership = group.members.find((m) => String(m.userId) === String(userId));
      if (!membership || membership.status !== 'active') {
        return sendError(res, 'You are not a member of this group', 400);
      }

      const remaining = activeMembers(group).filter((m) => String(m.userId) !== String(userId));
      if (membership.role === 'owner' && remaining.length > 0) {
        // Hand ownership to the longest-standing remaining member.
        remaining.sort((a, b) => new Date(a.joinedAt) - new Date(b.joinedAt));
        remaining[0].role = 'owner';
      }

      membership.status = 'left';
      group.lastActivityAt = new Date();

      if (remaining.length === 0) group.isArchived = true;
      await group.save();

      return sendSuccess(res, null, 'You left the group');
    } catch (error) {
      console.error('Error leaving study group:', error);
      return sendError(res, 'Failed to leave study group', 500, error.message);
    }
  }

  /** Owner invites more classmates into the group. */
  async inviteMembers(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId } = req.params;
      const { userIds = [] } = req.body;

      const group = await StudyGroup.findOne({ _id: groupId, courseId, isArchived: false });
      if (!group) return sendNotFound(res, 'Study group not found');
      if (!group.isOwner(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the group owner can invite members');
      }

      const candidates = (Array.isArray(userIds) ? userIds : []).filter((id) =>
        mongoose.Types.ObjectId.isValid(id)
      );
      if (candidates.length === 0) return sendError(res, 'No members to invite', 400);

      const enrolled = (await Enrollment.find({ courseId, userId: { $in: candidates } })
        .select('userId')
        .lean()).map((e) => String(e.userId));

      const room = group.maxMembers - activeMembers(group).length;
      const invited = [];

      enrolled.forEach((id) => {
        if (invited.length >= room) return;
        const existing = group.members.find((m) => String(m.userId) === id);
        if (existing) {
          if (existing.status === 'left') { existing.status = 'invited'; invited.push(id); }
          else if (existing.status === 'requested') { existing.status = 'active'; existing.joinedAt = new Date(); invited.push(id); }
        } else {
          group.members.push({ userId: id, role: 'member', status: 'invited' });
          invited.push(id);
        }
      });

      group.lastActivityAt = new Date();
      await group.save();

      if (invited.length) {
        const inviter = await User.findById(userId).select('fullName').lean();
        CommunityNotificationService.groupInvitation({
          recipientIds: invited,
          courseId,
          groupId: String(group._id),
          groupName: group.name,
          inviterName: inviter ? inviter.fullName : 'A classmate'
        });
      }

      return sendSuccess(res, { invited: invited.length }, `${invited.length} invitation(s) sent`);
    } catch (error) {
      console.error('Error inviting group members:', error);
      return sendError(res, 'Failed to invite members', 500, error.message);
    }
  }

  async removeMember(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId, memberId } = req.params;

      const group = await StudyGroup.findOne({ _id: groupId, courseId });
      if (!group) return sendNotFound(res, 'Study group not found');
      if (!group.isOwner(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the group owner can remove members');
      }
      if (String(memberId) === String(userId)) {
        return sendError(res, 'Use "leave group" to remove yourself', 400);
      }

      const membership = group.members.find((m) => String(m.userId) === String(memberId));
      if (!membership) return sendNotFound(res, 'That member is not in this group');

      membership.status = 'left';
      group.lastActivityAt = new Date();
      await group.save();

      return sendSuccess(res, null, 'Member removed');
    } catch (error) {
      console.error('Error removing group member:', error);
      return sendError(res, 'Failed to remove member', 500, error.message);
    }
  }

  // ── Group tasks ────────────────────────────────────────────────

  async addTask(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId } = req.params;
      const { title, description = '', assignedTo = [], dueDate } = req.body;

      if (!title || !title.trim()) return sendError(res, 'Task title is required', 400);

      const group = await StudyGroup.findOne({ _id: groupId, courseId, isArchived: false });
      if (!group) return sendNotFound(res, 'Study group not found');
      if (!group.isActiveMember(userId) && !isTeacher) {
        return sendForbidden(res, 'Only group members can add tasks');
      }

      const memberIds = new Set(activeMembers(group).map((m) => String(m.userId)));
      const assignees = (Array.isArray(assignedTo) ? assignedTo : []).filter(
        (id) => mongoose.Types.ObjectId.isValid(id) && memberIds.has(String(id))
      );

      group.tasks.push({
        title: title.trim(),
        description: (description || '').trim(),
        assignedTo: assignees,
        dueDate: dueDate ? new Date(dueDate) : undefined,
        createdBy: userId
      });
      group.lastActivityAt = new Date();
      await group.save();

      const created = group.tasks[group.tasks.length - 1];
      return sendSuccess(res, {
        id: String(created._id),
        title: created.title,
        description: created.description,
        isDone: created.isDone,
        dueDate: created.dueDate,
        assignedTo: assignees.map(String)
      }, 'Task added', 201);
    } catch (error) {
      console.error('Error adding group task:', error);
      return sendError(res, 'Failed to add task', 500, error.message);
    }
  }

  async updateTask(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId, taskId } = req.params;
      const { title, description, isDone, dueDate, assignedTo } = req.body;

      const group = await StudyGroup.findOne({ _id: groupId, courseId });
      if (!group) return sendNotFound(res, 'Study group not found');
      if (!group.isActiveMember(userId) && !isTeacher) {
        return sendForbidden(res, 'Only group members can update tasks');
      }

      const task = group.tasks.id(taskId);
      if (!task) return sendNotFound(res, 'Task not found');

      if (title !== undefined && title.trim()) task.title = title.trim();
      if (description !== undefined) task.description = (description || '').trim();
      if (dueDate !== undefined) task.dueDate = dueDate ? new Date(dueDate) : null;
      if (Array.isArray(assignedTo)) {
        const memberIds = new Set(activeMembers(group).map((m) => String(m.userId)));
        task.assignedTo = assignedTo.filter(
          (id) => mongoose.Types.ObjectId.isValid(id) && memberIds.has(String(id))
        );
      }
      if (isDone !== undefined) {
        task.isDone = Boolean(isDone);
        task.completedBy = task.isDone ? userId : null;
        task.completedAt = task.isDone ? new Date() : null;
      }

      group.lastActivityAt = new Date();
      await group.save();

      return sendSuccess(res, {
        id: String(task._id),
        title: task.title,
        description: task.description,
        isDone: task.isDone,
        dueDate: task.dueDate,
        completedBy: task.completedBy ? String(task.completedBy) : null,
        completedAt: task.completedAt
      }, 'Task updated');
    } catch (error) {
      console.error('Error updating group task:', error);
      return sendError(res, 'Failed to update task', 500, error.message);
    }
  }

  async deleteTask(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { groupId, taskId } = req.params;

      const group = await StudyGroup.findOne({ _id: groupId, courseId });
      if (!group) return sendNotFound(res, 'Study group not found');
      if (!group.isActiveMember(userId) && !isTeacher) {
        return sendForbidden(res, 'Only group members can delete tasks');
      }

      const task = group.tasks.id(taskId);
      if (!task) return sendNotFound(res, 'Task not found');

      task.deleteOne();
      group.lastActivityAt = new Date();
      await group.save();

      return sendSuccess(res, null, 'Task deleted');
    } catch (error) {
      console.error('Error deleting group task:', error);
      return sendError(res, 'Failed to delete task', 500, error.message);
    }
  }
}

module.exports = new GroupController();
