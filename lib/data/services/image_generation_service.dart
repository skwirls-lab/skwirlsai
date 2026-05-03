import 'dart:io';
import '../../core/constants/storage_paths.dart';
import '../../core/utils/logger.dart';
import 'package:path/path.dart' as p;

class ImageGenerationService {
  static const _tag = 'ImageGenerationService';

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;
  bool get isAvailable => _isModelLoaded;

  /// Check if an image generation model has been downloaded
  Future<bool> isModelDownloaded() async {
    final modelsDir = await StoragePaths.modelsDir;
    // Check for known SD model files
    final sdTurbo = File(p.join(modelsDir, 'sd-turbo.safetensors'));
    return sdTurbo.existsSync();
  }

  /// Load the image generation model
  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    final downloaded = await isModelDownloaded();
    if (!downloaded) {
      throw StateError(
        'Image generation model not downloaded. '
        'Go to Settings > Models to download Stable Diffusion.',
      );
    }

    Log.i(_tag, 'Loading image generation model...');

    // TODO: Initialize SD inference via platform channels
    // This will use native C++ / ONNX Runtime bindings to load
    // the Stable Diffusion model and prepare for inference.

    _isModelLoaded = true;
    Log.i(_tag, 'Image generation model loaded');
  }

  /// Generate an image from a text prompt
  Future<String> generateImage({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 4,
    double cfgScale = 7.5,
    int? seed,
  }) async {
    if (!_isModelLoaded) {
      throw StateError('Image generation model not loaded');
    }

    Log.i(_tag, 'Generating image: "$prompt" (${width}x$height, $steps steps)');

    final outputDir = await StoragePaths.generatedMediaDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(outputDir, 'img_$timestamp.png');

    // TODO: Execute SD inference via platform channels
    // 1. Encode prompt
    // 2. Run diffusion steps
    // 3. Decode latents to image
    // 4. Save to outputPath

    Log.i(_tag, 'Image generated: $outputPath');
    return outputPath;
  }

  /// Unload the model to free memory
  Future<void> unloadModel() async {
    if (!_isModelLoaded) return;

    // TODO: Release native resources
    _isModelLoaded = false;
    Log.i(_tag, 'Image generation model unloaded');
  }

  void dispose() {
    unloadModel();
  }
}
