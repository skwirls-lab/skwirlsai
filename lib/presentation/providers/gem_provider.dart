import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gem.dart';
import '../../data/repositories/gem_repository.dart';
import 'database_provider.dart';

final acornRepositoryProvider = Provider<AcornRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return AcornRepository(isar: isar);
});

final allAcornsProvider = FutureProvider<List<Acorn>>((ref) async {
  final repo = ref.watch(acornRepositoryProvider);
  return repo.getAllAcorns();
});

final activeAcornProvider = StateProvider<Acorn?>((ref) => null);

final acornByIdProvider = FutureProvider.family<Acorn?, String>((ref, uuid) async {
  final repo = ref.watch(acornRepositoryProvider);
  return repo.getAcorn(uuid);
});
