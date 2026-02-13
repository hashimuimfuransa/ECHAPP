const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Groq = require('groq-sdk');
const { spawn } = require('child_process');
const router = express.Router();

// Set up multer for audio file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/voice';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'voice-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: (req, file, cb) => {
    // Accept only audio files
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files are allowed'));
    }
  }
});

// In-memory storage for conversations (same as ai_chat)
const conversations = new Map();

// Initialize the AI clients
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY || 'your-google-api-key-here');
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || 'your-groq-api-key-here' });

// Voice transcription using Whisper-like model via OpenAI-compatible API
async function transcribeAudio(audioFilePath) {
  // This would typically use a service like OpenAI Whisper API or similar
  // For this implementation, we'll simulate the transcription
  // In a real implementation, you would use the actual transcription service
  
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      // Simulated transcription - in reality, this would process the audio file
      resolve("Hello, how can I help you with your learning today?");
    }, 1000);
  });
}

// Text-to-Speech simulation (in a real implementation, you'd use a TTS service)
async function generateSpeech(text, outputFile) {
  // This would typically use a TTS service like Google TTS, Amazon Polly, etc.
  // For this implementation, we'll just return a placeholder
  return { audioUrl: `/uploads/voice/response-${Date.now()}.mp3` };
}

// Endpoint to handle voice message
router.post('/voice/send', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Audio file is required' });
    }

    const { conversationId, context } = req.body;
    
    // Transcribe the audio to text
    const transcribedText = await transcribeAudio(req.file.path);
    
    // Get or create conversation
    let conversation = conversations.get(conversationId);
    if (!conversation) {
      const { v4: uuidv4 } = require('uuid');
      const newConversationId = uuidv4();
      conversation = {
        id: newConversationId,
        context: context || {},
        messages: [],
        createdAt: new Date()
      };
      conversations.set(newConversationId, conversation);
    }
    
    // Add user's transcribed message to conversation
    const userMessage = {
      id: `user_${Date.now()}`,
      sender: 'user',
      message: transcribedText,
      originalAudio: req.file.path,
      timestamp: new Date(),
      isContextAware: false
    };
    
    conversation.messages.push(userMessage);
    
    // Prepare messages for Groq API (including context)
    const messagesForAI = [
      {
        role: 'system',
        content: createContextAwareSystemPrompt(conversation.context)
      },
      ...conversation.messages.slice(-10).map(msg => ({ // Use last 10 messages for context
        role: msg.sender === 'user' ? 'user' : 'assistant',
        content: msg.message
      }))
    ];
    
    // Generate AI response using Groq (Grok model)
    const chatCompletion = await groq.chat.completions.create({
      messages: messagesForAI,
      model: "mixtral-8x7b-32768", // Using Mixtral as a placeholder; replace with actual Grok model when available
      temperature: 0.7,
      max_tokens: 1024,
      top_p: 1,
      stream: false
    });
    
    const aiResponse = chatCompletion.choices[0]?.message?.content || "I'm having trouble responding right now. Could you try asking again?";
    
    // Generate speech for the AI response
    const speechResult = await generateSpeech(aiResponse, `response-${Date.now()}.mp3`);
    
    // Add AI response to conversation
    const aiMessage = {
      id: `ai_${Date.now()}`,
      sender: 'ai',
      message: aiResponse,
      audioUrl: speechResult.audioUrl,
      timestamp: new Date(),
      isContextAware: true
    };
    
    conversation.messages.push(aiMessage);
    
    // Update context if provided
    if (context) {
      conversation.context = { ...conversation.context, ...context };
    }
    
    res.json({
      textResponse: aiResponse,
      audioResponse: speechResult.audioUrl,
      conversationId: conversation.id
    });
  } catch (error) {
    console.error('Error processing voice message:', error);
    res.status(500).json({ 
      error: 'Failed to process voice message', 
      message: 'I\'m having trouble processing your voice message. Could you try again?'
    });
  }
});

