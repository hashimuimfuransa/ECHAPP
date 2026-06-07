const crypto = require('crypto');
const axios = require('axios');

const BBB_SERVER_URL = process.env.BBB_SERVER_URL?.replace(/\/$/, '') || '';
const BBB_SHARED_SECRET = process.env.BBB_SHARED_SECRET || '';

/**
 * BigBlueButton API Service
 * Handles all BBB API calls with proper checksum authentication
 */
class BBBService {
  /**
   * Generate SHA1 checksum for BBB API call
   * @param {string} apiCall - The API call name (e.g., 'create', 'join')
   * @param {string} queryString - The query string parameters
   * @returns {string} SHA1 checksum
   */
  static generateChecksum(apiCall, queryString) {
    const stringToHash = `${apiCall}${queryString}${BBB_SHARED_SECRET}`;
    return crypto.createHash('sha1').update(stringToHash).digest('hex');
  }

  /**
   * Build BBB API URL with checksum
   * @param {string} apiCall - The API call name
   * @param {Object} params - Query parameters
   * @returns {string} Full API URL
   */
  static buildUrl(apiCall, params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const checksum = this.generateChecksum(apiCall, queryString);
    return `${BBB_SERVER_URL}/api/${apiCall}?${queryString}&checksum=${checksum}`;
  }

  /**
   * Create a new BBB meeting
   * @param {Object} options - Meeting options
   * @returns {Promise<Object>} Meeting creation response
   */
  static async createMeeting(options) {
    if (!BBB_SERVER_URL || !BBB_SHARED_SECRET) {
      throw new Error('BBB configuration missing. Check BBB_SERVER_URL and BBB_SHARED_SECRET env vars.');
    }

    const {
      name,
      meetingId,
      attendeePw,
      moderatorPw,
      duration,
      maxParticipants = 100,
      record = true,
      allowStartStopRecording = true,
      autoStartRecording = false,
      muteOnStart = true,
      welcomeMsg,
      meta = {}
    } = options;

    const params = {
      name: name || 'Untitled Meeting',
      meetingID: meetingId || `meeting_${Date.now()}`,
      attendeePW: attendeePw || `att_${crypto.randomBytes(4).toString('hex')}`,
      moderatorPW: moderatorPw || `mod_${crypto.randomBytes(4).toString('hex')}`,
      duration: duration || 60,
      maxParticipants: maxParticipants.toString(),
      record: record.toString(),
      allowStartStopRecording: allowStartStopRecording.toString(),
      autoStartRecording: autoStartRecording.toString(),
      muteOnStart: muteOnStart.toString(),
      ...Object.entries(meta).reduce((acc, [key, val]) => {
        acc[`meta_${key}`] = val;
        return acc;
      }, {})
    };

    if (welcomeMsg) {
      params.welcome = welcomeMsg;
    }

    const url = this.buildUrl('create', params);
    
    try {
      const response = await axios.get(url, { timeout: 30000 });
      const parser = new (require('xml2js').Parser)({ explicitArray: false });
      const result = await parser.parseStringPromise(response.data);
      
      if (result.response.returncode === 'SUCCESS') {
        return {
          success: true,
          meetingId: result.response.meetingID,
          internalMeetingId: result.response.internalMeetingID,
          attendeePw: result.response.attendeePW,
          moderatorPw: result.response.moderatorPW,
          createTime: result.response.createTime,
          createDate: result.response.createDate
        };
      } else {
        throw new Error(result.response.message || 'Failed to create meeting');
      }
    } catch (error) {
      console.error('BBB Create Meeting Error:', error.message);
      throw new Error(`Failed to create BBB meeting: ${error.message}`);
    }
  }

  /**
   * Generate join URL for a meeting
   * @param {Object} options - Join options
   * @returns {string} Join URL
   */
  static getJoinUrl(options) {
    if (!BBB_SERVER_URL || !BBB_SHARED_SECRET) {
      throw new Error('BBB configuration missing');
    }

    const {
      fullName,
      meetingId,
      password,
      userId,
      isModerator = false,
      redirect = true
    } = options;

    const params = {
      fullName: fullName || 'Guest',
      meetingID: meetingId,
      password: password,
      redirect: redirect.toString()
    };

    if (userId) {
      params.userID = userId;
    }

    // Add role parameter for moderators
    if (isModerator) {
      params.role = 'moderator';
    }

    return this.buildUrl('join', params);
  }

