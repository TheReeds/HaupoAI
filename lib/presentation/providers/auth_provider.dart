// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/preference_model.dart';
import 'dart:io';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final PreferenceRepository _preferenceRepository;
  final SocialRepository _socialRepository;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isInitialized = false;

  AuthProvider({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    PreferenceRepository? preferenceRepository,
    SocialRepository? socialRepository,
  }) : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _preferenceRepository = preferenceRepository ?? PreferenceRepository(),
        _socialRepository = socialRepository ?? SocialRepository() {
    _init();
  }

  // Getters
  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get needsOnboarding => _user != null && !_user!.isOnboardingCompleted;
  bool get isInitialized => _isInitialized;

  // Inicializar y escuchar cambios de autenticación
  void _init() {
    _authRepository.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Usuario autenticado
        final userModel = await _authRepository.getCurrentUser();
        if (userModel != null) {
          _user = userModel;
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        // Usuario no autenticado
        _user = null;
        _state = AuthState.unauthenticated;
      }

      if (!_isInitialized) {
        _isInitialized = true;
      }

      notifyListeners();
    });
  }

  // Registro con email y contraseña
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.isSuccess) {
        _user = result.user;
        _state = AuthState.authenticated;
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Error al registrar usuario');
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      return false;
    }
  }

  // Login con email y contraseña
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        _user = result.user;
        _state = AuthState.authenticated;
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Error al iniciar sesión');
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      return false;
    }
  }

  // Login con Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.signInWithGoogle();

      if (result.isSuccess) {
        _user = result.user;
        _state = AuthState.authenticated;
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Error al iniciar sesión con Google');
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authRepository.signOut();
      _user = null;
      _state = AuthState.unauthenticated;
      _clearError();
    } catch (e) {
      _setError('Error al cerrar sesión: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Completar onboarding con preferencias
  Future<bool> completeOnboarding({
    String? gender,
    String? skinTone,
    Set<String>? selectedColors,
    Set<String>? selectedStyles,
  }) async {
    if (_user == null) return false;

    try {
      _state = AuthState.loading;
      notifyListeners();

      // Guardar preferencias si se proporcionaron
      if (gender != null || skinTone != null ||
          selectedColors != null || selectedStyles != null) {
        final preferences = PreferenceModel.fromSetup(
          userId: _user!.uid,
          gender: gender,
          skinTone: skinTone,
          selectedColors: selectedColors,
          selectedStyles: selectedStyles,
        );

        await _preferenceRepository.savePreferences(preferences);
      }

      // Actualizar estado de onboarding
      final updatedUser = await _userRepository.updateOnboardingStatus(
          _user!.uid,
          true
      );

      // IMPORTANTE: Actualizar el usuario local
      _user = updatedUser;
      _state = AuthState.authenticated;
      _errorMessage = null;

      // Notificar cambios para que el router redirija
      notifyListeners();

      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Actualizar foto de perfil (MEJORADO)
  Future<bool> updateProfilePhoto(File imageFile) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final oldPhotoURL = _user!.photoURL;

      // 1. Actualizar en Firebase Auth y Firestore
      final updatedUser = await _userRepository.updateProfilePhoto(
        _user!.uid,
        imageFile,
      );

      // 2. Actualizar todos los posts y comentarios existentes
      await _socialRepository.updateUserDataInPosts(
        _user!.uid,
        null, // No cambiar el nombre
        updatedUser.photoURL,
      );

      // 3. Actualizar usuario local
      _user = updatedUser;
      _setLoading(false);
      notifyListeners();

      print('Foto de perfil actualizada: ${oldPhotoURL} -> ${updatedUser.photoURL}');
      return true;
    } catch (e) {
      _setError('Error al actualizar foto de perfil: ${e.toString()}');
      return false;
    }
  }

  // Actualizar nombre de usuario (MEJORADO)
  Future<bool> updateDisplayName(String displayName) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final oldDisplayName = _user!.displayName;

      // 1. Actualizar en Firebase Auth y Firestore
      final updatedUser = await _userRepository.updateDisplayName(
        _user!.uid,
        displayName,
      );

      // 2. Actualizar todos los posts y comentarios existentes
      await _socialRepository.updateUserDataInPosts(
        _user!.uid,
        displayName,
        null, // No cambiar la foto
      );

      // 3. Actualizar usuario local
      _user = updatedUser;
      _setLoading(false);
      notifyListeners();

      print('Nombre actualizado: $oldDisplayName -> $displayName');
      return true;
    } catch (e) {
      _setError('Error al actualizar nombre: ${e.toString()}');
      return false;
    }
  }

  // Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al enviar email de restablecimiento: ${e.toString()}');
      return false;
    }
  }

  // Actualizar usuario después del onboarding (método legacy)
  void updateUserOnboardingStatus(bool completed) {
    if (_user != null) {
      _user = _user!.copyWith(isOnboardingCompleted: completed);
      notifyListeners();
    }
  }

  // Actualizar datos del usuario
  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _state = AuthState.error;
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
  }

  // Limpiar error manualmente
  void clearError() {
    _clearError();
    notifyListeners();
  }
}