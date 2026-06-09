const axios = require('axios');
const fs = require('fs');
const path = require('path');

class TTSService {
  constructor() {
    this.apiKey = process.env.ELEVENLABS_API_KEY;
    this.voiceId = process.env.ELEVENLABS_VOICE_ID || 'pNInz6obpgnuM07pZNoR'; // Default: Adam (British Male)
    this._disabled = false; // set true if account-level error encountered
  }

  /**
   * Generate speech from text and save to file
   * @param {string} text The text to convert to speech
   * @param {string} outputFile Path to save the audio file
   * @returns {Promise<string|null>} Path to the generated audio file, or null on failure
   */
  async generateSpeech(text, outputFile) {
    if (!this.apiKey || this._disabled) {
      return null;
    }

    try {
      const response = await axios({
        method: 'post',
        url: `https://api.elevenlabs.io/v1/text-to-speech/${this.voiceId}`,
        data: {
          text: text,
          model_id: 'eleven_turbo_v2_5',
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
        writer.on('error', (err) => {
          if (fs.existsSync(outputFile)) fs.unlinkSync(outputFile);
          reject(err);
        });
      });
    } catch (error) {
      if (error.response && error.response.data && typeof error.response.data.on === 'function') {
        const chunks = [];
        for await (const chunk of error.response.data) {
          chunks.push(chunk);
        }
        const body = Buffer.concat(chunks).toString();
        let parsed;
        try { parsed = JSON.parse(body); } catch (_) { parsed = body; }
        const status = parsed?.detail?.status ?? '';
        if (status === 'detected_unusual_activity' || error.response.status === 402) {
          console.warn('TTS: ElevenLabs account blocked or payment required — disabling TTS for this session. Frontend TTS will be used.');
          this._disabled = true;
        } else {
          console.error('TTS Generation error (from API):', body);
        }
      } else {
        console.error('TTS Generation error:', error.response?.data || error.message);
      }
      return null;
    }
  }
}

module.exports = new TTSService();
