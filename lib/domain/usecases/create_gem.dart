import '../../data/models/gem.dart';
import '../../data/repositories/gem_repository.dart';

class CreateGemUseCase {
  final GemRepository _gemRepo;

  CreateGemUseCase({required GemRepository gemRepo}) : _gemRepo = gemRepo;

  Future<Gem> execute({
    required String name,
    String systemPrompt = '',
    String icon = '💎',
    String color = '#E3AB59',
    bool ragEnabled = false,
    bool agentModeDefault = false,
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
  }) async {
    return _gemRepo.createGem(
      name: name,
      systemPrompt: systemPrompt,
      icon: icon,
      color: color,
      ragEnabled: ragEnabled,
      agentModeDefault: agentModeDefault,
      temperature: temperature,
      topP: topP,
      topK: topK,
      maxTokens: maxTokens,
    );
  }
}
