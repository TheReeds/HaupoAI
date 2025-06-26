// lib/data/repositories/body_analysis_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/body_analysis_model.dart';
import '../models/user_model.dart';
import '../../core/services/roboflow_service.dart';
import 'dart:io';

class BodyAnalysisRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoboflowService _roboflowService = RoboflowService();

  // Realizar análisis corporal completo desde archivo
  Future<BodyAnalysisModel> analyzeBody({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // 1. Analizar con Roboflow
      final analysis = await _roboflowService.analyzeBodyType(
        userId: userId,
        imageFile: imageFile,
      );

      // 2. Guardar análisis en Firestore
      final savedAnalysis = await _saveBodyAnalysis(analysis);

      // 3. Limpiar imágenes temporales (opcional)
      _roboflowService.cleanupTempImages(userId);

      return savedAnalysis;
    } catch (e) {
      throw Exception('Error en análisis corporal: $e');
    }
  }

  // Analizar desde foto de perfil existente
  Future<BodyAnalysisModel> analyzeBodyFromProfilePhoto({
    required String userId,
    required String photoURL,
  }) async {
    try {
      // 1. Analizar con Roboflow
      final analysis = await _roboflowService.analyzeBodyTypeFromUrl(
        userId: userId,
        imageUrl: photoURL,
      );

      // 2. Guardar análisis en Firestore
      final savedAnalysis = await _saveBodyAnalysis(analysis);

      return savedAnalysis;
    } catch (e) {
      throw Exception('Error en análisis corporal: $e');
    }
  }

  // Guardar análisis corporal en Firestore
  Future<BodyAnalysisModel> _saveBodyAnalysis(BodyAnalysisModel analysis) async {
    final docRef = await _firestore
        .collection('body_analyses')
        .add(analysis.toFirestore());

    return BodyAnalysisModel(
      id: docRef.id,
      userId: analysis.userId,
      bodyType: analysis.bodyType,
      bodyShape: analysis.bodyShape,
      gender: analysis.gender,
      bodyTypeConfidence: analysis.bodyTypeConfidence,
      bodyShapeConfidence: analysis.bodyShapeConfidence,
      genderConfidence: analysis.genderConfidence,
      imageUrl: analysis.imageUrl,
      analyzedAt: analysis.analyzedAt,
      additionalData: analysis.additionalData,
    );
  }

  // Guardar información del análisis en el perfil del usuario
  Future<void> saveAnalysisToUserProfile({
    required String userId,
    required BodyAnalysisModel bodyAnalysis,
  }) async {
    final updateData = {
      'bodyType': bodyAnalysis.bodyType,
      'lastBodyAnalysis': Timestamp.fromDate(bodyAnalysis.analyzedAt),
      // Agregamos más información del análisis corporal
      'bodyShape': bodyAnalysis.bodyShape,
      'bodyTypeConfidence': bodyAnalysis.bodyTypeConfidence,
      'bodyShapeConfidence': bodyAnalysis.bodyShapeConfidence,
      'detectedGender': bodyAnalysis.gender,
      'genderConfidence': bodyAnalysis.genderConfidence,
    };

    await _firestore.collection('users').doc(userId).update(updateData);
  }

  // Obtener historial de análisis corporales de un usuario
  Future<List<BodyAnalysisModel>> getUserBodyAnalyses(String userId) async {
    final snapshot = await _firestore
        .collection('body_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BodyAnalysisModel.fromFirestore(doc))
        .toList();
  }

  // Obtener último análisis corporal de un usuario
  Future<BodyAnalysisModel?> getLatestBodyAnalysis(String userId) async {
    final snapshot = await _firestore
        .collection('body_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return BodyAnalysisModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Stream de análisis corporales de usuario
  Stream<List<BodyAnalysisModel>> getUserBodyAnalysesStream(String userId) {
    return _firestore
        .collection('body_analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BodyAnalysisModel.fromFirestore(doc))
        .toList());
  }

  // Eliminar análisis específico
  Future<void> deleteBodyAnalysis(String analysisId) async {
    await _firestore.collection('body_analyses').doc(analysisId).delete();
  }

  // Eliminar todos los análisis corporales de un usuario
  Future<void> deleteAllUserBodyAnalyses(String userId) async {
    final batch = _firestore.batch();

    final snapshot = await _firestore
        .collection('body_analyses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Obtener estadísticas de análisis corporales
  Future<Map<String, dynamic>> getBodyAnalysisStats(String userId) async {
    final analyses = await getUserBodyAnalyses(userId);

    if (analyses.isEmpty) {
      return {
        'totalAnalyses': 0,
        'mostCommonBodyType': null,
        'mostCommonBodyShape': null,
        'averageConfidence': 0.0,
        'lastAnalysisDate': null,
      };
    }

    // Contar tipos de cuerpo
    final bodyTypeCount = <String, int>{};
    final bodyShapeCount = <String, int>{};
    double totalConfidence = 0.0;

    for (final analysis in analyses) {
      bodyTypeCount[analysis.bodyType] = (bodyTypeCount[analysis.bodyType] ?? 0) + 1;
      bodyShapeCount[analysis.bodyShape] = (bodyShapeCount[analysis.bodyShape] ?? 0) + 1;
      totalConfidence += analysis.averageConfidence;
    }

    // Encontrar los más comunes
    String? mostCommonBodyType;
    int maxBodyTypeCount = 0;
    bodyTypeCount.forEach((type, count) {
      if (count > maxBodyTypeCount) {
        maxBodyTypeCount = count;
        mostCommonBodyType = type;
      }
    });

    String? mostCommonBodyShape;
    int maxBodyShapeCount = 0;
    bodyShapeCount.forEach((shape, count) {
      if (count > maxBodyShapeCount) {
        maxBodyShapeCount = count;
        mostCommonBodyShape = shape;
      }
    });

    return {
      'totalAnalyses': analyses.length,
      'mostCommonBodyType': mostCommonBodyType,
      'mostCommonBodyShape': mostCommonBodyShape,
      'averageConfidence': totalConfidence / analyses.length,
      'lastAnalysisDate': analyses.first.analyzedAt,
      'bodyTypeDistribution': bodyTypeCount,
      'bodyShapeDistribution': bodyShapeCount,
    };
  }

  // Obtener recomendaciones personalizadas basadas en el último análisis
  Future<Map<String, List<String>>> getPersonalizedRecommendations(String userId) async {
    final latestAnalysis = await getLatestBodyAnalysis(userId);

    if (latestAnalysis == null) {
      return {
        'clothing': ['Realiza un análisis corporal para obtener recomendaciones personalizadas'],
        'colors': [],
        'cuts': [],
      };
    }

    return {
      'clothing': latestAnalysis.getClothingRecommendations(),
      'colors': latestAnalysis.getColorRecommendations(),
      'cuts': latestAnalysis.getCutRecommendations(),
    };
  }

  // Comparar análisis corporales (evolución en el tiempo)
  Future<Map<String, dynamic>> compareBodyAnalyses(String userId, {int limit = 5}) async {
    final analyses = await getUserBodyAnalyses(userId);

    if (analyses.length < 2) {
      return {
        'hasComparison': false,
        'message': 'Necesitas al menos 2 análisis para comparar',
      };
    }

    final limitedAnalyses = analyses.take(limit).toList();

    // Analizar cambios en tipos de cuerpo
    final bodyTypeChanges = <String>[];
    final bodyShapeChanges = <String>[];

    for (int i = 0; i < limitedAnalyses.length - 1; i++) {
      final current = limitedAnalyses[i];
      final previous = limitedAnalyses[i + 1];

      if (current.bodyType != previous.bodyType) {
        bodyTypeChanges.add('${previous.bodyType} → ${current.bodyType}');
      }

      if (current.bodyShape != previous.bodyShape) {
        bodyShapeChanges.add('${previous.bodyShape} → ${current.bodyShape}');
      }
    }

    // Calcular tendencias de confianza
    final confidenceValues = limitedAnalyses.map((a) => a.averageConfidence).toList();
    final avgConfidence = confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;

    return {
      'hasComparison': true,
      'totalAnalyses': limitedAnalyses.length,
      'bodyTypeChanges': bodyTypeChanges,
      'bodyShapeChanges': bodyShapeChanges,
      'averageConfidence': avgConfidence,
      'confidenceTrend': _calculateTrend(confidenceValues),
      'mostRecentAnalysis': limitedAnalyses.first,
      'oldestAnalysis': limitedAnalyses.last,
      'timeSpan': limitedAnalyses.first.analyzedAt.difference(limitedAnalyses.last.analyzedAt).inDays,
    };
  }

  // Calcular tendencia (si mejora o empeora la confianza)
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'stable';

    final first = values.last; // El más antiguo
    final last = values.first; // El más reciente

    final difference = last - first;

    if (difference > 0.05) return 'improving';
    if (difference < -0.05) return 'declining';
    return 'stable';
  }

  // Obtener insights del análisis corporal
  Future<List<String>> getBodyAnalysisInsights(String userId) async {
    final stats = await getBodyAnalysisStats(userId);
    final insights = <String>[];

    if (stats['totalAnalyses'] == 0) {
      insights.add('¡Realiza tu primer análisis corporal para comenzar!');
      return insights;
    }

    final totalAnalyses = stats['totalAnalyses'] as int;
    final avgConfidence = stats['averageConfidence'] as double;
    final mostCommonType = stats['mostCommonBodyType'] as String?;

    insights.add('Has realizado $totalAnalyses análisis corporales');

    if (avgConfidence > 0.8) {
      insights.add('Tus análisis tienen muy alta confianza (${(avgConfidence * 100).toStringAsFixed(1)}%)');
    } else if (avgConfidence > 0.6) {
      insights.add('Tus análisis tienen buena confianza (${(avgConfidence * 100).toStringAsFixed(1)}%)');
    } else {
      insights.add('Considera tomar fotos con mejor calidad para mayor precisión');
    }

    if (mostCommonType != null) {
      insights.add('Tu tipo de cuerpo más común es: $mostCommonType');
    }

    if (totalAnalyses > 1) {
      insights.add('¡Genial! Tienes un historial para comparar tu evolución');
    }

    return insights;
  }
}