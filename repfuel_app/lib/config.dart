class Config {
  // API Configuration
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  
  // Get API key from environment or use a placeholder
  // In production, this should be stored securely (e.g., using flutter_dotenv or secure storage)
  static String get openAIKey {
    // For development, you can set this via environment variable
    // In production, use secure storage or backend proxy
    const String apiKey = String.fromEnvironment('OPENAI_API_KEY', 
        defaultValue: 'YOUR_API_KEY_HERE');
    
    if (apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('OpenAI API key not configured. Please set OPENAI_API_KEY environment variable or configure secure storage.');
    }
    
    return apiKey;
  }
  
  // App Configuration
  static const String appName = 'Smart Sales Trainer';
  static const String appVersion = '1.0.4';
  
  // Feature flags
  static const bool enableSpeechToText = true;
  static const bool enableTextToSpeech = true;
  static const bool enableOpenAI = true;
} 