const ChatMessage = require('../models/ChatMessage');
const Conversation = require('../models/Conversation');
const { v4: uuidv4 } = require('uuid');

class ChatController {
  // Get user's conversation history
  static async getUserConversations(req, res) {
    try {
      const userId = req.user?._id.toString();
      
      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      const conversations = await Conversation.getUserConversations(userId, 20);
      
      res.json({
        success: true,
        conversations: conversations.map(conv => ({
          id: conv._id,
          title: conv.title,
          preview: conv.preview,
          lastActivity: conv.lastActivity,
          messageCount: conv.messageCount,
          courseId: conv.courseId?._id || conv.courseId,
          lessonId: conv.lessonId?._id || conv.lessonId,
          sectionTitle: conv.sectionTitle,
          createdAt: conv.createdAt,
          updatedAt: conv.updatedAt
        }))
      });
    } catch (error) {
      console.error('Error fetching user conversations:', error);
      res.status(500).json({ 
        error: 'Failed to fetch conversations',
        details: error.message 
      });
    }
  }

  // Get specific conversation messages
  static async getConversationMessages(req, res) {
    try {
      const { conversationId } = req.params;
      const userId = req.user?._id.toString();
      const limit = parseInt(req.query.limit) || 50;

      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      // Verify user owns this conversation
      const conversation = await Conversation.findById(conversationId);
      
      if (!conversation || conversation.userId !== userId) {
        return res.status(404).json({ 
          error: 'Conversation not found' 
        });
      }

      if (!conversation) {
        return res.status(404).json({ 
          error: 'Conversation not found' 
        });
      }

      const messages = await ChatMessage.getConversationHistory(conversationId, limit);
      
      res.json({
        success: true,
        conversation: {
          id: conversation._id,
          title: conversation.title,
          context: conversation.getContext()
        },
        messages: messages.map(msg => ({
          id: msg._id,
          sender: msg.sender,
          message: msg.message,
          messageType: msg.messageType,
          timestamp: msg.timestamp,
          formattedTimestamp: msg.formattedTimestamp,
          isContextAware: msg.isContextAware
        }))
      });
    } catch (error) {
      console.error('Error fetching conversation messages:', error);
      res.status(500).json({ 
        error: 'Failed to fetch messages',
        details: error.message 
      });
    }
  }

  // Create new conversation or get existing one
  static async createConversation(req, res) {
    try {
      const userId = req.user?._id.toString();
      const { context } = req.body;

      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      const conversation = await Conversation.getOrCreateConversation(userId, context);
      
      // If it's a new conversation, save it
      if (conversation.isNew) {
        await conversation.save();
      }

      res.json({
        success: true,
        conversation: {
          id: conversation._id,
          title: conversation.title,
          context: conversation.getContext(),
          messageCount: conversation.messageCount,
          createdAt: conversation.createdAt
        }
      });
    } catch (error) {
      console.error('Error creating conversation:', error);
      res.status(500).json({ 
        error: 'Failed to create conversation',
        details: error.message 
      });
    }
  }

