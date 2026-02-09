const { GoogleGenerativeAI } = require("@google/generative-ai");

async function debugGeminiAPI() {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.log("GEMINI_API_KEY not found in environment variables");
      return;
    }

    console.log("API Key present:", !!apiKey);
    console.log("API Key length:", apiKey.length);
    
    const genAI = new GoogleGenerativeAI(apiKey);
    
    console.log("GoogleGenerativeAI instance created");
    
    // Try to make a direct API call to see what models are actually available
    try {
      const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
      const data = await response.json();
      console.log("Available models:", data.models?.map(m => m.name) || "No models found");
    } catch (error) {
      console.log("Error fetching models list:", error.message);
    }
    
    // Try with gemini-pro using explicit API version
    try {
      const model = genAI.getGenerativeModel({ 
        model: "models/gemini-pro",
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 1000,
        }
      });
      
      console.log("Attempting to use models/gemini-pro...");
      const result = await model.generateContent("Hello, world!");
      console.log("Success! Response:", result.response.text());
    } catch (error) {
      console.log("Explicit models/gemini-pro error:", error.message);
    }

  } catch (error) {
    console.error("Error debugging Gemini AI:", error);
  }
}

debugGeminiAPI();