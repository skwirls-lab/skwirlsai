import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Isar database instance - must be overridden in ProviderScope
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'Isar instance must be initialized before app start '
    'and provided via ProviderScope override.',
  );
});
