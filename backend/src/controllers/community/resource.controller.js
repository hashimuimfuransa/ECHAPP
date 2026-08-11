const CommunityResource = require('../../models/community/CommunityResource');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS, toPublicMember } = require('../../utils/community.utils');

// Study sessions moved to session.controller.js when they gained a full
// BigBlueButton lifecycle — this file is now resources only.
const RESOURCE_TYPES = ['document', 'link', 'video', 'note'];

const mapResource = (r, userId) => ({
  id: String(r._id),
  title: r.title,
  description: r.description || '',
  type: r.type,
  source: r.source,
  url: r.url || null,
  body: r.body || null,
  fileName: r.fileName || null,
  mimeType: r.mimeType || null,
  size: r.size || null,
  uploadedBy: r.uploadedBy && r.uploadedBy.fullName ? toPublicMember(r.uploadedBy) : null,
  isApproved: r.isApproved,
  isMine: String(r.uploadedBy && (r.uploadedBy._id || r.uploadedBy)) === String(userId),
  likeCount: (r.likes || []).length,
  isLikedByMe: (r.likes || []).some((l) => String(l) === String(userId)),
  downloadCount: r.downloadCount || 0,
  createdAt: r.createdAt
});


class ResourceController {
  /** Split feed: teacher-published resources vs peer-shared ones. */
  async listResources(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { source, type, search = '' } = req.query;

      const query = { courseId };
      if (source === 'teacher' || source === 'student') query.source = source;
      if (type && RESOURCE_TYPES.includes(type)) query.type = type;
      if (search.trim()) {
        const rx = { $regex: search.trim(), $options: 'i' };
        query.$or = [{ title: rx }, { description: rx }];
      }

      const resources = await CommunityResource.find(query)
        .sort({ createdAt: -1 })
        .limit(200)
        .populate('uploadedBy', PUBLIC_USER_FIELDS)
        .lean();

      const mapped = resources.map((r) => mapResource(r, userId));

      return sendSuccess(res, {
        teacherResources: mapped.filter((r) => r.source === 'teacher'),
        studentResources: mapped.filter((r) => r.source === 'student'),
        total: mapped.length
      }, 'Resources loaded');
    } catch (error) {
      console.error('Error listing community resources:', error);
      return sendError(res, 'Failed to load resources', 500, error.message);
    }
  }

  /**
   * Share a resource. Teacher uploads land in the authoritative section and
   * are approved on the spot; student uploads wait for teacher approval.
   */
  async createResource(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const {
        title,
        description = '',
        type = 'link',
        url = '',
        body = '',
        fileName,
        mimeType,
        size
      } = req.body;

      if (!title || !title.trim()) return sendError(res, 'Resource title is required', 400);
      if (!RESOURCE_TYPES.includes(type)) return sendError(res, 'Unknown resource type', 400);
      if (type !== 'note' && !url.trim()) {
        return sendError(res, 'A link or file URL is required', 400);
      }
      if (type === 'note' && !body.trim()) {
        return sendError(res, 'Write something in the note', 400);
      }

      const resource = await CommunityResource.create({
        courseId,
        uploadedBy: userId,
        source: isTeacher ? 'teacher' : 'student',
        title: title.trim(),
        description: (description || '').trim(),
        type,
        url: (url || '').trim(),
        body: (body || '').trim(),
        fileName: fileName || null,
        mimeType: mimeType || null,
        size: size || null,
        isApproved: isTeacher,
        approvedBy: isTeacher ? userId : null
      });

      const populated = await CommunityResource.findById(resource._id)
        .populate('uploadedBy', PUBLIC_USER_FIELDS)
        .lean();

      return sendSuccess(
        res,
        mapResource(populated, userId),
        isTeacher ? 'Resource shared with the class' : 'Resource shared — a teacher will review it',
        201
      );
    } catch (error) {
      console.error('Error creating community resource:', error);
      return sendError(res, 'Failed to share resource', 500, error.message);
    }
  }

  async deleteResource(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { resourceId } = req.params;

      const resource = await CommunityResource.findOne({ _id: resourceId, courseId });
      if (!resource) return sendNotFound(res, 'Resource not found');
      if (String(resource.uploadedBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'You can only remove resources you shared');
      }

      await resource.deleteOne();
      return sendSuccess(res, null, 'Resource removed');
    } catch (error) {
      console.error('Error deleting community resource:', error);
      return sendError(res, 'Failed to remove resource', 500, error.message);
    }
  }

  /** Teacher quality control over peer-shared material. */
  async approveResource(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { resourceId } = req.params;
      const isApproved = req.body.isApproved !== false;

      const resource = await CommunityResource.findOneAndUpdate(
        { _id: resourceId, courseId },
        { $set: { isApproved, approvedBy: isApproved ? userId : null } },
        { new: true }
      ).lean();

      if (!resource) return sendNotFound(res, 'Resource not found');

      return sendSuccess(res, {
        id: String(resource._id),
        isApproved: resource.isApproved
      }, isApproved ? 'Resource approved' : 'Approval removed');
    } catch (error) {
      console.error('Error approving community resource:', error);
      return sendError(res, 'Failed to update resource', 500, error.message);
    }
  }

  async toggleResourceLike(req, res) {
    try {
      const { courseId, userId } = req.community;
      const { resourceId } = req.params;

      const resource = await CommunityResource.findOne({ _id: resourceId, courseId });
      if (!resource) return sendNotFound(res, 'Resource not found');

      const index = resource.likes.findIndex((l) => String(l) === String(userId));
      if (index >= 0) resource.likes.splice(index, 1);
      else resource.likes.push(userId);
      await resource.save();

      return sendSuccess(res, {
        liked: index < 0,
        likeCount: resource.likes.length
      }, index < 0 ? 'Liked' : 'Like removed');
    } catch (error) {
      console.error('Error liking community resource:', error);
      return sendError(res, 'Failed to update like', 500, error.message);
    }
  }

}

module.exports = new ResourceController();
