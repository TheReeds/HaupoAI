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

  // Nuevos campos para análisis
  final String? currentFaceShape;
  final double? faceAnalysisConfidence;
  final DateTime? lastFaceAnalysis;
  final String? bodyType;
  final DateTime? lastBodyAnalysis;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.isOnboardingCompleted = false,
    this.preferences,
    this.currentFaceShape,
    this.faceAnalysisConfidence,
    this.lastFaceAnalysis,
    this.bodyType,
    this.lastBodyAnalysis,
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
      currentFaceShape: data['currentFaceShape'],
      faceAnalysisConfidence: data['faceAnalysisConfidence']?.toDouble(),
      lastFaceAnalysis: data['lastFaceAnalysis'] != null
          ? (data['lastFaceAnalysis'] as Timestamp).toDate()
          : null,
      bodyType: data['bodyType'],
      lastBodyAnalysis: data['lastBodyAnalysis'] != null
          ? (data['lastBodyAnalysis'] as Timestamp).toDate()
          : null,
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
      'currentFaceShape': currentFaceShape,
      'faceAnalysisConfidence': faceAnalysisConfidence,
      'lastFaceAnalysis': lastFaceAnalysis != null
          ? Timestamp.fromDate(lastFaceAnalysis!)
          : null,
      'bodyType': bodyType,
      'lastBodyAnalysis': lastBodyAnalysis != null
          ? Timestamp.fromDate(lastBodyAnalysis!)
          : null,
    };
  }

  // Copiar con cambios
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    DateTime? lastLoginAt,
    bool? isOnboardingCompleted,
    Map<String, dynamic>? preferences,
    String? currentFaceShape,
    double? faceAnalysisConfidence,
    DateTime? lastFaceAnalysis,
    String? bodyType,
    DateTime? lastBodyAnalysis,
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
      currentFaceShape: currentFaceShape ?? this.currentFaceShape,
      faceAnalysisConfidence: faceAnalysisConfidence ?? this.faceAnalysisConfidence,
      lastFaceAnalysis: lastFaceAnalysis ?? this.lastFaceAnalysis,
      bodyType: bodyType ?? this.bodyType,
      lastBodyAnalysis: lastBodyAnalysis ?? this.lastBodyAnalysis,
    );
  }

  // Métodos de utilidad
  bool get hasFaceAnalysis => currentFaceShape != null && currentFaceShape!.isNotEmpty;
  bool get hasBodyAnalysis => bodyType != null && bodyType!.isNotEmpty;

  bool get needsFaceAnalysisUpdate {
    if (!hasFaceAnalysis) return true;
    if (lastFaceAnalysis == null) return true;
    // Sugerir actualización después de 30 días
    return DateTime.now().difference(lastFaceAnalysis!).inDays > 30;
  }

  bool get needsBodyAnalysisUpdate {
    if (!hasBodyAnalysis) return true;
    if (lastBodyAnalysis == null) return true;
    // Sugerir actualización después de 90 días
    return DateTime.now().difference(lastBodyAnalysis!).inDays > 90;
  }
}