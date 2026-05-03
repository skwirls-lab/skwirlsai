import 'dart:async';
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import '../../core/utils/logger.dart';
import 'inference_provider.dart';

/// Local GGUF inference via llama_cpp_dart (FFI to llama.cpp)
class LocalInferenceProvider implements InferenceProvider {
  static const _tag = 'LocalInference';

  Llama? _llama;
  bool _isGenerating = false;
  bool _stopRequested = false;

  @override
  String get providerName => 'Local (llama.cpp)';

  @override
  bool get isReady => _llama != null;

  @override
  bool get isGenerating => _isGenerating;

  @override
  Future<void> initialize(ModelConfig config) async {
    if (config.source != ModelSource.local || config.localPath == null) {
      throw ArgumentError('LocalInferenceProvider requires a local GGUF path');
    }

    final file = File(config.localPath!);
    if (!await file.exists()) {
      throw FileSystemException('Model file not found', config.localPath);
    }

    await shutdown();

    Log.i(_tag, 'Loading model: ${config.localPath}');

    try {
      final modelParams = ModelParams();
      modelParams.nGpuLayers = config.gpuLayers ?? 99;

      final contextParams = ContextParams();
      contextParams.nCtx = config.contextSize ?? 4096;
      contextParams.nBatch = config.contextSize ?? 4096;
      contextParams.nThreads = config.threadCount ?? (Platform.numberOfProcessors - 1);
      contextParams.nThreadsBatch = config.threadCount ?? (Platform.numberOfProcessors - 1);
      contextParams.nPredict = -1; // unlimited, we control via maxTokens

      _llama = Llama(
        config.localPath!,
        modelParams: modelParams,
        contextParams: contextParams,
      );

      Log.i(_tag, 'Model loaded successfully');
    } catch (e, st) {
      Log.e(_tag, 'Failed to load model', e, st);
      _llama = null;
      rethrow;
    }
  }

  @override
  Future<void> shutdown() async {
    if (_llama != null) {
      Log.i(_tag, 'Unloading model...');
      _llama!.dispose();
      _llama = null;
      _isGenerating = false;
      Log.i(_tag, 'Model unloaded');
    }
  }

  @override
  Stream<String> generateStream({
    required List<ChatMessage> messages,
    String? systemPrompt,
    GenerationParams? params,
  }) async* {
    if (_llama == null) {
      throw StateError('No model loaded. Call initialize() first.');
    }
    if (_isGenerating) {
      throw StateError('Already generating.');
    }

    _isGenerating = true;
    _stopRequested = false;
    final p = params ?? const GenerationParams();

    try {
      final prompt = _buildPrompt(messages, systemPrompt);

      Log.i(_tag, 'Generating (${prompt.length} chars, temp=${p.temperature})');

      _llama!.setPrompt(prompt);

      int tokenCount = 0;
      while (tokenCount < p.maxTokens && !_stopRequested) {
        // getNext() returns (String, bool) — (text, isDone)
        final (text, isDone) = _llama!.getNext();

        if (text.isNotEmpty) {
          tokenCount++;
          yield text;
        }

        if (isDone) break;
      }

      Log.i(_tag, 'Generation complete ($tokenCount tokens)');
    } catch (e, st) {
      Log.e(_tag, 'Generation failed', e, st);
      rethrow;
    } finally {
      _isGenerating = false;
      _stopRequested = false;
    }
  }

  @override
  void stopGeneration() {
    if (_isGenerating) {
      _stopRequested = true;
      Log.i(_tag, 'Stop requested');
    }
  }

  /// Build a chat prompt string. Uses ChatML format which is widely supported.
  String _buildPrompt(List<ChatMessage> messages, String? systemPrompt) {
    final buffer = StringBuffer();

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      buffer.writeln('<|im_start|>system');
      buffer.writeln(systemPrompt);
      buffer.writeln('<|im_end|>');
    }

    for (final msg in messages) {
      final role = msg.role == 'assistant' ? 'assistant' : msg.role;
      buffer.writeln('<|im_start|>$role');
      buffer.writeln(msg.content);
      buffer.writeln('<|im_end|>');
    }

    buffer.write('<|im_start|>assistant\n');

    return buffer.toString();
  }
}
