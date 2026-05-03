import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gem.dart';
import '../../data/repositories/gem_repository.dart';
import 'database_provider.dart';

final gemRepositoryProvider = Provider<GemRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return GemRepository(isar: isar);
});

final allGemsProvider = FutureProvider<List<Gem>>((ref) async {
  final repo = ref.watch(gemRepositoryProvider);
  return repo.getAllGems();
});

final activeGemProvider = StateProvider<Gem?>((ref) => null);

final gemByIdProvider = FutureProvider.family<Gem?, String>((ref, uuid) async {
  final repo = ref.watch(gemRepositoryProvider);
  return repo.getGem(uuid);
});