// Alternative endpoint for real-time voice processing (streaming)
router.post('/voice/stream', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Audio file is required' });
    }

    const { conversationId, context } = req.body;
    
    // Transcribe the audio to text
    const transcribedText = await transcribeAudio(req.file.path);
    
    // Get or create conversation
    let conversation = conversations.get(conversationId);
    if (!conversation) {
      const { v4: uuidv4 } = require('uuid');
      const newConversationId = uuidv4();
      conversation = {
        id: newConversationId,
        context: context || {},
        messages: [],
        createdAt: new Date()
      };
      conversations.set(newConversationId, conversation);
    }
    
    // Add user's transcribed message to conversation
    const userMessage = {
      id: `user_${Date.now()}`,
      sender: 'user',
      message: transcribedText,
      originalAudio: req.file.path,
      timestamp: new Date(),
      isContextAware: false
    };
    
    conversation.messages.push(userMessage);
    
    // Prepare messages for AI
    const messagesForAI = [
      {
        role: 'system',
        content: createContextAwareSystemPrompt(conversation.context)
      },
      ...conversation.messages.slice(-10).map(msg => ({
        role: msg.sender === 'user' ? 'user' : 'assistant',
        content: msg.message
      }))
    ];
    
    // Create a streaming response
    res.setHeader('Content-Type', 'text/plain');
    res.setHeader('Transfer-Encoding', 'chunked');
    
    // Use Groq streaming for real-time response
    const chatStream = await groq.chat.completions.create({
      messages: messagesForAI,
      model: "mixtral-8x7b-32768",
      temperature: 0.7,
      max_tokens: 1024,
      top_p: 1,
      stream: true
    });
    
    let fullResponse = '';
    for await (const chunk of chatStream) {
      const content = chunk.choices[0]?.delta?.content || '';
      fullResponse += content;
      res.write(content);
    }
    
    // Add AI response to conversation
    const aiMessage = {
      id: `ai_${Date.now()}`,
      sender: 'ai',
      message: fullResponse,
      timestamp: new Date(),
      isContextAware: true
    };
    
    conversation.messages.push(aiMessage);
    
    res.end();
  } catch (error) {
    console.error('Error processing voice stream:', error);
    res.status(500).json({ 
      error: 'Failed to process voice stream' 
    });
  }
});

// Endpoint to get voice response as audio
router.get('/voice/response/:conversationId/:messageId', (req, res) => {
  try {
    const { conversationId, messageId } = req.params;
    const conversation = conversations.get(conversationId);
    
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    // Find the message with audio
    const message = conversation.messages.find(msg => msg.id === messageId);
    if (!message || !message.audioUrl) {
      return res.status(404).json({ error: 'Audio response not found' });
    }
    
    // Serve the audio file
    const filePath = path.join(__dirname, '../', message.audioUrl);
    res.sendFile(filePath);
  } catch (error) {
    console.error('Error serving audio:', error);
    res.status(500).json({ error: 'Failed to serve audio' });
  }
});

// Helper function to create context-aware system prompt
function createContextAwareSystemPrompt(context) {
  let prompt = `You are an AI Learning Assistant helping a student with their education. `;
  
  if (context.courseTitle) {
    prompt += `The student is studying "${context.courseTitle}". `;
  }
  
  if (context.lessonTitle) {
    prompt += `They are currently working on "${context.lessonTitle}". `;
  }
  
  if (context.studentName) {
    prompt += `The student's name is ${context.studentName}. `;
  }
  
  if (context.studentLevel) {
    prompt += `Their current level is ${context.studentLevel}. `;
  }
  
  prompt += `Provide helpful, educational responses that relate to their current learning context. `;
  prompt += `Keep your responses informative, encouraging, and tailored to their specific learning situation. `;
  prompt += `If they're struggling with a concept, offer to break it down into simpler parts. `;
  prompt += `If they're asking for practice, suggest relevant exercises. `;
  prompt += `Always maintain a supportive and educational tone.`;
  
  return prompt;
}

module.exports = router;