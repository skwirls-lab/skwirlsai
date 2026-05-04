import 'dart:async';
import 'dart:io';
import '../../core/utils/logger.dart';
import 'inference_provider.dart';
import 'isolate_inference_worker.dart';

/// Tokens to strip from model output (ChatML / Gemma special tokens)
const _stripTokens = [
  '<|im_end|>',
  '<|im_start|>',
  '<end_of_turn>',
  '<start_of_turn>',
  '<eos>',
];

/// Local GGUF inference via llama_cpp_dart running in a background isolate.
/// All blocking FFI calls (model load, prompt processing, token generation)
/// happen off the main thread so the UI stays fully responsive.
class LocalInferenceProvider implements InferenceProvider {
  static const _tag = 'LocalInference';

  IsolateInferenceWorker? _worker;
  bool _isGenerating = false;

  @override
  String get providerName => 'Local (llama.cpp)';

  @override
  bool get isReady => _worker?.isLoaded ?? false;

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

    // Resolve the monolithic DLL path on Windows
    String? libraryPath;
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final dllPath = '$exeDir\\llama_monolithic.dll';
      if (await File(dllPath).exists()) {
        libraryPath = dllPath;
        Log.i(_tag, 'Using monolithic DLL: $dllPath');
      } else {
        Log.w(_tag, 'llama_monolithic.dll not found at $dllPath');
      }
    }

    try {
      _worker = IsolateInferenceWorker();
      await _worker!.loadModel(
        modelPath: config.localPath!,
        libraryPath: libraryPath,
        nCtx: config.contextSize ?? 8192,
        nGpuLayers: config.gpuLayers ?? (Platform.isWindows ? 0 : 99),
        mainGpu: Platform.isWindows ? -1 : 0,
        nThreads: config.threadCount ?? (Platform.numberOfProcessors - 1),
      );
      Log.i(_tag, 'Model loaded successfully (background isolate)');
    } catch (e, st) {
      Log.e(_tag, 'Failed to load model', e, st);
      await _worker?.dispose();
      _worker = null;
      rethrow;
    }
  }

  @override
  Future<void> shutdown() async {
    if (_worker != null) {
      Log.i(_tag, 'Unloading model...');
      await _worker!.dispose();
      _worker = null;
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
    if (_worker == null || !_worker!.isLoaded) {
      throw StateError('No model loaded. Call initialize() first.');
    }
    if (_isGenerating) {
      throw StateError('Already generating.');
    }

    _isGenerating = true;
    final p = params ?? const GenerationParams();

    try {
      final prompt = _buildPrompt(messages, systemPrompt);
      Log.i(_tag, 'Generating (${prompt.length} chars, temp=${p.temperature})');

      await for (final token in _worker!.generate(prompt, p.maxTokens)) {
        // Strip special tokens that leak into output
        var cleaned = token;
        for (final tok in _stripTokens) {
          cleaned = cleaned.replaceAll(tok, '');
        }
        if (cleaned.isNotEmpty) {
          yield cleaned;
        }
      }

      Log.i(_tag, 'Generation complete');
    } catch (e, st) {
      Log.e(_tag, 'Generation failed', e, st);
      rethrow;
    } finally {
      _isGenerating = false;
    }
  }

  @override
  void stopGeneration() {
    if (_isGenerating) {
      _worker?.stop();
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
