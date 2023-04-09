import 'package:notes/services/auth/auth_provider.dart';
import 'package:notes/services/auth/auth_user.dart';
import 'package:notes/services/auth/firebase_auth_provider.dart';

class AuthService implements AuthProvider {
  final AuthProvider authProvider;

  AuthService(this.authProvider);

  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());

  @override
  Future<AuthUser> createUser(
          {required String email, required String password}) =>
      authProvider.createUser(email: email, password: password);

  @override
  AuthUser? get currentUser => authProvider.currentUser;

  @override
  Future<AuthUser> login({required String email, required String password}) =>
      authProvider.login(email: email, password: password);

  @override
  Future<void> logout() => authProvider.logout();

  @override
  Future<void> sendEmailVerification() => authProvider.sendEmailVerification();

  @override
  Future<void> init() => authProvider.init();
}
