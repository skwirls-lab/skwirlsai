import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../../domain/entities/model_info.dart';
import '../../core/utils/logger.dart';

class HardwareAnalyzer {
  static const _tag = 'HardwareAnalyzer';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<HardwareInfo> analyze() async {
    Log.i(_tag, 'Analyzing hardware capabilities...');

    if (Platform.isWindows) return _analyzeWindows();
    if (Platform.isAndroid) return _analyzeAndroid();
    if (Platform.isLinux) return _analyzeLinux();
    if (Platform.isMacOS) return _analyzeMacOS();

    return _fallbackInfo();
  }

  Future<HardwareInfo> _analyzeWindows() async {
    final info = await _deviceInfo.windowsInfo;

    final totalRamMB = info.systemMemoryInMegabytes;
    final cpuCores = Platform.numberOfProcessors;

    // Attempt to detect VRAM via platform channel (best-effort)
    int? vramMB;
    try {
      vramMB = await _detectVramWindows();
    } catch (e) {
      Log.w(_tag, 'Could not detect VRAM: $e');
    }

    final availableStorage = await _getAvailableStorage();

    Log.i(_tag, 'Windows: ${totalRamMB}MB RAM, $cpuCores cores, VRAM: ${vramMB ?? "unknown"}MB');

    return HardwareInfo(
      totalRamMB: totalRamMB,
      availableRamMB: totalRamMB, // Approximation
      vramMB: vramMB,
      cpuCores: cpuCores,
      cpuArchitecture: _getCpuArch(),
      availableStorageMB: availableStorage,
      platformName: 'Windows',
    );
  }

  Future<HardwareInfo> _analyzeAndroid() async {
    final info = await _deviceInfo.androidInfo;

    // Android doesn't expose RAM directly through device_info_plus
    // Use /proc/meminfo for more accurate reading
    int totalRamMB = 4096; // Conservative default
    int availableRamMB = 2048;

    try {
      final meminfo = await File('/proc/meminfo').readAsString();
      final totalMatch = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(meminfo);
      final availMatch = RegExp(r'MemAvailable:\s+(\d+)\s+kB').firstMatch(meminfo);

      if (totalMatch != null) {
        totalRamMB = int.parse(totalMatch.group(1)!) ~/ 1024;
      }
      if (availMatch != null) {
        availableRamMB = int.parse(availMatch.group(1)!) ~/ 1024;
      }
    } catch (e) {
      Log.w(_tag, 'Could not read /proc/meminfo: $e');
    }

    final cpuCores = Platform.numberOfProcessors;
    final availableStorage = await _getAvailableStorage();

    Log.i(_tag, 'Android ${info.model}: ${totalRamMB}MB RAM, $cpuCores cores');

    return HardwareInfo(
      totalRamMB: totalRamMB,
      availableRamMB: availableRamMB,
      vramMB: null, // Mobile GPU shares system RAM
      cpuCores: cpuCores,
      cpuArchitecture: _getCpuArch(),
      availableStorageMB: availableStorage,
      platformName: 'Android (${info.model})',
    );
  }

  Future<HardwareInfo> _analyzeLinux() async {
    final info = await _deviceInfo.linuxInfo;

    int totalRamMB = 8192;
    int availableRamMB = 4096;

    try {
      final meminfo = await File('/proc/meminfo').readAsString();
      final totalMatch = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(meminfo);
      final availMatch = RegExp(r'MemAvailable:\s+(\d+)\s+kB').firstMatch(meminfo);

      if (totalMatch != null) {
        totalRamMB = int.parse(totalMatch.group(1)!) ~/ 1024;
      }
      if (availMatch != null) {
        availableRamMB = int.parse(availMatch.group(1)!) ~/ 1024;
      }
    } catch (e) {
      Log.w(_tag, 'Could not read /proc/meminfo: $e');
    }

    int? vramMB;
    try {
      vramMB = await _detectVramLinux();
    } catch (e) {
      Log.w(_tag, 'Could not detect VRAM: $e');
    }

    final cpuCores = Platform.numberOfProcessors;
    final availableStorage = await _getAvailableStorage();

    Log.i(_tag, 'Linux ${info.prettyName}: ${totalRamMB}MB RAM, $cpuCores cores, VRAM: ${vramMB ?? "unknown"}MB');

    return HardwareInfo(
      totalRamMB: totalRamMB,
      availableRamMB: availableRamMB,
      vramMB: vramMB,
      cpuCores: cpuCores,
      cpuArchitecture: _getCpuArch(),
      availableStorageMB: availableStorage,
      platformName: 'Linux (${info.prettyName})',
    );
  }

  Future<HardwareInfo> _analyzeMacOS() async {
    final info = await _deviceInfo.macOsInfo;

    // macOS doesn't expose system memory via device_info_plus
    // Estimate based on typical Apple Silicon or Intel specs
    final totalRamMB = 8192; // Default to 8GB estimate
    final cpuCores = Platform.numberOfProcessors;
    final availableStorage = await _getAvailableStorage();

    Log.i(_tag, 'macOS ${info.computerName}: ~${totalRamMB}MB RAM, $cpuCores cores');

    return HardwareInfo(
      totalRamMB: totalRamMB,
      availableRamMB: totalRamMB,
      vramMB: null, // Unified memory on Apple Silicon
      cpuCores: cpuCores,
      cpuArchitecture: _getCpuArch(),
      availableStorageMB: availableStorage,
      platformName: 'macOS (${info.model})',
    );
  }

  HardwareInfo _fallbackInfo() {
    return HardwareInfo(
      totalRamMB: 4096,
      availableRamMB: 2048,
      cpuCores: Platform.numberOfProcessors,
      cpuArchitecture: _getCpuArch(),
      availableStorageMB: 10000,
      platformName: Platform.operatingSystem,
    );
  }

  String _getCpuArch() {
    // Dart doesn't expose CPU architecture directly; use platform info
    if (Platform.version.contains('arm64') ||
        Platform.version.contains('aarch64')) {
      return 'ARM64';
    }
    return 'x86_64';
  }

  Future<int> _getAvailableStorage() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'logicaldisk',
          'where',
          'DeviceID="C:"',
          'get',
          'FreeSpace',
          '/format:value',
        ]);
        final match = RegExp(r'FreeSpace=(\d+)').firstMatch(result.stdout as String);
        if (match != null) {
          return int.parse(match.group(1)!) ~/ (1024 * 1024);
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('df', ['-m', '/']);
        final lines = (result.stdout as String).split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            return int.tryParse(parts[3]) ?? 10000;
          }
        }
      }
    } catch (e) {
      Log.w(_tag, 'Could not detect available storage: $e');
    }
    return 10000; // 10GB fallback
  }

  Future<int?> _detectVramWindows() async {
    // Uses wmic to query GPU memory
    try {
      final result = await Process.run('wmic', [
        'path',
        'win32_VideoController',
        'get',
        'AdapterRAM',
        '/format:value',
      ]);
      final match = RegExp(r'AdapterRAM=(\d+)').firstMatch(result.stdout as String);
      if (match != null) {
        return int.parse(match.group(1)!) ~/ (1024 * 1024);
      }
    } catch (_) {}
    return null;
  }

  Future<int?> _detectVramLinux() async {
    // Try nvidia-smi first
    try {
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=memory.total',
        '--format=csv,noheader,nounits',
      ]);
      if (result.exitCode == 0) {
        return int.tryParse((result.stdout as String).trim());
      }
    } catch (_) {}
    return null;
  }
}
