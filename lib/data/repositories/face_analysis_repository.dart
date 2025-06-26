// lib/data/repositories/face_analysis_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/face_analysis_model.dart';
import '../models/hair_analysis_model.dart';
import '../models/user_model.dart';
import '../../core/services/roboflow_service.dart';
import 'dart:io';

class FaceAnalysisRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoboflowService _roboflowService = RoboflowService();

  // Realizar análisis completo (cara y cabello)
  Future<Map<String, dynamic>> analyzeCompleteProfile({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // 1. Analizar con Roboflow (ambos modelos)
      final analysisResults = await _roboflowService.analyzeCompleteProfile(
        userId: userId,
        imageFile: imageFile,
      );

      final faceAnalysis = analysisResults['faceAnalysis'] as FaceAnalysisModel;
      final hairAnalysis = analysisResults['hairAnalysis'] as HairAnalysisModel;

      // 2. Guardar ambos análisis en Firestore
      final savedFaceAnalysis = await _saveFaceAnalysis(faceAnalysis);
      final savedHairAnalysis = await _saveHairAnalysis(hairAnalysis);

      // 3. Limpiar imágenes temporales (opcional)
      _roboflowService.cleanupTempImages(userId);

      return {
        'faceAnalysis': savedFaceAnalysis,
        'hairAnalysis': savedHairAnalysis,
        'imageUrl': analysisResults['imageUrl'],
      };
    } catch (e) {
      throw Exception('Error en análisis completo: $e');
    }
  }

  // Analizar desde foto de perfil existente (completo)
  Future<Map<String, dynamic>> analyzeCompleteProfileFromPhoto({
    required String userId,
    required String photoURL,
  }) async {
    try {
      // 1. Analizar con Roboflow
      final analysisResults = await _roboflowService.analyzeCompleteProfileFromUrl(
        userId: userId,
        imageUrl: photoURL,
      );

      final faceAnalysis = analysisResults['faceAnalysis'] as FaceAnalysisModel;
      final hairAnalysis = analysisResults['hairAnalysis'] as HairAnalysisModel;

      // 2. Guardar ambos análisis en Firestore
      final savedFaceAnalysis = await _saveFaceAnalysis(faceAnalysis);
      final savedHairAnalysis = await _saveHairAnalysis(hairAnalysis);

      return {
        'faceAnalysis': savedFaceAnalysis,
        'hairAnalysis': savedHairAnalysis,
        'imageUrl': analysisResults['imageUrl'],
      };
    } catch (e) {
      throw Exception('Error en análisis completo: $e');
    }
  }

  // Métodos legacy para compatibilidad (solo análisis facial)
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

      // 3. Limpiar imágenes temporales (opcional)
      _roboflowService.cleanupTempImages(userId);

      return savedAnalysis;
    } catch (e) {
      throw Exception('Error en análisis facial: $e');
    }
  }

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

      return savedAnalysis;
    } catch (e) {
      throw Exception('Error en análisis facial: $e');
    }
  }

  // Guardar información del análisis completo en el perfil del usuario
  Future<void> saveAnalysisToUserProfile({
    required String userId,
    FaceAnalysisModel? faceAnalysis,
    HairAnalysisModel? hairAnalysis,
  }) async {
    final updateData = <String, dynamic>{};

    if (faceAnalysis != null) {
      updateData.addAll({
        'currentFaceShape': faceAnalysis.faceShape,
        'faceAnalysisConfidence': faceAnalysis.confidence,
        'lastFaceAnalysis': Timestamp.fromDate(faceAnalysis.analyzedAt),
      });
    }

    if (hairAnalysis != null) {
      updateData.addAll({
        'currentHairType': hairAnalysis.hairType,
        'hairAnalysisConfidence': hairAnalysis.confidence,
        'lastHairAnalysis': Timestamp.fromDate(hairAnalysis.analyzedAt),
      });
    }

    if (updateData.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updateData);
    }
  }

  // Guardar análisis facial en Firestore
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

  // Guardar análisis de cabello en Firestore
  Future<HairAnalysisModel> _saveHairAnalysis(HairAnalysisModel analysis) async {
    final docRef = await _firestore
        .collection('hair_analyses')
        .add(analysis.toFirestore());

    return HairAnalysisModel(
      id: docRef.id,
      userId: analysis.userId,
      hairType: analysis.hairType,
      confidence: analysis.confidence,
      imageUrl: analysis.imageUrl,
      analyzedAt: analysis.analyzedAt,
      additionalData: analysis.additionalData,
    );
  }

  // Obtener historial de análisis faciales de un usuario
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

  // Obtener historial de análisis de cabello de un usuario
  Future<List<HairAnalysisModel>> getUserHairAnalyses(String userId) async {
    final snapshot = await _firestore
        .collection('hair_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => HairAnalysisModel.fromFirestore(doc))
        .toList();
  }

  // Obtener último análisis facial de un usuario
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

  // Obtener último análisis de cabello de un usuario
  Future<HairAnalysisModel?> getLatestHairAnalysis(String userId) async {
    final snapshot = await _firestore
        .collection('hair_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return HairAnalysisModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Obtener ambos análisis más recientes
  Future<Map<String, dynamic>> getLatestCompleteAnalysis(String userId) async {
    final faceAnalysis = await getLatestFaceAnalysis(userId);
    final hairAnalysis = await getLatestHairAnalysis(userId);

    return {
      'faceAnalysis': faceAnalysis,
      'hairAnalysis': hairAnalysis,
    };
  }

  // Stream de análisis faciales de usuario
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

  // Stream de análisis de cabello de usuario
  Stream<List<HairAnalysisModel>> getUserHairAnalysesStream(String userId) {
    return _firestore
        .collection('hair_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HairAnalysisModel.fromFirestore(doc))
        .toList());
  }

  // Eliminar análisis específicos
  Future<void> deleteFaceAnalysis(String analysisId) async {
    await _firestore.collection('face_analyses').doc(analysisId).delete();
  }

  Future<void> deleteHairAnalysis(String analysisId) async {
    await _firestore.collection('hair_analyses').doc(analysisId).delete();
  }

  // Eliminar todos los análisis de un usuario
  Future<void> deleteAllUserAnalyses(String userId) async {
    final batch = _firestore.batch();

    // Eliminar análisis faciales
    final faceSnapshot = await _firestore
        .collection('face_analyses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in faceSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Eliminar análisis de cabello
    final hairSnapshot = await _firestore
        .collection('hair_analyses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in hairSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Obtener estadísticas completas de análisis
  Future<Map<String, dynamic>> getCompleteAnalysisStats(String userId) async {
    final faceAnalyses = await getUserFaceAnalyses(userId);
    final hairAnalyses = await getUserHairAnalyses(userId);

    // Estadísticas faciales
    Map<String, dynamic> faceStats = {
      'totalAnalyses': 0,
      'mostCommonShape': null,
      'averageConfidence': 0.0,
      'lastAnalysisDate': null,
    };

    if (faceAnalyses.isNotEmpty) {
      final shapeCount = <String, int>{};
      double totalConfidence = 0.0;

      for (final analysis in faceAnalyses) {
        shapeCount[analysis.faceShape] = (shapeCount[analysis.faceShape] ?? 0) + 1;
        totalConfidence += analysis.confidence;
      }

      String? mostCommonShape;
      int maxCount = 0;
      shapeCount.forEach((shape, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonShape = shape;
        }
      });

      faceStats = {
        'totalAnalyses': faceAnalyses.length,
        'mostCommonShape': mostCommonShape,
        'averageConfidence': totalConfidence / faceAnalyses.length,
        'lastAnalysisDate': faceAnalyses.first.analyzedAt,
        'shapeDistribution': shapeCount,
      };
    }

    // Estadísticas de cabello
    Map<String, dynamic> hairStats = {
      'totalAnalyses': 0,
      'mostCommonType': null,
      'averageConfidence': 0.0,
      'lastAnalysisDate': null,
    };

    if (hairAnalyses.isNotEmpty) {
      final typeCount = <String, int>{};
      double totalConfidence = 0.0;

      for (final analysis in hairAnalyses) {
        typeCount[analysis.hairType] = (typeCount[analysis.hairType] ?? 0) + 1;
        totalConfidence += analysis.confidence;
      }

      String? mostCommonType;
      int maxCount = 0;
      typeCount.forEach((type, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonType = type;
        }
      });

      hairStats = {
        'totalAnalyses': hairAnalyses.length,
        'mostCommonType': mostCommonType,
        'averageConfidence': totalConfidence / hairAnalyses.length,
        'lastAnalysisDate': hairAnalyses.first.analyzedAt,
        'typeDistribution': typeCount,
      };
    }

    return {
      'face': faceStats,
      'hair': hairStats,
      'totalCombinedAnalyses': faceAnalyses.length + hairAnalyses.length,
    };
  }
}