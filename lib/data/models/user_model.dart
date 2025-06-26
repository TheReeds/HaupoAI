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

  // Campos para análisis facial
  final String? currentFaceShape;
  final double? faceAnalysisConfidence;
  final DateTime? lastFaceAnalysis;

  // Campos para análisis de cabello
  final String? currentHairType;
  final double? hairAnalysisConfidence;
  final DateTime? lastHairAnalysis;

  // Campos para análisis corporal
  final String? bodyType;
  final String? bodyShape;
  final String? detectedGender;
  final double? bodyTypeConfidence;
  final double? bodyShapeConfidence;
  final double? genderConfidence;
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
    this.currentHairType,
    this.hairAnalysisConfidence,
    this.lastHairAnalysis,
    this.bodyType,
    this.bodyShape,
    this.detectedGender,
    this.bodyTypeConfidence,
    this.bodyShapeConfidence,
    this.genderConfidence,
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
      currentHairType: data['currentHairType'],
      hairAnalysisConfidence: data['hairAnalysisConfidence']?.toDouble(),
      lastHairAnalysis: data['lastHairAnalysis'] != null
          ? (data['lastHairAnalysis'] as Timestamp).toDate()
          : null,
      bodyType: data['bodyType'],
      bodyShape: data['bodyShape'],
      detectedGender: data['detectedGender'],
      bodyTypeConfidence: data['bodyTypeConfidence']?.toDouble(),
      bodyShapeConfidence: data['bodyShapeConfidence']?.toDouble(),
      genderConfidence: data['genderConfidence']?.toDouble(),
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
      'currentHairType': currentHairType,
      'hairAnalysisConfidence': hairAnalysisConfidence,
      'lastHairAnalysis': lastHairAnalysis != null
          ? Timestamp.fromDate(lastHairAnalysis!)
          : null,
      'bodyType': bodyType,
      'bodyShape': bodyShape,
      'detectedGender': detectedGender,
      'bodyTypeConfidence': bodyTypeConfidence,
      'bodyShapeConfidence': bodyShapeConfidence,
      'genderConfidence': genderConfidence,
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
    String? currentHairType,
    double? hairAnalysisConfidence,
    DateTime? lastHairAnalysis,
    String? bodyType,
    String? bodyShape,
    String? detectedGender,
    double? bodyTypeConfidence,
    double? bodyShapeConfidence,
    double? genderConfidence,
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
      currentHairType: currentHairType ?? this.currentHairType,
      hairAnalysisConfidence: hairAnalysisConfidence ?? this.hairAnalysisConfidence,
      lastHairAnalysis: lastHairAnalysis ?? this.lastHairAnalysis,
      bodyType: bodyType ?? this.bodyType,
      bodyShape: bodyShape ?? this.bodyShape,
      detectedGender: detectedGender ?? this.detectedGender,
      bodyTypeConfidence: bodyTypeConfidence ?? this.bodyTypeConfidence,
      bodyShapeConfidence: bodyShapeConfidence ?? this.bodyShapeConfidence,
      genderConfidence: genderConfidence ?? this.genderConfidence,
      lastBodyAnalysis: lastBodyAnalysis ?? this.lastBodyAnalysis,
    );
  }

  // Métodos de utilidad
  bool get hasFaceAnalysis => currentFaceShape != null && currentFaceShape!.isNotEmpty;
  bool get hasHairAnalysis => currentHairType != null && currentHairType!.isNotEmpty;
  bool get hasBodyAnalysis => bodyType != null && bodyType!.isNotEmpty;
  bool get hasCompleteAnalysis => hasFaceAnalysis && hasHairAnalysis && hasBodyAnalysis;

  bool get needsFaceAnalysisUpdate {
    if (!hasFaceAnalysis) return true;
    if (lastFaceAnalysis == null) return true;
    // Sugerir actualización después de 30 días
    return DateTime.now().difference(lastFaceAnalysis!).inDays > 30;
  }

  bool get needsHairAnalysisUpdate {
    if (!hasHairAnalysis) return true;
    if (lastHairAnalysis == null) return true;
    // Sugerir actualización después de 60 días (el cabello cambia más lento)
    return DateTime.now().difference(lastHairAnalysis!).inDays > 60;
  }

  bool get needsBodyAnalysisUpdate {
    if (!hasBodyAnalysis) return true;
    if (lastBodyAnalysis == null) return true;
    // Sugerir actualización después de 90 días
    return DateTime.now().difference(lastBodyAnalysis!).inDays > 90;
  }

  // Obtener porcentaje de perfil completo
  double get profileCompletenessPercentage {
    double completion = 0.0;

    // Información básica (30%)
    if (displayName != null && displayName!.isNotEmpty) completion += 0.1;
    if (photoURL != null && photoURL!.isNotEmpty) completion += 0.1;
    if (isOnboardingCompleted) completion += 0.1;

    // Análisis facial (35%)
    if (hasFaceAnalysis) completion += 0.35;

    // Análisis de cabello (25%)
    if (hasHairAnalysis) completion += 0.25;

    // Análisis corporal (15%)
    if (hasBodyAnalysis) completion += 0.15;

    return completion;
  }

  // Obtener siguiente paso recomendado
  String get nextRecommendedStep {
    if (!isOnboardingCompleted) return 'Completar configuración inicial';
    if (displayName == null || displayName!.isEmpty) return 'Agregar nombre de usuario';
    if (photoURL == null || photoURL!.isEmpty) return 'Subir foto de perfil';
    if (!hasFaceAnalysis) return 'Realizar análisis facial';
    if (!hasHairAnalysis) return 'Realizar análisis de cabello';
    if (!hasBodyAnalysis) return 'Realizar análisis corporal';
    if (needsFaceAnalysisUpdate) return 'Actualizar análisis facial';
    if (needsHairAnalysisUpdate) return 'Actualizar análisis de cabello';
    if (needsBodyAnalysisUpdate) return 'Actualizar análisis corporal';
    return 'Perfil completo';
  }
}