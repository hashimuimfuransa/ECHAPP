const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  role: {
    type: String,
    enum: ['owner', 'member'],
    default: 'member'
  },
  status: {
    type: String,
    enum: ['invited', 'active', 'requested', 'left'],
    default: 'active'
  },
  joinedAt: {
    type: Date,
    default: Date.now
  }
}, { _id: false });

/** A checklist item the group works through together. */
const taskSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Task title is required'],
    trim: true,
    maxlength: [200, 'Task title cannot exceed 200 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [2000, 'Task description cannot exceed 2000 characters']
  },
  assignedTo: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  dueDate: Date,
  isDone: {
    type: Boolean,
    default: false
  },
  completedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  completedAt: Date,
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, { timestamps: true });

const studyGroupSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  name: {
    type: String,
    required: [true, 'Group name is required'],
    trim: true,
    maxlength: [120, 'Group name cannot exceed 120 characters']
  },
  purpose: {
    type: String,
    enum: ['exam_prep', 'assignment', 'revision', 'project', 'practice', 'general'],
    default: 'general'
  },
  description: {
    type: String,
    trim: true,
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  maxMembers: {
    type: Number,
    default: 6,
    min: [2, 'A group needs at least 2 members'],
    max: [50, 'A group cannot exceed 50 members']
  },
  members: [memberSchema],
  tasks: [taskSchema],
  /** Open groups can be joined directly; closed ones need an invite. */
  isOpen: {
    type: Boolean,
    default: true
  },
  /** Set when the group was formed to work on a specific assignment. */
  assignmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CommunityAssignment',
    default: null
  },
  isArchived: {
    type: Boolean,
    default: false
  },
  lastActivityAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

studyGroupSchema.index({ courseId: 1, isArchived: 1, lastActivityAt: -1 });
studyGroupSchema.index({ courseId: 1, 'members.userId': 1 });

studyGroupSchema.virtual('memberCount').get(function () {
  if (!this.members) return 0;
  return this.members.filter((m) => m.status === 'active').length;
});

studyGroupSchema.virtual('openTaskCount').get(function () {
  if (!this.tasks) return 0;
  return this.tasks.filter((t) => !t.isDone).length;
});

studyGroupSchema.methods.isActiveMember = function (userId) {
  const id = String(userId);
  return this.members.some((m) => String(m.userId) === id && m.status === 'active');
};

studyGroupSchema.methods.isOwner = function (userId) {
  const id = String(userId);
  return this.members.some(
    (m) => String(m.userId) === id && m.role === 'owner' && m.status === 'active'
  );
};

module.exports = mongoose.model('StudyGroup', studyGroupSchema);
