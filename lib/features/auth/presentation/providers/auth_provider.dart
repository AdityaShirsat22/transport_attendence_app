import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleettrack/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

class AuthController extends StateNotifier<bool> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(_repository.isAuthenticated);

  String? get currentEmail => _repository.currentAdminEmail;

  Future<void> login(String email, String password) async {
    await _repository.signInWithEmailPassword(email, password);
    state = _repository.isAuthenticated;
  }

  Future<void> logout() async {
    await _repository.signOut();
    state = _repository.isAuthenticated;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
