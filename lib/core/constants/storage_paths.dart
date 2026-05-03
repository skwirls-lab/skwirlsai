import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StoragePaths {
  StoragePaths._();

  static Future<String> get modelsDir async {
    final appDir = await _appSupportDir;
    final dir = Directory(p.join(appDir, 'models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get documentsDir async {
    final appDir = await _appSupportDir;
    final dir = Directory(p.join(appDir, 'documents'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get cacheDir async {
    final appDir = await _appSupportDir;
    final dir = Directory(p.join(appDir, 'cache'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get generatedMediaDir async {
    final appDir = await _appSupportDir;
    final dir = Directory(p.join(appDir, 'generated'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get _appSupportDir async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  /// Platform-aware display path for the user
  static String get platformModelHint {
    if (Platform.isWindows) {
      return r'%LOCALAPPDATA%\SkwirlsAI\models\';
    } else if (Platform.isAndroid) {
      return 'Internal Storage/SkwirlsAI/models/';
    } else if (Platform.isLinux) {
      return '~/.local/share/SkwirlsAI/models/';
    } else if (Platform.isMacOS) {
      return '~/Library/Application Support/SkwirlsAI/models/';
    }
    return 'SkwirlsAI/models/';
  }
}
