// lib/data/repositories/personalized_recommendations_repository.dart - CORREGIDO
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/personalized_recommendations_service.dart';
import '../models/personalized_recommendations_model.dart';
import '../models/user_model.dart';
import '../models/preference_model.dart';
import 'dart:io';

class PersonalizedRecommendationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PersonalizedRecommendationsService _recommendationsService =
  PersonalizedRecommendationsService(); // CAMBIADO

  // Generar y guardar recomendaciones personalizadas (MÉTODO CORREGIDO)
  Future<PersonalizedRecommendationsModel> generateAndSaveRecommendations({
    required UserModel user,
    required PreferenceModel preferences,
    File? wellnessPhoto,
  }) async {
    try {
      // 1. Generar recomendaciones usando el servicio mejorado
      final recommendations = await _recommendationsService.generateImprovedRecommendations(
        user: user,
        preferences: preferences,
        wellnessPhoto: wellnessPhoto,
      );

      // 2. Guardar en Firestore
      final savedRecommendations = await _saveRecommendations(recommendations);

      // 3. Limpiar recomendaciones antiguas (mantener solo las últimas 5)
      await _cleanupOldRecommendations(user.uid);

      return savedRecommendations;
    } catch (e) {
      throw Exception('Error generando recomendaciones: $e');
    }
  }

  // Guardar recomendaciones en Firestore
  Future<PersonalizedRecommendationsModel> _saveRecommendations(
      PersonalizedRecommendationsModel recommendations) async {
    final docRef = await _firestore
        .collection('personalized_recommendations')
        .add(recommendations.toFirestore());

    return PersonalizedRecommendationsModel(
      id: docRef.id,
      userId: recommendations.userId,
      generatedAt: recommendations.generatedAt,
      wellnessPhotoUrl: recommendations.wellnessPhotoUrl,
      hairStyleRecommendations: recommendations.hairStyleRecommendations,
      clothingRecommendations: recommendations.clothingRecommendations,
      colorRecommendations: recommendations.colorRecommendations,
      skinCareRecommendations: recommendations.skinCareRecommendations,
      hairCareRecommendations: recommendations.hairCareRecommendations,
      bodyWellnessRecommendations: recommendations.bodyWellnessRecommendations,
      exerciseRecommendations: recommendations.exerciseRecommendations,
      nutritionRecommendations: recommendations.nutritionRecommendations,
      lifestyleRecommendations: recommendations.lifestyleRecommendations,
      wellnessAnalysis: recommendations.wellnessAnalysis,
      overallWellnessScore: recommendations.overallWellnessScore,
      styleCompatibilityScore: recommendations.styleCompatibilityScore,
      healthScore: recommendations.healthScore,
      userDataSnapshot: recommendations.userDataSnapshot,
      additionalData: recommendations.additionalData,
    );
  }

  // Obtener las recomendaciones más recientes del usuario
  Future<PersonalizedRecommendationsModel?> getLatestRecommendations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('personalized_recommendations')
          .where('userId', isEqualTo: userId)
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return PersonalizedRecommendationsModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo recomendaciones: $e');
    }
  }

  // Obtener historial de recomendaciones del usuario
  Future<List<PersonalizedRecommendationsModel>> getUserRecommendationsHistory(
      String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('personalized_recommendations')
          .where('userId', isEqualTo: userId)
          .orderBy('generatedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PersonalizedRecommendationsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo historial: $e');
    }
  }

  // Stream de recomendaciones del usuario
  Stream<PersonalizedRecommendationsModel?> getLatestRecommendationsStream(String userId) {
    return _firestore
        .collection('personalized_recommendations')
        .where('userId', isEqualTo: userId)
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return PersonalizedRecommendationsModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Verificar si el usuario necesita nuevas recomendaciones
  Future<bool> needsNewRecommendations(String userId) async {
    try {
      final latest = await getLatestRecommendations(userId);
      if (latest == null) return true;

      return latest.needsUpdate;
    } catch (e) {
      return true; // Si hay error, asumir que necesita actualización
    }
  }

  // Obtener recomendaciones por categoría
  Future<List<String>> getRecommendationsByCategory(
      String userId, String category) async {
    try {
      final latest = await getLatestRecommendations(userId);
      if (latest == null) return [];

      switch (category.toLowerCase()) {
        case 'hairstyle':
          return latest.hairStyleRecommendations;
        case 'clothing':
          return latest.clothingRecommendations;
        case 'colors':
          return latest.colorRecommendations;
        case 'skincare':
          return latest.skinCareRecommendations;
        case 'haircare':
          return latest.hairCareRecommendations;
        case 'bodywellness':
          return latest.bodyWellnessRecommendations;
        case 'exercise':
          return latest.exerciseRecommendations;
        case 'nutrition':
          return latest.nutritionRecommendations;
        case 'lifestyle':
          return latest.lifestyleRecommendations;
        default:
          return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Actualizar recomendaciones específicas
  Future<void> updateRecommendations(
      String recommendationId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('personalized_recommendations')
          .doc(recommendationId)
          .update(updates);
    } catch (e) {
      throw Exception('Error actualizando recomendaciones: $e');
    }
  }

  // Marcar recomendación como seguida
  Future<void> markRecommendationAsFollowed(
      String recommendationId, String category, int index) async {
    try {
      final doc = await _firestore
          .collection('personalized_recommendations')
          .doc(recommendationId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final followedRecommendations =
      Map<String, dynamic>.from(data['followedRecommendations'] ?? {});

      if (!followedRecommendations.containsKey(category)) {
        followedRecommendations[category] = <int>[];
      }

      final categoryFollowed = List<int>.from(followedRecommendations[category]);
      if (!categoryFollowed.contains(index)) {
        categoryFollowed.add(index);
        followedRecommendations[category] = categoryFollowed;
      }

      await _firestore
          .collection('personalized_recommendations')
          .doc(recommendationId)
          .update({
        'followedRecommendations': followedRecommendations,
        'lastFollowedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error marcando recomendación: $e');
    }
  }

  // Obtener estadísticas de seguimiento
  Future<Map<String, dynamic>> getFollowingStats(String userId) async {
    try {
      final recommendations = await getUserRecommendationsHistory(userId, limit: 5);

      if (recommendations.isEmpty) {
        return {
          'totalRecommendations': 0,
          'followedRecommendations': 0,
          'followingRate': 0.0,
          'categoriesStats': <String, dynamic>{},
        };
      }

      int totalRecommendations = 0;
      int followedRecommendations = 0;
      final categoriesStats = <String, Map<String, int>>{};

      for (final recommendation in recommendations) {
        final categories = [
          'hairStyle', 'clothing', 'colors', 'skinCare',
          'hairCare', 'bodyWellness', 'exercise', 'nutrition', 'lifestyle'
        ];

        for (final category in categories) {
          List<String> categoryRecommendations = [];

          switch (category) {
            case 'hairStyle':
              categoryRecommendations = recommendation.hairStyleRecommendations;
              break;
            case 'clothing':
              categoryRecommendations = recommendation.clothingRecommendations;
              break;
            case 'colors':
              categoryRecommendations = recommendation.colorRecommendations;
              break;
            case 'skinCare':
              categoryRecommendations = recommendation.skinCareRecommendations;
              break;
            case 'hairCare':
              categoryRecommendations = recommendation.hairCareRecommendations;
              break;
            case 'bodyWellness':
              categoryRecommendations = recommendation.bodyWellnessRecommendations;
              break;
            case 'exercise':
              categoryRecommendations = recommendation.exerciseRecommendations;
              break;
            case 'nutrition':
              categoryRecommendations = recommendation.nutritionRecommendations;
              break;
            case 'lifestyle':
              categoryRecommendations = recommendation.lifestyleRecommendations;
              break;
          }

          totalRecommendations += categoryRecommendations.length;

          // Contar recomendaciones seguidas
          final followed = recommendation.additionalData?['followedRecommendations']?[category] ?? [];
          followedRecommendations += (followed as List).length;

          categoriesStats[category] = {
            'total': categoryRecommendations.length,
            'followed': (followed as List).length,
          };
        }
      }

      final followingRate = totalRecommendations > 0
          ? followedRecommendations / totalRecommendations
          : 0.0;

      return {
        'totalRecommendations': totalRecommendations,
        'followedRecommendations': followedRecommendations,
        'followingRate': followingRate,
        'categoriesStats': categoriesStats,
      };
    } catch (e) {
      return {
        'totalRecommendations': 0,
        'followedRecommendations': 0,
        'followingRate': 0.0,
        'categoriesStats': <String, dynamic>{},
      };
    }
  }

  // MÉTODO CORREGIDO: Generar recomendaciones mejoradas usando IA
  Future<List<String>> generateEnhancedRecommendations({
    required UserModel user,
    required PreferenceModel preferences,
    required String category,
    Map<String, dynamic>? wellnessAnalysis,
  }) async {
    try {
      // Usar el nuevo servicio mejorado
      final recommendations = await _recommendationsService.generateImprovedRecommendations(
        user: user,
        preferences: preferences,
        wellnessPhoto: null, // Para recomendaciones específicas no necesitamos foto
      );

      // Extraer la categoría específica
      switch (category.toLowerCase()) {
        case 'hairstyle':
          return recommendations.hairStyleRecommendations;
        case 'clothing':
          return recommendations.clothingRecommendations;
        case 'colors':
          return recommendations.colorRecommendations;
        case 'skincare':
          return recommendations.skinCareRecommendations;
        case 'haircare':
          return recommendations.hairCareRecommendations;
        case 'bodywellness':
          return recommendations.bodyWellnessRecommendations;
        case 'exercise':
          return recommendations.exerciseRecommendations;
        case 'nutrition':
          return recommendations.nutritionRecommendations;
        case 'lifestyle':
          return recommendations.lifestyleRecommendations;
        default:
          return [];
      }
    } catch (e) {
      throw Exception('Error generando recomendaciones mejoradas: $e');
    }
  }

  // Eliminar recomendaciones específicas
  Future<void> deleteRecommendations(String recommendationId) async {
    try {
      await _firestore
          .collection('personalized_recommendations')
          .doc(recommendationId)
          .delete();
    } catch (e) {
      throw Exception('Error eliminando recomendaciones: $e');
    }
  }

  // Limpiar recomendaciones antiguas (mantener solo las últimas 5)
  Future<void> _cleanupOldRecommendations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('personalized_recommendations')
          .where('userId', isEqualTo: userId)
          .orderBy('generatedAt', descending: true)
          .get();

      final docs = snapshot.docs;
      if (docs.length > 5) {
        final batch = _firestore.batch();
        for (int i = 5; i < docs.length; i++) {
          batch.delete(docs[i].reference);
        }
        await batch.commit();
      }
    } catch (e) {
      // Error en limpieza no es crítico
      print('Error limpiando recomendaciones antiguas: $e');
    }
  }

  // Obtener análisis de tendencias personales
  Future<Map<String, dynamic>> getPersonalTrends(String userId) async {
    try {
      final recommendations = await getUserRecommendationsHistory(userId);

      if (recommendations.length < 2) {
        return {
          'hasEnoughData': false,
          'message': 'Necesitas al menos 2 análisis para ver tendencias',
        };
      }

      final trends = <String, dynamic>{};

      // Analizar tendencias en puntuaciones
      final scores = recommendations.map((r) => {
        'date': r.generatedAt,
        'overall': r.overallWellnessScore,
        'style': r.styleCompatibilityScore,
        'health': r.healthScore,
      }).toList();

      trends['scoresTrend'] = _calculateScoresTrend(scores);

      // Analizar cambios en recomendaciones
      trends['recommendationChanges'] = _analyzeRecommendationChanges(recommendations);

      // Analizar progreso de bienestar
      trends['wellnessProgress'] = _analyzeWellnessProgress(recommendations);

      return {
        'hasEnoughData': true,
        'trends': trends,
        'dataPoints': recommendations.length,
        'timeSpan': recommendations.first.generatedAt
            .difference(recommendations.last.generatedAt).inDays,
      };
    } catch (e) {
      return {
        'hasEnoughData': false,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _calculateScoresTrend(List<Map<String, dynamic>> scores) {
    if (scores.length < 2) return {};

    final latest = scores.first;
    final oldest = scores.last;

    return {
      'overall': {
        'change': latest['overall'] - oldest['overall'],
        'trend': _getTrendDirection(latest['overall'], oldest['overall']),
      },
      'style': {
        'change': latest['style'] - oldest['style'],
        'trend': _getTrendDirection(latest['style'], oldest['style']),
      },
      'health': {
        'change': latest['health'] - oldest['health'],
        'trend': _getTrendDirection(latest['health'], oldest['health']),
      },
    };
  }

  String _getTrendDirection(double current, double previous) {
    final difference = current - previous;
    if (difference > 0.05) return 'improving';
    if (difference < -0.05) return 'declining';
    return 'stable';
  }

  Map<String, dynamic> _analyzeRecommendationChanges(
      List<PersonalizedRecommendationsModel> recommendations) {
    if (recommendations.length < 2) return {};

    final latest = recommendations.first;
    final previous = recommendations[1];

    final changes = <String, bool>{};

    // Comparar categorías de recomendaciones
    changes['hairStyleChanged'] = !_listsEqual(
        latest.hairStyleRecommendations,
        previous.hairStyleRecommendations
    );
    changes['clothingChanged'] = !_listsEqual(
        latest.clothingRecommendations,
        previous.clothingRecommendations
    );
    changes['lifestyleChanged'] = !_listsEqual(
        latest.lifestyleRecommendations,
        previous.lifestyleRecommendations
    );

    final totalChanges = changes.values.where((changed) => changed).length;

    return {
      'changes': changes,
      'totalCategories': changes.length,
      'changedCategories': totalChanges,
      'changePercentage': totalChanges / changes.length,
    };
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> _analyzeWellnessProgress(
      List<PersonalizedRecommendationsModel> recommendations) {
    final wellnessData = <Map<String, dynamic>>[];

    for (final rec in recommendations) {
      if (rec.wellnessAnalysis != null) {
        wellnessData.add({
          'date': rec.generatedAt,
          'fatigueDetected': rec.wellnessAnalysis!['fatigue_detected'] ?? false,
          'skinCondition': rec.wellnessAnalysis!['skin_condition'] ?? 'unknown',
          'hydrationLevel': rec.wellnessAnalysis!['hydration_level'] ?? 'unknown',
        });
      }
    }

    if (wellnessData.length < 2) {
      return {'hasData': false};
    }

    // Analizar mejoras en el tiempo
    final latest = wellnessData.first;
    final oldest = wellnessData.last;

    return {
      'hasData': true,
      'fatigueImprovement': (oldest['fatigueDetected'] == true &&
          latest['fatigueDetected'] == false),
      'skinImprovement': _compareSkinCondition(
          oldest['skinCondition'],
          latest['skinCondition']
      ),
      'hydrationImprovement': _compareHydrationLevel(
          oldest['hydrationLevel'],
          latest['hydrationLevel']
      ),
      'dataPoints': wellnessData.length,
    };
  }

  bool _compareSkinCondition(String old, String current) {
    const conditions = ['poor', 'fair', 'good'];
    final oldIndex = conditions.indexOf(old);
    final currentIndex = conditions.indexOf(current);
    return currentIndex > oldIndex;
  }

  bool _compareHydrationLevel(String old, String current) {
    if (old == 'low' && current == 'normal') return true;
    return false;
  }

  // Buscar recomendaciones similares
  Future<List<PersonalizedRecommendationsModel>> findSimilarRecommendations({
    required String userId,
    required String category,
    int limit = 5,
  }) async {
    try {
      // Esta es una implementación básica
      // En una implementación más avanzada, usarías algoritmos de similitud
      final allRecommendations = await getUserRecommendationsHistory(userId);

      return allRecommendations.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Exportar recomendaciones a formato de reporte
  Future<Map<String, dynamic>> exportRecommendationsReport(String userId) async {
    try {
      final latest = await getLatestRecommendations(userId);
      final stats = await getFollowingStats(userId);
      final trends = await getPersonalTrends(userId);

      if (latest == null) {
        throw Exception('No hay recomendaciones para exportar');
      }

      return {
        'user': {
          'userId': userId,
          'generatedAt': latest.generatedAt.toIso8601String(),
        },
        'scores': latest.getScoresSummary(),
        'recommendations': {
          'hairStyle': latest.hairStyleRecommendations,
          'clothing': latest.clothingRecommendations,
          'colors': latest.colorRecommendations,
          'skinCare': latest.skinCareRecommendations,
          'hairCare': latest.hairCareRecommendations,
          'bodyWellness': latest.bodyWellnessRecommendations,
          'exercise': latest.exerciseRecommendations,
          'nutrition': latest.nutritionRecommendations,
          'lifestyle': latest.lifestyleRecommendations,
        },
        'priorities': latest.getPriorityRecommendations(),
        'alerts': latest.getHealthAlerts(),
        'improvementPlan': latest.getImprovementPlan(),
        'insights': latest.getPersonalizedInsights(),
        'stats': stats,
        'trends': trends,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error exportando reporte: $e');
    }
  }
}