// lib/data/repositories/face_analysis_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/face_analysis_model.dart';
import '../models/user_model.dart';
import '../../core/services/roboflow_service.dart';
import 'dart:io';

class FaceAnalysisRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoboflowService _roboflowService = RoboflowService();

  // Realizar análisis facial completo
  Future<FaceAnalysisModel> analyzeFace({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // 1. Analizar con Roboflow
      final analysis = await _roboflowService.analyzeFaceShape(
        userId: userId,
        imageFile: imageFile,
      );

      // 2. Guardar análisis en Firestore
      final savedAnalysis = await _saveFaceAnalysis(analysis);

      // 3. Actualizar información del usuario
      await _updateUserFaceInfo(userId, savedAnalysis);

      // 4. Limpiar imágenes temporales (opcional)
      _roboflowService.cleanupTempImages(userId);

      return savedAnalysis;
    } catch (e) {
      throw Exception('Error en análisis facial: $e');
    }
  }

  // Analizar desde foto de perfil existente
  Future<FaceAnalysisModel> analyzeFaceFromProfilePhoto({
    required String userId,
    required String photoURL,
  }) async {
    try {
      // 1. Analizar con Roboflow
      final analysis = await _roboflowService.analyzeFaceShapeFromUrl(
        userId: userId,
        imageUrl: photoURL,
      );

      // 2. Guardar análisis en Firestore
      final savedAnalysis = await _saveFaceAnalysis(analysis);

      // 3. Actualizar información del usuario
      await _updateUserFaceInfo(userId, savedAnalysis);

      return savedAnalysis;
    } catch (e) {
      throw Exception('Error en análisis facial: $e');
    }
  }

  // Guardar análisis en Firestore
  Future<FaceAnalysisModel> _saveFaceAnalysis(FaceAnalysisModel analysis) async {
    final docRef = await _firestore
        .collection('face_analyses')
        .add(analysis.toFirestore());

    return FaceAnalysisModel(
      id: docRef.id,
      userId: analysis.userId,
      faceShape: analysis.faceShape,
      confidence: analysis.confidence,
      imageUrl: analysis.imageUrl,
      analyzedAt: analysis.analyzedAt,
      additionalData: analysis.additionalData,
    );
  }

  // Actualizar información facial del usuario
  Future<void> _updateUserFaceInfo(String userId, FaceAnalysisModel analysis) async {
    await _firestore.collection('users').doc(userId).update({
      'currentFaceShape': analysis.faceShape,
      'faceAnalysisConfidence': analysis.confidence,
      'lastFaceAnalysis': Timestamp.fromDate(analysis.analyzedAt),
    });
  }

  // Obtener historial de análisis de un usuario
  Future<List<FaceAnalysisModel>> getUserFaceAnalyses(String userId) async {
    final snapshot = await _firestore
        .collection('face_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FaceAnalysisModel.fromFirestore(doc))
        .toList();
  }

  // Obtener último análisis de un usuario
  Future<FaceAnalysisModel?> getLatestFaceAnalysis(String userId) async {
    final snapshot = await _firestore
        .collection('face_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return FaceAnalysisModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Stream de análisis de usuario
  Stream<List<FaceAnalysisModel>> getUserFaceAnalysesStream(String userId) {
    return _firestore
        .collection('face_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FaceAnalysisModel.fromFirestore(doc))
        .toList());
  }

  // Eliminar análisis específico
  Future<void> deleteFaceAnalysis(String analysisId) async {
    await _firestore.collection('face_analyses').doc(analysisId).delete();
  }

  // Eliminar todos los análisis de un usuario
  Future<void> deleteAllUserFaceAnalyses(String userId) async {
    final batch = _firestore.batch();

    final snapshot = await _firestore
        .collection('face_analyses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Obtener estadísticas de análisis
  Future<Map<String, dynamic>> getFaceAnalysisStats(String userId) async {
    final analyses = await getUserFaceAnalyses(userId);

    if (analyses.isEmpty) {
      return {
        'totalAnalyses': 0,
        'mostCommonShape': null,
        'averageConfidence': 0.0,
        'lastAnalysisDate': null,
      };
    }

    // Contar formas de rostro
    final shapeCount = <String, int>{};
    double totalConfidence = 0.0;

    for (final analysis in analyses) {
      shapeCount[analysis.faceShape] = (shapeCount[analysis.faceShape] ?? 0) + 1;
      totalConfidence += analysis.confidence;
    }

    // Encontrar la forma más común
    String? mostCommonShape;
    int maxCount = 0;
    shapeCount.forEach((shape, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonShape = shape;
      }
    });

    return {
      'totalAnalyses': analyses.length,
      'mostCommonShape': mostCommonShape,
      'averageConfidence': totalConfidence / analyses.length,
      'lastAnalysisDate': analyses.first.analyzedAt,
      'shapeDistribution': shapeCount,
    };
  }
}