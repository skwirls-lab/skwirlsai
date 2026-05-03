import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/storage_paths.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/model_info.dart';
import 'package:path/path.dart' as p;

class ModelService {
  static const _tag = 'ModelService';
  static const _activeModelKey = 'active_model_id';

  final Dio _dio = Dio();
  CancelToken? _downloadCancelToken;

  ModelInfo? _activeModel;
  ModelInfo? get activeModel => _activeModel;

  final _downloadProgressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get downloadProgress => _downloadProgressController.stream;

  /// Get the currently selected model ID from preferences
  Future<String?> getActiveModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeModelKey);
  }

  /// Set the active model ID in preferences
  Future<void> setActiveModelId(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeModelKey, modelId);
    Log.i(_tag, 'Active model set to: $modelId');
  }

  /// List all available models (downloaded + catalog)
  Future<List<ModelInfo>> listAvailableModels() async {
    final modelsDir = await StoragePaths.modelsDir;
    final models = <ModelInfo>[];

    // Check catalog models
    for (final entry in ApiConstants.gemma4Models.entries) {
      final info = entry.value;
      final filePath = p.join(modelsDir, info.fileName);
      final exists = await File(filePath).exists();

      models.add(ModelInfo(
        id: info.id,
        displayName: info.displayName,
        filePath: filePath,
        fileSizeMB: info.fileSizeMB,
        status: exists ? ModelStatus.downloaded : ModelStatus.notDownloaded,
      ));
    }

    // Scan for custom GGUF files
    final dir = Directory(modelsDir);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.gguf')) {
          final fileName = p.basename(entity.path);
          final isKnown = models.any((m) => m.filePath != null && p.basename(m.filePath!) == fileName);
          if (!isKnown) {
            final stat = await entity.stat();
            models.add(ModelInfo(
              id: 'custom-${fileName.hashCode}',
              displayName: fileName,
              filePath: entity.path,
              fileSizeMB: stat.size ~/ (1024 * 1024),
              isCustom: true,
              status: ModelStatus.downloaded,
            ));
          }
        }
      }
    }

    return models;
  }

  /// Download a model from Hugging Face
  Future<void> downloadModel(
    String modelId, {
    void Function(DownloadProgress)? onProgress,
  }) async {
    final info = ApiConstants.gemma4Models[modelId];
    if (info == null) {
      throw ArgumentError('Unknown model ID: $modelId');
    }

    final modelsDir = await StoragePaths.modelsDir;
    final filePath = p.join(modelsDir, info.fileName);
    final tempPath = '$filePath.download';

    Log.i(_tag, 'Starting download: ${info.displayName} (${info.fileSizeDisplay})');
    _downloadCancelToken = CancelToken();

    try {
      await _dio.download(
        info.downloadUrl,
        tempPath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          final progress = DownloadProgress(
            modelId: modelId,
            bytesReceived: received,
            totalBytes: total,
            percentage: total > 0 ? (received / total * 100) : 0,
          );
          _downloadProgressController.add(progress);
          onProgress?.call(progress);
        },
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
        ),
      );

      // Rename temp file to final
      await File(tempPath).rename(filePath);
      Log.i(_tag, 'Download complete: $filePath');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        Log.i(_tag, 'Download cancelled');
        // Clean up temp file
        final temp = File(tempPath);
        if (await temp.exists()) await temp.delete();
      } else {
        Log.e(_tag, 'Download failed', e);
        rethrow;
      }
    }
  }

  /// Cancel an in-progress download
  void cancelDownload() {
    _downloadCancelToken?.cancel('User cancelled');
    _downloadCancelToken = null;
  }

  /// Import a custom GGUF model from user-selected path
  Future<ModelInfo> importCustomModel(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw ArgumentError('File not found: $sourcePath');
    }
    if (!sourcePath.toLowerCase().endsWith('.gguf')) {
      throw ArgumentError('Only .gguf files are supported');
    }

    final modelsDir = await StoragePaths.modelsDir;
    final fileName = p.basename(sourcePath);
    final destPath = p.join(modelsDir, fileName);

    // Copy file to models directory
    Log.i(_tag, 'Importing custom model: $fileName');
    await file.copy(destPath);

    final stat = await File(destPath).stat();
    final model = ModelInfo(
      id: 'custom-${fileName.hashCode}',
      displayName: fileName,
      filePath: destPath,
      fileSizeMB: stat.size ~/ (1024 * 1024),
      isCustom: true,
      status: ModelStatus.downloaded,
    );

    Log.i(_tag, 'Custom model imported: ${model.displayName}');
    return model;
  }

  /// Delete a downloaded model
  Future<void> deleteModel(String modelId) async {
    final models = await listAvailableModels();
    final model = models.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw ArgumentError('Model not found: $modelId'),
    );

    if (model.filePath == null) return;
    final file = File(model.filePath!);
    if (await file.exists()) {
      await file.delete();
      Log.i(_tag, 'Deleted model: ${model.displayName}');
    }

    // If this was the active model, clear the preference
    final activeId = await getActiveModelId();
    if (activeId == modelId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeModelKey);
    }
  }

  void dispose() {
    _downloadCancelToken?.cancel();
    _downloadProgressController.close();
  }
}

class DownloadProgress {
  final String modelId;
  final int bytesReceived;
  final int totalBytes;
  final double percentage;

  const DownloadProgress({
    required this.modelId,
    required this.bytesReceived,
    required this.totalBytes,
    required this.percentage,
  });

  String get display =>
      '${(bytesReceived / (1024 * 1024)).toStringAsFixed(0)} / ${(totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB (${percentage.toStringAsFixed(1)}%)';
}
