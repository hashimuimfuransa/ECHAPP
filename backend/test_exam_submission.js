// Test exam submission with text answers
const axios = require('axios');

async function testExamSubmission() {
  try {
    // First, login to get auth token
    const loginResponse = await axios.post('http://localhost:5000/api/auth/login', {
      email: 'teststudent@example.com',
      password: 'password123'
    });
    
    const token = loginResponse.data.data.token;
    console.log('Login successful, token:', token ? token.substring(0, 20) + '...' : 'NO TOKEN');
    
    // Get exam questions
    const examId = '6991ee526cfa11c580f43af8'; // Using the exam from our test data
    const questionsResponse = await axios.get(`http://localhost:5000/api/exams/${examId}/questions`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('Exam questions retrieved:', questionsResponse.data.data.questions.length);
    
    // Prepare answers with text responses
    const answers = [
      // fill_blank question - correct answer
      {
        questionId: '6991ee526cfa11c580f43afc', // "The sum of two numbers is 15. If one number is 8, what is the other number?"
        answerText: '7'
      },
      // open question - text response
      {
        questionId: '6991ee526cfa11c580f43b03', // "Explain the concept of fractions and provide an example."
        answerText: 'A fraction represents a part of a whole. For example, 1/2 means one part out of two equal parts.'
      },
      // mcq question
      {
        questionId: '6991ee526cfa11c580f43afb', // "Which of the following numbers is a prime number?"
        selectedOption: 0 // Assuming first option is correct
      }
    ];
    
    console.log('Submitting answers:', JSON.stringify(answers, null, 2));
    
    // Submit exam
    const submitResponse = await axios.post(`http://localhost:5000/api/exams/${examId}/submit`, {
      answers: answers
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('Exam submission response:', JSON.stringify(submitResponse.data, null, 2));
    
    // Check exam history
    const historyResponse = await axios.get('http://localhost:5000/api/exams/student/history', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('Exam history response:', JSON.stringify(historyResponse.data, null, 2));
    
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

testExamSubmission();