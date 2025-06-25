// lib/data/datasources/auth_datasource.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/errors/exceptions.dart';

class AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Usuario actual
  User? get currentUser => _firebaseAuth.currentUser;

  // Registro con email y contraseña
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Actualizar el displayName si se proporcionó
        if (displayName != null && displayName.isNotEmpty) {
          await result.user!.updateDisplayName(displayName);
          await result.user!.reload();
        }

        // Crear modelo de usuario
        final userModel = UserModel.fromFirebaseUser(
          result.user!,
          isOnboardingCompleted: false,
        );

        // Guardar en Firestore
        await _saveUserToFirestore(userModel);

        return AuthResult.success(userModel, isNewUser: true);
      } else {
        return AuthResult.failure('Error al crear el usuario');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Error inesperado: ${e.toString()}');
    }
  }

  // Login con email y contraseña
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Obtener datos del usuario desde Firestore
        final userModel = await _getUserFromFirestore(result.user!.uid);

        if (userModel != null) {
          // Actualizar último login
          final updatedUser = userModel.copyWith(
            lastLoginAt: DateTime.now(),
          );
          await _updateUserInFirestore(updatedUser);

          return AuthResult.success(updatedUser);
        } else {
          // Si no existe en Firestore, crearlo
          final newUserModel = UserModel.fromFirebaseUser(result.user!);
          await _saveUserToFirestore(newUserModel);
          return AuthResult.success(newUserModel);
        }
      } else {
        return AuthResult.failure('Error al iniciar sesión');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Error inesperado: ${e.toString()}');
    }
  }

  // Login con Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Login con Google cancelado');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result =
      await _firebaseAuth.signInWithCredential(credential);

      if (result.user != null) {
        // Verificar si es un usuario nuevo
        final bool isNewUser = result.additionalUserInfo?.isNewUser ?? false;

        // Obtener o crear usuario en Firestore
        UserModel userModel;
        if (isNewUser) {
          userModel = UserModel.fromFirebaseUser(
            result.user!,
            isOnboardingCompleted: false,
          );
          await _saveUserToFirestore(userModel);
        } else {
          final existingUser = await _getUserFromFirestore(result.user!.uid);
          if (existingUser != null) {
            userModel = existingUser.copyWith(lastLoginAt: DateTime.now());
            await _updateUserInFirestore(userModel);
          } else {
            userModel = UserModel.fromFirebaseUser(result.user!);
            await _saveUserToFirestore(userModel);
          }
        }

        return AuthResult.success(userModel, isNewUser: isNewUser);
      } else {
        return AuthResult.failure('Error al iniciar sesión con Google');
      }
    } catch (e) {
      return AuthResult.failure('Error con Google Sign-In: ${e.toString()}');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Error al cerrar sesión: ${e.toString()}');
    }
  }

  // Obtener usuario actual desde Firestore
  Future<UserModel?> getCurrentUser() async {
    final user = currentUser;
    if (user != null) {
      return await _getUserFromFirestore(user.uid);
    }
    return null;
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseAuthErrorMessage(e));
    }
  }

  // Métodos privados
  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<void> _updateUserInFirestore(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toFirestore());
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mensajes de error en español
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'El formato del email no es válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}