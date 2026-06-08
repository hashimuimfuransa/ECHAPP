const crypto = require('crypto');
const axios = require('axios');
const BBBConfig = require('../models/BBBConfig');

// Fallback environment variables
const ENV_BBB_SERVER_URL = process.env.BBB_SERVER_URL?.replace(/\/$/, '') || '';
const ENV_BBB_SHARED_SECRET = process.env.BBB_SHARED_SECRET || '';

/**
 * BigBlueButton API Service
 * Handles all BBB API calls with proper checksum authentication
 */
class BBBService {
  /**
   * Get BBB configuration from database or environment
   * @returns {Promise<Object>} BBB config with serverUrl and sharedSecret
   */
  static async getConfig() {
    // Try database first
    const dbConfig = await BBBConfig.getActiveConfig();
    if (dbConfig) {
      return {
        serverUrl: dbConfig.serverUrl.replace(/\/$/, ''),
        sharedSecret: dbConfig.sharedSecret
      };
    }
    
    // Fallback to environment variables
    if (ENV_BBB_SERVER_URL && ENV_BBB_SHARED_SECRET) {
      return {
        serverUrl: ENV_BBB_SERVER_URL,
        sharedSecret: ENV_BBB_SHARED_SECRET
      };
    }
    
    return null;
  }

  /**
   * Generate SHA1 checksum for BBB API call
   * @param {string} apiCall - The API call name (e.g., 'create', 'join')
   * @param {string} queryString - The query string parameters
   * @param {string} sharedSecret - The shared secret
   * @returns {string} SHA1 checksum
   */
  static generateChecksum(apiCall, queryString, sharedSecret) {
    const stringToHash = `${apiCall}${queryString}${sharedSecret}`;
    return crypto.createHash('sha1').update(stringToHash).digest('hex');
  }

  /**
   * Build BBB API URL with checksum
   * @param {string} apiCall - The API call name
   * @param {Object} params - Query parameters
   * @param {Object} config - BBB config with serverUrl and sharedSecret
   * @returns {string} Full API URL
   */
  static buildUrl(apiCall, params = {}, config) {
    const queryString = new URLSearchParams(params).toString();
    const checksum = this.generateChecksum(apiCall, queryString, config.sharedSecret);
    return `${config.serverUrl}/api/${apiCall}?${queryString}&checksum=${checksum}`;
  }

  /**
   * Create a new BBB meeting
   * @param {Object} options - Meeting options
   * @returns {Promise<Object>} Meeting creation response
   */
  static async createMeeting(options) {
    const config = await this.getConfig();
    if (!config) {
      throw new Error('BBB configuration missing. Please configure BBB in admin settings or set environment variables.');
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

    const url = this.buildUrl('create', params, config);
    
    try {
      console.log('BBB Create URL:', url);
      const response = await axios.get(url, { timeout: 30000 });
      console.log('BBB Response:', response.data);
      
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
      console.error('BBB Response data:', error.response?.data || 'No response data');
      throw new Error(`Failed to create BBB meeting: ${error.message}`);
    }
  }

  /**
   * Generate join URL for a meeting
   * @param {Object} options - Join options
   * @returns {Promise<string>} Join URL
   */
  static async getJoinUrl(options) {
    const config = await this.getConfig();
    if (!config) {
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

    return this.buildUrl('join', params, config);
  }

  /**
   * End a BBB meeting
   * @param {string} meetingId - The meeting ID
   * @param {string} moderatorPw - The moderator password
   * @returns {Promise<Object>} End meeting response
   */
  static async endMeeting(meetingId, moderatorPw) {
    const config = await this.getConfig();
    if (!config) {
      throw new Error('BBB configuration missing');
    }

    const params = {
      meetingID: meetingId,
      password: moderatorPw
    };

    const url = this.buildUrl('end', params, config);
    
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
    const config = await this.getConfig();
    if (!config) {
      throw new Error('BBB configuration missing');
    }

    const params = {
      meetingID: meetingId,
      password: moderatorPw
    };

    const url = this.buildUrl('getMeetingInfo', params, config);
    
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
    const config = await this.getConfig();
    if (!config) {
      throw new Error('BBB configuration missing');
    }

    const params = {};
    if (meetingId) {
      params.meetingID = meetingId;
    }

    const url = this.buildUrl('getRecordings', params, config);
    
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
    const config = await this.getConfig();
    if (!config) {
      return false;
    }

    try {
      const params = {};
      const url = this.buildUrl('getMeetings', params, config);
      const response = await axios.get(url, { timeout: 5000 });
      return response.status === 200;
    } catch (error) {
      return false;
    }
  }
}

module.exports = BBBService;
