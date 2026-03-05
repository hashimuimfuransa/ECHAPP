const ChatMessage = require('../models/ChatMessage');
const Conversation = require('../models/Conversation');
const Enrollment = require('../models/Enrollment');
const Result = require('../models/Result');
const User = require('../models/User');
const GrokService = require('../services/grok_service');
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

      // Get student performance data for richer context
      const enrollments = await Enrollment.find({ userId }).populate('courseId');
      const results = await Result.find({ userId }).populate('examId');
      const user = await User.findById(userId);

      const performanceContext = {
        studentName: user?.fullName || 'Student',
        studentLevel: user?.role || 'student',
        courses: enrollments.map(e => ({
          title: e.courseId?.title,
          progress: e.progress,
          status: e.completionStatus
        })),
        examResults: results.map(r => ({
          examTitle: r.examId?.title,
          score: r.score,
          totalPoints: r.totalPoints,
          percentage: r.percentage,
          passed: r.passed
        }))
      };

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
          content: ChatController.createContextAwareSystemPrompt({
            ...conversation.getContext(),
            ...performanceContext
          })
        },
        ...recentMessages.map(msg => ({
          role: msg.sender === 'user' ? 'user' : 'assistant',
          content: msg.message
        }))
      ];

      // Generate AI response
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
    let prompt = "You are an expert AI Learning Assistant and Instructor for Excellence Coaching Hub. Your mission is to help students succeed by providing accurate, supportive, and personalized guidance across any topic they inquire about. ";
    
    // Inject Student Profile and Performance
    if (context.studentName) {
      prompt += `You are talking to ${context.studentName}. `;
    }
    
    if (context.courses && context.courses.length > 0) {
      prompt += "Student's Current Courses: " + context.courses.map(c => `[${c.title}: ${c.progress}% done, Status: ${c.status}]`).join(", ") + ". ";
    }
    
    if (context.examResults && context.examResults.length > 0) {
      prompt += "Student's Performance History: " + context.examResults.map(r => `[Exam: ${r.examTitle}, Score: ${r.score}/${r.totalPoints} (${r.percentage}%), Passed: ${r.passed}]`).join(", ") + ". ";
    }
    
    prompt += "\n\nCRITICAL INSTRUCTIONS:\n";
    prompt += "1. NEVER say 'I am not sure of responding' or similar phrases. Always find a helpful way to respond or ask for clarification if truly needed.\n";
    prompt += "2. BEHAVIOR RECOMMENDATIONS: Based on the student's grades and progress, offer specific advice on how they should behave or study. For example, if a student has low grades in a specific exam, suggest they revisit that lesson or practice more. If they are progressing well, encourage them to take more advanced topics.\n";
    prompt += "3. VERSATILITY: You are an all-knowing instructor. While your primary focus is the student's courses at Excellence Coaching Hub, you MUST answer any question the student asks, regardless of whether it's directly related to their course or not. Provide helpful, educational, and detailed answers to all queries.\n";
    prompt += "4. NO HALLUCINATIONS: Only speak about facts related to the courses and the student's data. If you don't know something about the student's data, don't invent it.\n";
    prompt += "5. TONE: Be very professional, attractive, user-friendly, and feel like a real human coach and instructor, not a robotic script.\n";
    
    if (context.courseTitle) {
      prompt += `The current focus is on the course: "${context.courseTitle}". `;
    }
    
    if (context.lessonTitle) {
      prompt += `The student is currently looking at the lesson: "${context.lessonTitle}". `;
    }

    if (context.currentLessonNotes) {
      prompt += `\nHere are the notes for the current lesson:\n${context.currentLessonNotes}\n`;
    }

    const courseStructure = context.courseStructure || (context.allSections && context.allSections.map(section => {
      const lessons = (context.sectionLessons && context.sectionLessons[section.id]) || [];
      return {
        sectionTitle: section.title,
        lessons: lessons.map(l => ({
          title: l.title,
          description: l.description,
          content: l.notes
        }))
      };
    }));

    if (courseStructure && courseStructure.length > 0) {
      prompt += `\nHere is the detailed content and structure of the course "${context.courseTitle || 'this course'}":\n`;
      courseStructure.forEach(section => {
        prompt += `- Section: ${section.sectionTitle}\n`;
        section.lessons.forEach(lesson => {
          prompt += `  * Lesson: ${lesson.title}\n`;
          if (lesson.description) prompt += `    Description: ${lesson.description}\n`;
          if (lesson.content) prompt += `    CONTENT/NOTES: ${lesson.content.substring(0, 1000)}${lesson.content.length > 1000 ? '...' : ''}\n`;
        });
      });
      prompt += `\nYou have access to all these sections, lesson titles, and lesson materials/notes. You can help the student by summarizing any of these lessons, explaining concepts from the materials, or answering questions about any part of the course content.\n`;
    }
    
    prompt += "\nFeel free to discuss anything the student wants. You are their dedicated instructor, so provide value in every response, whether it's about their specific course, general knowledge, or personal growth.";
    
    return prompt;
  }

  // Helper method to generate AI response using Grok AI
  static async generateAIResponse(messages, context) {
    try {
      // Return response from Grok Service
      return await GrokService.generateChatResponse(messages, context);
    } catch (error) {
      console.error("Error in generateAIResponse:", error);
      return "I'm currently reviewing your progress and thinking about the best way to help you. Could you please rephrase your question or tell me more about what you're working on?";
    }
  }
}

module.exports = ChatController;