  /**
   * End a BBB meeting
   * @param {string} meetingId - The meeting ID
   * @param {string} moderatorPw - The moderator password
   * @returns {Promise<Object>} End meeting response
   */
  static async endMeeting(meetingId, moderatorPw) {
    if (!BBB_SERVER_URL || !BBB_SHARED_SECRET) {
      throw new Error('BBB configuration missing');
    }

    const params = {
      meetingID: meetingId,
      password: moderatorPw
    };

    const url = this.buildUrl('end', params);
    
    try {
      const response = await axios.get(url, { timeout: 10000 });
      const parser = new (require('xml2js').Parser)({ explicitArray: false });
      const result = await parser.parseStringPromise(response.data);
      
      return {
        success: result.response.returncode === 'SUCCESS',
        message: result.response.message
      };
    } catch (error) {
      console.error('BBB End Meeting Error:', error.message);
      throw new Error(`Failed to end meeting: ${error.message}`);
    }
  }

  /**
   * Get meeting info
   * @param {string} meetingId - The meeting ID
   * @param {string} moderatorPw - The moderator password
   * @returns {Promise<Object>} Meeting info
   */
  static async getMeetingInfo(meetingId, moderatorPw) {
    if (!BBB_SERVER_URL || !BBB_SHARED_SECRET) {
      throw new Error('BBB configuration missing');
    }

    const params = {
      meetingID: meetingId,
      password: moderatorPw
    };

    const url = this.buildUrl('getMeetingInfo', params);
    
    try {
      const response = await axios.get(url, { timeout: 10000 });
      const parser = new (require('xml2js').Parser)({ explicitArray: false });
      const result = await parser.parseStringPromise(response.data);
      
      if (result.response.returncode === 'SUCCESS') {
        return {
          success: true,
          meetingId: result.response.meetingID,
          meetingName: result.response.meetingName,
          isRunning: result.response.running === 'true',
          hasUserJoined: result.response.hasUserJoined === 'true',
          participantCount: parseInt(result.response.participantCount || 0),
          moderatorCount: parseInt(result.response.moderatorCount || 0),
          attendees: result.response.attendees?.attendee || []
        };
      } else {
        return { success: false, message: result.response.message };
      }
    } catch (error) {
      console.error('BBB Get Meeting Info Error:', error.message);
      throw new Error(`Failed to get meeting info: ${error.message}`);
    }
  }

  /**
   * Get recordings for a meeting
   * @param {string} meetingId - The meeting ID (optional, gets all if not provided)
   * @returns {Promise<Array>} Recordings list
   */
  static async getRecordings(meetingId = null) {
    if (!BBB_SERVER_URL || !BBB_SHARED_SECRET) {
      throw new Error('BBB configuration missing');
    }

    const params = {};
    if (meetingId) {
      params.meetingID = meetingId;
    }

    const url = this.buildUrl('getRecordings', params);
    
    try {
      const response = await axios.get(url, { timeout: 10000 });
      const parser = new (require('xml2js').Parser)({ explicitArray: false });
      const result = await parser.parseStringPromise(response.data);
      
      if (result.response.returncode === 'SUCCESS') {
        const recordings = result.response.recordings?.recording;
        if (!recordings) return [];
        
        // Handle single recording or array
        const recordingsArray = Array.isArray(recordings) ? recordings : [recordings];
        
        return recordingsArray.map(r => ({
          recordId: r.recordID,
          meetingId: r.meetingID,
          internalMeetingId: r.internalMeetingID,
          name: r.name,
          published: r.published === 'true',
          state: r.state,
          startTime: parseInt(r.startTime),
          endTime: parseInt(r.endTime),
          participants: parseInt(r.participants || 0),
          playback: r.playback?.format?.url || null,
          playbackType: r.playback?.format?.type || null,
          duration: parseInt(r.playback?.format?.length || 0)
        }));
      } else {
        return [];
      }
    } catch (error) {
      console.error('BBB Get Recordings Error:', error.message);
      return [];
    }
  }

  /**
   * Check if BBB server is available
   * @returns {Promise<boolean>}
   */
  static async isAvailable() {
    if (!BBB_SERVER_URL || !BBB_SHARED_SECRET) {
      return false;
    }

    try {
      const params = {};
      const url = this.buildUrl('getMeetings', params);
      const response = await axios.get(url, { timeout: 5000 });
      return response.status === 200;
    } catch (error) {
      return false;
    }
  }
}

module.exports = BBBService;
