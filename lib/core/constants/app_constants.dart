class AppConstants {
  AppConstants._();

  static const String appName = 'SkwirlsAI';
  static const String appVersion = '1.0.0';
  static const String packageId = 'com.svl.skwirlsai';

  // LLM defaults
  static const int defaultContextSize = 8192;
  static const double defaultTemperature = 0.7;
  static const double defaultTopP = 0.9;
  static const int defaultTopK = 40;
  static const int defaultMaxTokens = 2048;
  static const double defaultRepeatPenalty = 1.1;

  // Agent mode limits
  static const int maxAgentIterations = 8;
  static const Duration agentToolTimeout = Duration(seconds: 45);
  static const Duration agentGenerationTimeout = Duration(seconds: 120);

  // Sync settings
  static const Duration syncDebounce = Duration(seconds: 30);
  static const int maxSyncRetries = 5;

  // RAG defaults
  static const int ragChunkSize = 512;
  static const int ragChunkOverlap = 50;
  static const int ragTopK = 3;

  // Model tiers (RAM-based recommendations)
  static const int tier1MaxRamMB = 4096;   // E2B: <4GB
  static const int tier2MaxRamMB = 8192;   // E4B: 4-8GB
  static const int tier3MaxRamMB = 16384;  // 26B: 16GB+
  // 31B: 24GB+ VRAM

  // Hugging Face base URL
  static const String huggingFaceBaseUrl = 'https://huggingface.co';
}
