/// Abstract interface for LLM inference providers.
///
/// Implementations:
///   - [LocalInferenceProvider] — llama_cpp_dart for local GGUF files
///   - [RemoteInferenceProvider] — OpenAI-compatible API (Ollama, vLLM, BYOK)
abstract class InferenceProvider {
  String get providerName;
  bool get isReady;
  bool get isGenerating;

  /// Connect/load the model. What this means depends on the provider:
  ///   - Local: load GGUF into memory
  ///   - Remote: verify the endpoint is reachable
  Future<void> initialize(ModelConfig config);

  /// Release resources
  Future<void> shutdown();

  /// Stream tokens from the LLM
  Stream<String> generateStream({
    required List<ChatMessage> messages,
    String? systemPrompt,
    GenerationParams? params,
  });

  /// Stop an in-progress generation
  void stopGeneration();
}

/// Configuration for connecting to a model
class ModelConfig {
  final ModelSource source;

  // Local GGUF fields
  final String? localPath;
  final int? gpuLayers;
  final int? threadCount;
  final int? contextSize;

  // Remote API fields
  final String? baseUrl;
  final String? apiKey;
  final String? modelName;

  const ModelConfig({
    required this.source,
    this.localPath,
    this.gpuLayers,
    this.threadCount,
    this.contextSize,
    this.baseUrl,
    this.apiKey,
    this.modelName,
  });

  /// For local GGUF models
  factory ModelConfig.local({
    required String path,
    int? gpuLayers,
    int? threadCount,
    int contextSize = 4096,
  }) =>
      ModelConfig(
        source: ModelSource.local,
        localPath: path,
        gpuLayers: gpuLayers,
        threadCount: threadCount,
        contextSize: contextSize,
      );

  /// For remote OpenAI-compatible endpoints (Ollama, vLLM, etc.)
  factory ModelConfig.remote({
    required String baseUrl,
    required String modelName,
    String? apiKey,
  }) =>
      ModelConfig(
        source: ModelSource.remote,
        baseUrl: baseUrl,
        modelName: modelName,
        apiKey: apiKey,
      );

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'localPath': localPath,
        'gpuLayers': gpuLayers,
        'threadCount': threadCount,
        'contextSize': contextSize,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'modelName': modelName,
      };

  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
        source: ModelSource.values.byName(json['source'] as String),
        localPath: json['localPath'] as String?,
        gpuLayers: json['gpuLayers'] as int?,
        threadCount: json['threadCount'] as int?,
        contextSize: json['contextSize'] as int?,
        baseUrl: json['baseUrl'] as String?,
        apiKey: json['apiKey'] as String?,
        modelName: json['modelName'] as String?,
      );
}

enum ModelSource { local, remote }

/// Lightweight message representation for prompt building
class ChatMessage {
  final String role; // 'user', 'assistant', 'system', 'tool'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Generation parameters
class GenerationParams {
  final double temperature;
  final double topP;
  final int topK;
  final int maxTokens;
  final double repeatPenalty;

  const GenerationParams({
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.maxTokens = 2048,
    this.repeatPenalty = 1.1,
  });
}
