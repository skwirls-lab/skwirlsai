import '../../data/models/gem.dart';
import '../../data/repositories/gem_repository.dart';

class CreateAcornUseCase {
  final AcornRepository _acornRepo;

  CreateAcornUseCase({required AcornRepository acornRepo}) : _acornRepo = acornRepo;

  Future<Acorn> execute({
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
    return _acornRepo.createAcorn(
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
