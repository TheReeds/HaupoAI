// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isOnboardingCompleted;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.isOnboardingCompleted = false,
    this.preferences,
  });

  // Crear desde Firebase User
  factory UserModel.fromFirebaseUser(
      firebase_auth.User firebaseUser, {
        bool isOnboardingCompleted = false,
        Map<String, dynamic>? preferences,
      }) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isOnboardingCompleted: isOnboardingCompleted,
      preferences: preferences,
    );
  }

  // Crear desde Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isOnboardingCompleted: data['isOnboardingCompleted'] ?? false,
      preferences: data['preferences'],
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'isOnboardingCompleted': isOnboardingCompleted,
      'preferences': preferences,
    };
  }

  // Copiar con cambios
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    DateTime? lastLoginAt,
    bool? isOnboardingCompleted,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      preferences: preferences ?? this.preferences,
    );
  }
}

// lib/data/models/auth_result.dart
class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;
  final bool isNewUser;

  AuthResult({
    required this.isSuccess,
    this.user,
    this.error,
    this.isNewUser = false,
  });

  factory AuthResult.success(UserModel user, {bool isNewUser = false}) {
    return AuthResult(
      isSuccess: true,
      user: user,
      isNewUser: isNewUser,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult(
      isSuccess: false,
      error: error,
    );
  }
}