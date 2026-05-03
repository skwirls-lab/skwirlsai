import 'dart:io';
import '../../core/constants/storage_paths.dart';
import '../../core/utils/logger.dart';
import 'package:path/path.dart' as p;

class AudioGenerationService {
  static const _tag = 'AudioGenerationService';

  bool _ttsModelLoaded = false;
  bool get isTtsAvailable => _ttsModelLoaded;

  bool _audioGenModelLoaded = false;
  bool get isAudioGenAvailable => _audioGenModelLoaded;

  /// Check if a TTS model has been downloaded
  Future<bool> isTtsModelDownloaded() async {
    final modelsDir = await StoragePaths.modelsDir;
    final modelFile = File(p.join(modelsDir, 'tts-model.onnx'));
    return modelFile.existsSync();
  }

  /// Load the TTS model
  Future<void> loadTtsModel() async {
    if (_ttsModelLoaded) return;

    final downloaded = await isTtsModelDownloaded();
    if (!downloaded) {
      throw StateError(
        'TTS model not downloaded. '
        'Go to Settings > Models to download a text-to-speech model.',
      );
    }

    Log.i(_tag, 'Loading TTS model...');

    // TODO: Initialize TTS via ONNX Runtime or platform channels

    _ttsModelLoaded = true;
    Log.i(_tag, 'TTS model loaded');
  }

  /// Generate speech audio from text
  Future<String> generateSpeech({
    required String text,
    String voice = 'default',
    double speed = 1.0,
  }) async {
    if (!_ttsModelLoaded) {
      // Try platform-native TTS as fallback
      return _platformTts(text);
    }

    Log.i(_tag, 'Generating speech: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}"');

    final outputDir = await StoragePaths.generatedMediaDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(outputDir, 'tts_$timestamp.wav');

    // TODO: Execute TTS inference
    // 1. Tokenize text
    // 2. Run model
    // 3. Save WAV to outputPath

    Log.i(_tag, 'Speech generated: $outputPath');
    return outputPath;
  }

  /// Fallback: use platform-native TTS (no model download needed)
  Future<String> _platformTts(String text) async {
    Log.i(_tag, 'Using platform-native TTS');

    // TODO: Use flutter_tts or platform channel for native TTS
    // This is available on all platforms without any model download

    final outputDir = await StoragePaths.generatedMediaDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(outputDir, 'tts_native_$timestamp.wav');

    return outputPath;
  }

  /// Generate ambient audio/sound effects from text description
  Future<String> generateAudio({
    required String prompt,
    int durationSeconds = 5,
    int? seed,
  }) async {
    if (!_audioGenModelLoaded) {
      throw StateError(
        'Audio generation model not downloaded. '
        'Go to Settings > Models to download a text-to-audio model.',
      );
    }

    Log.i(_tag, 'Generating audio: "$prompt" (${durationSeconds}s)');

    final outputDir = await StoragePaths.generatedMediaDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(outputDir, 'audio_$timestamp.wav');

    // TODO: Execute text-to-audio inference

    Log.i(_tag, 'Audio generated: $outputPath');
    return outputPath;
  }

  Future<void> unloadModels() async {
    _ttsModelLoaded = false;
    _audioGenModelLoaded = false;
    Log.i(_tag, 'Audio models unloaded');
  }

  void dispose() {
    unloadModels();
  }
}
