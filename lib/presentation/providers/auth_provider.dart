import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../domain/entities/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  // Watch the stream so we re-evaluate when auth state changes
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  // Watch the stream to stay reactive
  ref.watch(authStateProvider);
  final user = ref.watch(authServiceProvider).currentUser;
  return user != null && !user.isAnonymous;
});
