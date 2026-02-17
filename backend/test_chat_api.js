// Test script to verify cross-device chat functionality
const axios = require('axios');

// Test the new chat API endpoints
async function testChatAPI() {
  const baseUrl = 'http://localhost:5000/api/ai'; // Update with your backend URL
  
  console.log('🧪 Testing AI Chat API Endpoints...\n');
  
  try {
    // Test 1: Create conversation (without auth for testing)
    console.log('1. Testing conversation creation...');
    const createResponse = await axios.post(`${baseUrl}/conversations/create`, {
      context: {
        courseId: 'test_course_123',
        lessonId: 'test_lesson_456',
        sectionTitle: 'Introduction to Programming',
        studentLevel: 'beginner'
      }
    });
    
    console.log('✅ Conversation created:', createResponse.data);
    const conversationId = createResponse.data.conversation.id;
    
    // Test 2: Send message
    console.log('\n2. Testing message sending...');
    const messageResponse = await axios.post(`${baseUrl}/chat/send`, {
      conversationId: conversationId,
      message: 'Hello, can you help me understand variables?',
      context: {
        courseId: 'test_course_123',
        lessonId: 'test_lesson_456',
        sectionTitle: 'Introduction to Programming',
        studentLevel: 'beginner'
      }
    });
    
    console.log('✅ Message sent:', messageResponse.data);
    
    // Test 3: Get conversation messages
    console.log('\n3. Testing message retrieval...');
    const messagesResponse = await axios.get(`${baseUrl}/conversations/${conversationId}`);
    console.log('✅ Messages retrieved:', messagesResponse.data);
    
    // Test 4: Get user conversations
    console.log('\n4. Testing user conversations list...');
    const conversationsResponse = await axios.get(`${baseUrl}/conversations`);
    console.log('✅ Conversations list:', conversationsResponse.data);
    
    console.log('\n🎉 All tests passed! Chat API is working correctly.');
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Make sure your backend server is running on port 5000');
    }
  }
}

// Run the test
testChatAPI();