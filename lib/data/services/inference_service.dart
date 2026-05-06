import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'inference_provider.dart';
import 'local_inference_provider.dart';
import 'remote_inference_provider.dart';

export 'inference_provider.dart' show ChatMessage, ModelConfig, ModelSource, GenerationParams;

/// Facade over local and remote inference providers.
///
/// Manages which provider is active and delegates generation calls.
/// Supports:
///   - Local GGUF via llama_cpp_dart
///   - Remote via OpenAI-compatible API (Ollama, vLLM, OpenAI, BYOK)
class InferenceService {
  static const _tag = 'InferenceService';

  InferenceProvider? _activeProvider;
  ModelConfig? _activeConfig;

  // Generation parameters (defaults, can be overridden per-call)
  double temperature = AppConstants.defaultTemperature;
  double topP = AppConstants.defaultTopP;
  int topK = AppConstants.defaultTopK;
  int maxTokens = AppConstants.defaultMaxTokens;
  double repeatPenalty = AppConstants.defaultRepeatPenalty;

  bool get isModelLoaded => _activeProvider?.isReady ?? false;
  bool get isGenerating => _activeProvider?.isGenerating ?? false;
  String? get loadedModelPath => _activeConfig?.localPath;
  String? get activeEndpoint => _activeConfig?.baseUrl;
  String? get activeModelName {
    final name = _activeConfig?.modelName;
    if (name != null && name.isNotEmpty) return name;
    // For local models, derive name from file path
    final path = _activeConfig?.localPath;
    if (path != null && path.isNotEmpty) {
      final fileName = path.split(RegExp(r'[/\\]')).last;
      // Strip .gguf extension for a cleaner name
      return fileName.replaceAll(RegExp(r'\.gguf$', caseSensitive: false), '');
    }
    return null;
  }
  ModelSource? get activeSource => _activeConfig?.source;
  String get providerName => _activeProvider?.providerName ?? 'None';

  /// Connect to a model — local GGUF or remote endpoint
  Future<void> connect(ModelConfig config) async {
    // Shutdown existing provider
    await disconnect();

    Log.i(_tag, 'Connecting: ${config.source.name} '
        '${config.localPath ?? config.baseUrl ?? ""}');

    // Create the right provider
    final provider = switch (config.source) {
      ModelSource.local => LocalInferenceProvider(),
      ModelSource.remote => RemoteInferenceProvider(),
    };

    await provider.initialize(config);

    _activeProvider = provider;
    _activeConfig = config;

    Log.i(_tag, 'Connected to ${provider.providerName}');
  }

  /// Disconnect and free resources
  Future<void> disconnect() async {
    if (_activeProvider != null) {
      await _activeProvider!.shutdown();
      _activeProvider = null;
      _activeConfig = null;
      Log.i(_tag, 'Disconnected');
    }
  }

  /// Generate a response as a stream of tokens
  Stream<String> generateStream({
    required List<ChatMessage> messages,
    bool agentMode = false,
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
  }) async* {
    if (_activeProvider == null || !_activeProvider!.isReady) {
      throw StateError('No model connected. Call connect() first.');
    }

    // Build system prompt with tool info for agent mode
    String? fullSystemPrompt = systemPrompt;
    if (agentMode && tools != null && tools.isNotEmpty) {
      final toolBlock = StringBuffer();
      if (systemPrompt != null) toolBlock.writeln(systemPrompt);
      toolBlock.writeln();
      toolBlock.writeln('# Available Tools');
      toolBlock.writeln('You have access to the following tools. Use them when they can help answer the user\'s question.');
      toolBlock.writeln();
      for (final tool in tools) {
        final fn = tool['function'] as Map<String, dynamic>;
        toolBlock.writeln('## ${fn['name']}');
        toolBlock.writeln('Description: ${fn['description']}');
        final params = fn['parameters'] as Map<String, dynamic>?;
        if (params != null && params['properties'] != null) {
          final props = params['properties'] as Map<String, dynamic>;
          final required = (params['required'] as List?)?.cast<String>() ?? [];
          toolBlock.writeln('Parameters:');
          for (final entry in props.entries) {
            final p = entry.value as Map<String, dynamic>;
            final req = required.contains(entry.key) ? ' (required)' : '';
            toolBlock.writeln('  - ${entry.key}: ${p['type']}$req — ${p['description'] ?? ''}');
          }
        }
        toolBlock.writeln();
      }
      toolBlock.writeln('# How to call a tool');
      toolBlock.writeln('When you want to use a tool, output ONLY valid JSON in a tool_call code block:');
      toolBlock.writeln('```tool_call');
      toolBlock.writeln('{"name": "tool_name", "arguments": {"param": "value"}}');
      toolBlock.writeln('```');
      toolBlock.writeln();
      toolBlock.writeln('Important rules:');
      toolBlock.writeln('- Output ONLY the tool call JSON, nothing else, when calling a tool.');
      toolBlock.writeln('- After the tool returns its result, continue your response using that information.');
      toolBlock.writeln('- If you don\'t need a tool, just respond normally without any tool_call block.');
      fullSystemPrompt = toolBlock.toString();
    }

    final params = GenerationParams(
      temperature: temperature,
      topP: topP,
      topK: topK,
      maxTokens: maxTokens,
      repeatPenalty: repeatPenalty,
    );

    yield* _activeProvider!.generateStream(
      messages: messages,
      systemPrompt: fullSystemPrompt,
      params: params,
    );
  }

  /// Stop an in-progress generation
  void stopGeneration() {
    _activeProvider?.stopGeneration();
  }

  /// Update generation parameters
  void updateParams({
    double? temp,
    double? topPVal,
    int? topKVal,
    int? maxTok,
    double? repeatPen,
  }) {
    if (temp != null) temperature = temp;
    if (topPVal != null) topP = topPVal;
    if (topKVal != null) topK = topKVal;
    if (maxTok != null) maxTokens = maxTok;
    if (repeatPen != null) repeatPenalty = repeatPen;
  }

  void dispose() {
    stopGeneration();
    disconnect();
  }
}
