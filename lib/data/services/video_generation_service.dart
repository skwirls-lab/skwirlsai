import 'dart:io';
import '../../core/constants/storage_paths.dart';
import '../../core/utils/logger.dart';
import 'package:path/path.dart' as p;

class VideoGenerationService {
  static const _tag = 'VideoGenerationService';

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;
  bool get isAvailable => _isModelLoaded;

  /// Check if a video generation model has been downloaded
  Future<bool> isModelDownloaded() async {
    final modelsDir = await StoragePaths.modelsDir;
    final modelFile = File(p.join(modelsDir, 'animatediff.safetensors'));
    return modelFile.existsSync();
  }

  /// Load the video generation model
  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    final downloaded = await isModelDownloaded();
    if (!downloaded) {
      throw StateError(
        'Video generation model not downloaded. '
        'Go to Settings > Models to download a text-to-video model.',
      );
    }

    Log.i(_tag, 'Loading video generation model...');

    // TODO: Initialize video generation via platform channels

    _isModelLoaded = true;
    Log.i(_tag, 'Video generation model loaded');
  }

  /// Generate a short video clip from a text prompt
  Future<String> generateVideo({
    required String prompt,
    int durationSeconds = 3,
    int width = 512,
    int height = 512,
    int fps = 8,
    int? seed,
  }) async {
    if (!_isModelLoaded) {
      throw StateError('Video generation model not loaded');
    }

    Log.i(_tag, 'Generating video: "$prompt" (${durationSeconds}s, ${width}x$height)');

    final outputDir = await StoragePaths.generatedMediaDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(outputDir, 'vid_$timestamp.mp4');

    // TODO: Execute text-to-video inference via platform channels
    // 1. Encode prompt
    // 2. Generate frames
    // 3. Encode to MP4
    // 4. Save to outputPath

    Log.i(_tag, 'Video generated: $outputPath');
    return outputPath;
  }

  /// Unload the model to free memory
  Future<void> unloadModel() async {
    if (!_isModelLoaded) return;
    _isModelLoaded = false;
    Log.i(_tag, 'Video generation model unloaded');
  }

  void dispose() {
    unloadModel();
  }
}
