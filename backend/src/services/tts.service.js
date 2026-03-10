const axios = require('axios');
const fs = require('fs');
const path = require('path');

class TTSService {
  constructor() {
    this.apiKey = process.env.ELEVENLABS_API_KEY;
    this.voiceId = process.env.ELEVENLABS_VOICE_ID || 'nT6n6V0X6o7O6b6E6R6E'; // Default: Brian (Deep, Professional British)
    // Previous: 'pNInz6obpgnuM07pZNoR' (Adam - British Male)
  }

  /**
   * Generate speech from text and save to file
   * @param {string} text The text to convert to speech
   * @param {string} outputFile Path to save the audio file
   * @returns {Promise<string>} Path to the generated audio file
   */
  async generateSpeech(text, outputFile) {
    if (!this.apiKey) {
      console.warn('ELEVENLABS_API_KEY not found in .env. Falling back to frontend TTS.');
      return null;
    }

    try {
      const response = await axios({
        method: 'post',
        url: `https://api.elevenlabs.io/v1/text-to-speech/${this.voiceId}`,
        data: {
          text: text,
          model_id: 'eleven_monolingual_v1', // High quality monolingual model
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
            style: 0.0,
            use_speaker_boost: true
          }
        },
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': this.apiKey,
          'Content-Type': 'application/json'
        },
        responseType: 'stream'
      });

      const writer = fs.createWriteStream(outputFile);
      response.data.pipe(writer);

      return new Promise((resolve, reject) => {
        writer.on('finish', () => resolve(outputFile));
        writer.on('error', reject);
      });
    } catch (error) {
      console.error('TTS Generation error:', error.response?.data || error.message);
      return null;
    }
  }
}

module.exports = new TTSService();
