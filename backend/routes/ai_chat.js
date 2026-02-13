const express = require('express');
const Groq = require('groq-sdk'); // Using Groq SDK which works with Grok models
const { v4: uuidv4 } = require('uuid');
const router = express.Router();

// In-memory storage for conversations (in production, use a database)
const conversations = new Map();

// Initialize the Groq client for Grok models
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || 'your-groq-api-key-here' });

// Endpoint to create a new conversation
router.post('/conversations/create', async (req, res) => {
  try {
    const { context } = req.body;
    const conversationId = uuidv4();
    
    conversations.set(conversationId, {
      id: conversationId,
      context: context || {},
      messages: [],
      createdAt: new Date()
    });
    
    res.status(201).json({ conversationId });
  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({ error: 'Failed to create conversation' });
  }
});

// Endpoint to get conversation history
router.get('/conversations/:conversationId', (req, res) => {
  try {
    const { conversationId } = req.params;
    const conversation = conversations.get(conversationId);
    
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    res.json(conversation.messages);
  } catch (error) {
    console.error('Error fetching conversation:', error);
    res.status(500).json({ error: 'Failed to fetch conversation' });
  }
});

// Endpoint to send a message and get AI response
router.post('/chat/send', async (req, res) => {
  try {
    const { conversationId, message, context } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    // Get or create conversation
    let conversation = conversations.get(conversationId);
    if (!conversation) {
      const newConversationId = uuidv4();
      conversation = {
        id: newConversationId,
        context: context || {},
        messages: [],
        createdAt: new Date()
      };
      conversations.set(newConversationId, conversation);
    }
    
    // Add user message to conversation
    const userMessage = {
      id: `user_${Date.now()}`,
      sender: 'user',
      message: message,
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
      stream: false // For simplicity, not streaming
    });
    
    const aiResponse = chatCompletion.choices[0]?.message?.content || "I'm having trouble responding right now. Could you try asking again?";
    
    // Add AI response to conversation
    const aiMessage = {
      id: `ai_${Date.now()}`,
      sender: 'ai',
      message: aiResponse,
      timestamp: new Date(),
      isContextAware: true
    };
    
    conversation.messages.push(aiMessage);
    
    // Update context if provided
    if (context) {
      conversation.context = { ...conversation.context, ...context };
    }
    
    res.json(aiMessage);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ 
      error: 'Failed to process message', 
      message: 'I\'m having trouble connecting to my AI brain. Could you try asking again?'
    });
  }
});

// Endpoint to update conversation context
router.put('/conversations/update-context', (req, res) => {
  try {
    const { conversationId, context } = req.body;
    
    const conversation = conversations.get(conversationId);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    conversation.context = { ...conversation.context, ...context };
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error updating context:', error);
    res.status(500).json({ error: 'Failed to update context' });
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