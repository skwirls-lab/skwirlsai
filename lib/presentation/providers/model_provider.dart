import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/model_service.dart';
import '../../data/services/inference_service.dart';
import '../../data/services/hardware_analyzer.dart';
import '../../domain/entities/model_info.dart';

final hardwareAnalyzerProvider = Provider<HardwareAnalyzer>((ref) {
  return HardwareAnalyzer();
});

final hardwareInfoProvider = FutureProvider<HardwareInfo>((ref) async {
  final analyzer = ref.watch(hardwareAnalyzerProvider);
  return analyzer.analyze();
});

final modelServiceProvider = Provider<ModelService>((ref) {
  final service = ModelService();
  ref.onDispose(() => service.dispose());
  return service;
});

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  final service = InferenceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final availableModelsProvider = FutureProvider<List<ModelInfo>>((ref) async {
  final modelService = ref.watch(modelServiceProvider);
  return modelService.listAvailableModels();
});

final activeModelIdProvider = FutureProvider<String?>((ref) async {
  final modelService = ref.watch(modelServiceProvider);
  return modelService.getActiveModelId();
});

final downloadProgressProvider = StreamProvider<DownloadProgress>((ref) {
  final modelService = ref.watch(modelServiceProvider);
  return modelService.downloadProgress;
});

/// Manually toggled after connect/disconnect to keep UI in sync.
final isModelLoadedProvider = StateProvider<bool>((ref) => false);

final isGeneratingProvider = Provider<bool>((ref) {
  final inferenceService = ref.watch(inferenceServiceProvider);
  return inferenceService.isGenerating;
});
