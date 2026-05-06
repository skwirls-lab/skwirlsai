import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../models/gem.dart';

class AcornRepository {
  static const _tag = 'AcornRepo';
  final Isar _isar;
  final _uuid = const Uuid();

  AcornRepository({required Isar isar}) : _isar = isar;

  /// Initialize default acorns on first run
  Future<void> initializeDefaults() async {
    final count = await _isar.acorns.count();
    if (count > 0) return;

    Log.i(_tag, 'Initializing default acorns...');
    final defaults = Acorn.defaults;

    await _isar.writeTxn(() async {
      for (final acorn in defaults) {
        await _isar.acorns.put(acorn);
      }
    });

    Log.i(_tag, 'Created ${defaults.length} default acorns');
  }

  /// Get all acorns, with General Assistant first, then defaults, then custom
  Future<List<Acorn>> getAllAcorns() async {
    final all = await _isar.acorns.where().findAll();
    all.sort((a, b) {
      // General Assistant always first
      if (a.uuid == 'acorn-general-assistant') return -1;
      if (b.uuid == 'acorn-general-assistant') return 1;
      // Defaults before custom
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      // Within same category, sort by name
      return a.name.compareTo(b.name);
    });
    return all;
  }

  /// Get an acorn by UUID
  Future<Acorn?> getAcorn(String uuid) async {
    return _isar.acorns.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Create a new acorn
  Future<Acorn> createAcorn({
    required String name,
    String systemPrompt = '',
    String icon = '💎',
    String color = '#E3AB59',
    bool ragEnabled = false,
    bool agentModeDefault = false,
    String enabledSkills = '',
    String defaultModelId = '',
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
  }) async {
    final now = DateTime.now();
    final acorn = Acorn()
      ..uuid = _uuid.v4()
      ..name = name
      ..systemPrompt = systemPrompt
      ..icon = icon
      ..color = color
      ..createdAt = now
      ..updatedAt = now
      ..ragEnabled = ragEnabled
      ..agentModeDefault = agentModeDefault
      ..enabledSkills = enabledSkills
      ..defaultModelId = defaultModelId
      ..temperature = temperature
      ..topP = topP
      ..topK = topK
      ..maxTokens = maxTokens;

    await _isar.writeTxn(() async {
      await _isar.acorns.put(acorn);
    });

    Log.i(_tag, 'Created acorn: $name (${acorn.uuid})');
    return acorn;
  }

  /// Update an existing acorn
  Future<void> updateAcorn(Acorn acorn) async {
    acorn.updatedAt = DateTime.now();
    acorn.syncVersion++;

    await _isar.writeTxn(() async {
      await _isar.acorns.put(acorn);
    });

    Log.i(_tag, 'Updated acorn: ${acorn.name}');
  }

  /// Delete an acorn (requires at least one acorn to remain)
  Future<bool> deleteAcorn(String uuid) async {
    final acorn = await getAcorn(uuid);
    if (acorn == null) return false;

    final count = await _isar.acorns.count();
    if (count <= 1) {
      Log.w(_tag, 'Cannot delete last acorn');
      return false;
    }

    await _isar.writeTxn(() async {
      await _isar.acorns.delete(acorn.id);
    });

    Log.i(_tag, 'Deleted acorn: ${acorn.name}');
    return true;
  }

  /// Get the "General Assistant" default acorn
  Future<Acorn> getDefaultAcorn() async {
    final acorn = await _isar.acorns
        .filter()
        .uuidEqualTo('acorn-general-assistant')
        .findFirst();

    if (acorn != null) return acorn;

    // Fallback: return first acorn
    final all = await getAllAcorns();
    if (all.isNotEmpty) return all.first;

    // Last resort: create defaults and return
    await initializeDefaults();
    return (await getAllAcorns()).first;
  }
}
