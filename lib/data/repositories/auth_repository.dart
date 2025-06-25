// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../datasources/auth_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepository({AuthDataSource? authDataSource})
      : _authDataSource = authDataSource ?? AuthDataSource();

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _authDataSource.authStateChanges;

  // Usuario actual
  User? get currentUser => _authDataSource.currentUser;

  // Registro con email y contraseña
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _authDataSource.registerWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  // Login con email y contraseña
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _authDataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Login con Google
  Future<AuthResult> signInWithGoogle() async {
    return await _authDataSource.signInWithGoogle();
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  // Obtener usuario actual
  Future<UserModel?> getCurrentUser() async {
    return await _authDataSource.getCurrentUser();
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    await _authDataSource.resetPassword(email);
  }

  // Verificar si el usuario está autenticado
  bool get isAuthenticated => currentUser != null;
}