  // Send message and get AI response
  static async sendMessage(req, res) {
    try {
      const { conversationId, message, context } = req.body;
      const userId = req.user?._id.toString();

      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      if (!message || message.trim().length === 0) {
        return res.status(400).json({ 
          error: 'Message is required' 
        });
      }

      // Get or create conversation
      let conversation;
      if (conversationId) {
        conversation = await Conversation.findById(conversationId);
        
        if (!conversation || conversation.userId !== userId) {
          return res.status(404).json({ 
            error: 'Conversation not found' 
          });
        }
      } else {
        conversation = await Conversation.getOrCreateConversation(userId, context);
        if (conversation.isNew) {
          await conversation.save();
        }
      }

      // Save user message
      const userMessage = new ChatMessage({
        conversationId: conversation._id,
        sender: 'user',
        message: message.trim(),
        messageType: 'text',
        context: context || {},
        isContextAware: !!context,
        metadata: {
          ipAddress: req.ip,
          userAgent: req.get('User-Agent')
        }
      });

      await userMessage.save();
      await conversation.incrementMessageCount();

      // Prepare messages for AI (including context)
      const recentMessages = await ChatMessage.getConversationHistory(
        conversation._id, 
        10
      );

      const messagesForAI = [
        {
          role: 'system',
          content: ChatController.createContextAwareSystemPrompt(conversation.getContext())
        },
        ...recentMessages.map(msg => ({
          role: msg.sender === 'user' ? 'user' : 'assistant',
          content: msg.message
        }))
      ];

      // Generate AI response (this would integrate with your AI service)
      const aiResponse = await ChatController.generateAIResponse(messagesForAI, context);

      // Save AI response
      const aiMessage = new ChatMessage({
        conversationId: conversation._id,
        sender: 'ai',
        message: aiResponse,
        messageType: 'text',
        isContextAware: true,
        context: context || {}
      });

      await aiMessage.save();
      await conversation.incrementMessageCount();

      res.json({
        success: true,
        conversation: {
          id: conversation._id,
          title: conversation.title
        },
        messages: [
          {
            id: userMessage._id,
            sender: 'user',
            message: userMessage.message,
            timestamp: userMessage.timestamp,
            formattedTimestamp: userMessage.formattedTimestamp
          },
          {
            id: aiMessage._id,
            sender: 'ai',
            message: aiMessage.message,
            timestamp: aiMessage.timestamp,
            formattedTimestamp: aiMessage.formattedTimestamp
          }
        ]
      });
    } catch (error) {
      console.error('Error sending message:', error);
      res.status(500).json({ 
        error: 'Failed to send message',
        details: error.message 
      });
    }
  }

  // Archive conversation
  static async archiveConversation(req, res) {
    try {
      const { conversationId } = req.params;
      const userId = req.user?._id.toString();

      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      const conversation = await Conversation.findById(conversationId);

      if (!conversation || conversation.userId !== userId) {
        return res.status(404).json({ 
          error: 'Conversation not found' 
        });
      }

      await conversation.archive();

      res.json({
        success: true,
        message: 'Conversation archived successfully'
      });
    } catch (error) {
      console.error('Error archiving conversation:', error);
      res.status(500).json({ 
        error: 'Failed to archive conversation',
        details: error.message 
      });
    }
  }

  // Helper method to create context-aware system prompt
  static createContextAwareSystemPrompt(context) {
    let prompt = "You are an AI learning assistant for Excellence Coaching Hub. ";
    
    if (context?.courseId) {
      prompt += `You are helping with course content. `;
    }
    
    if (context?.lessonId) {
      prompt += `You are providing assistance with a specific lesson. `;
    }
    
    if (context?.sectionTitle) {
      prompt += `The current section is: ${context.sectionTitle}. `;
    }
    
    if (context?.studentLevel) {
      prompt += `The student's level is ${context.studentLevel}. `;
    }
    
    prompt += "Provide helpful, accurate, and encouraging responses. Keep explanations clear and appropriate for educational purposes.";
    
    return prompt;
  }

  // Helper method to generate AI response (placeholder - integrate with your AI service)
  static async generateAIResponse(messages, context) {
    // This is a placeholder implementation
    // In production, integrate with Groq, OpenAI, or your preferred AI service
    
    const lastUserMessage = messages.filter(m => m.role === 'user').pop();
    if (!lastUserMessage) {
      return "Hello! How can I help you with your learning today?";
    }

    // Simple response logic - replace with actual AI integration
    const userMessage = lastUserMessage.content.toLowerCase();
    
    if (userMessage.includes('hello') || userMessage.includes('hi')) {
      return "Hello! I'm your AI learning assistant. How can I help you with your studies today?";
    } else if (userMessage.includes('help') || userMessage.includes('explain')) {
      return "I'd be happy to help you understand this concept better. Could you tell me more about what specifically you'd like me to explain?";
    } else if (context?.sectionTitle) {
      return `I see you're working on "${context.sectionTitle}". I'm here to help you with any questions about this topic. What would you like to know?`;
    } else {
      return "Thanks for your message! I'm here to help with your learning. Feel free to ask me anything about the course material or learning concepts.";
    }
  }
}

module.exports = ChatController;