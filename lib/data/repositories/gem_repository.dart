import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../models/gem.dart';

class GemRepository {
  static const _tag = 'GemRepo';
  final Isar _isar;
  final _uuid = const Uuid();

  GemRepository({required Isar isar}) : _isar = isar;

  /// Initialize default gems on first run
  Future<void> initializeDefaults() async {
    final count = await _isar.gems.count();
    if (count > 0) return;

    Log.i(_tag, 'Initializing default gems...');
    final defaults = Gem.defaults;

    await _isar.writeTxn(() async {
      for (final gem in defaults) {
        await _isar.gems.put(gem);
      }
    });

    Log.i(_tag, 'Created ${defaults.length} default gems');
  }

  /// Get all gems
  Future<List<Gem>> getAllGems() async {
    return _isar.gems.where().sortByName().findAll();
  }

  /// Get a gem by UUID
  Future<Gem?> getGem(String uuid) async {
    return _isar.gems.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Create a new gem
  Future<Gem> createGem({
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
    final now = DateTime.now();
    final gem = Gem()
      ..uuid = _uuid.v4()
      ..name = name
      ..systemPrompt = systemPrompt
      ..icon = icon
      ..color = color
      ..createdAt = now
      ..updatedAt = now
      ..ragEnabled = ragEnabled
      ..agentModeDefault = agentModeDefault
      ..temperature = temperature
      ..topP = topP
      ..topK = topK
      ..maxTokens = maxTokens;

    await _isar.writeTxn(() async {
      await _isar.gems.put(gem);
    });

    Log.i(_tag, 'Created gem: $name (${gem.uuid})');
    return gem;
  }

  /// Update an existing gem
  Future<void> updateGem(Gem gem) async {
    gem.updatedAt = DateTime.now();
    gem.syncVersion++;

    await _isar.writeTxn(() async {
      await _isar.gems.put(gem);
    });

    Log.i(_tag, 'Updated gem: ${gem.name}');
  }

  /// Delete a gem (only if not a default)
  Future<bool> deleteGem(String uuid) async {
    final gem = await getGem(uuid);
    if (gem == null) return false;
    if (gem.isDefault) {
      Log.w(_tag, 'Cannot delete default gem: ${gem.name}');
      return false;
    }

    await _isar.writeTxn(() async {
      await _isar.gems.delete(gem.id);
    });

    Log.i(_tag, 'Deleted gem: ${gem.name}');
    return true;
  }

  /// Get the "General Assistant" default gem
  Future<Gem> getDefaultGem() async {
    final gem = await _isar.gems
        .filter()
        .uuidEqualTo('gem-general-assistant')
        .findFirst();

    if (gem != null) return gem;

    // Fallback: return first gem
    final all = await getAllGems();
    if (all.isNotEmpty) return all.first;

    // Last resort: create defaults and return
    await initializeDefaults();
    return (await getAllGems()).first;
  }
}
