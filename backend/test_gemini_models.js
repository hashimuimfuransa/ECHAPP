const { GoogleGenerativeAI } = require("@google/generative-ai");

async function listAvailableModels() {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.log("GEMINI_API_KEY not found in environment variables");
      return;
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    
    // Try to list models (this might not work with all API keys)
    console.log("Testing Gemini AI connection...");
    
    // Test with gemini-2.0-flash (should work)
    try {
      const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
      console.log("✓ gemini-2.0-flash model is available");
      
      // Test a simple request
      const result = await model.generateContent("Say hello");
      console.log("✓ API connection successful");
      console.log("Response:", result.response.text());
    } catch (error) {
      console.log("✗ gemini-2.0-flash error:", error.message);
    }
    
    // Test with gemini-1.5-pro
    try {
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-pro" });
      console.log("✓ gemini-1.5-pro model is available");
    } catch (error) {
      console.log("✗ gemini-1.5-pro error:", error.message);
    }
    
    // Test with gemini-pro (old model)
    try {
      const model = genAI.getGenerativeModel({ model: "gemini-pro" });
      console.log("✓ gemini-pro model is available");
    } catch (error) {
      console.log("✗ gemini-pro error:", error.message);
    }

  } catch (error) {
    console.error("Error testing Gemini AI:", error);
  }
}

listAvailableModels();