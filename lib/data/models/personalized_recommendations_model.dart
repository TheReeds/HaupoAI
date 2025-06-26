// lib/data/models/personalized_recommendations_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalizedRecommendationsModel {
  final String id;
  final String userId;
  final DateTime generatedAt;
  final String? wellnessPhotoUrl;

  // Recomendaciones de estilo
  final List<String> hairStyleRecommendations;
  final List<String> clothingRecommendations;
  final List<String> colorRecommendations;

  // Recomendaciones de cuidado personal
  final List<String> skinCareRecommendations;
  final List<String> hairCareRecommendations;
  final List<String> bodyWellnessRecommendations;

  // Recomendaciones de hábitos saludables
  final List<String> exerciseRecommendations;
  final List<String> nutritionRecommendations;
  final List<String> lifestyleRecommendations;

  // Análisis de bienestar (detectado por IA)
  final Map<String, dynamic>? wellnessAnalysis;

  // Puntuaciones
  final double overallWellnessScore;
  final double styleCompatibilityScore;
  final double healthScore;

  // Metadatos
  final Map<String, dynamic> userDataSnapshot;
  final Map<String, dynamic>? additionalData;

  PersonalizedRecommendationsModel({
    required this.id,
    required this.userId,
    required this.generatedAt,
    this.wellnessPhotoUrl,
    required this.hairStyleRecommendations,
    required this.clothingRecommendations,
    required this.colorRecommendations,
    required this.skinCareRecommendations,
    required this.hairCareRecommendations,
    required this.bodyWellnessRecommendations,
    required this.exerciseRecommendations,
    required this.nutritionRecommendations,
    required this.lifestyleRecommendations,
    this.wellnessAnalysis,
    required this.overallWellnessScore,
    required this.styleCompatibilityScore,
    required this.healthScore,
    required this.userDataSnapshot,
    this.additionalData,
  });

  factory PersonalizedRecommendationsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonalizedRecommendationsModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      wellnessPhotoUrl: data['wellnessPhotoUrl'],
      hairStyleRecommendations: List<String>.from(data['hairStyleRecommendations'] ?? []),
      clothingRecommendations: List<String>.from(data['clothingRecommendations'] ?? []),
      colorRecommendations: List<String>.from(data['colorRecommendations'] ?? []),
      skinCareRecommendations: List<String>.from(data['skinCareRecommendations'] ?? []),
      hairCareRecommendations: List<String>.from(data['hairCareRecommendations'] ?? []),
      bodyWellnessRecommendations: List<String>.from(data['bodyWellnessRecommendations'] ?? []),
      exerciseRecommendations: List<String>.from(data['exerciseRecommendations'] ?? []),
      nutritionRecommendations: List<String>.from(data['nutritionRecommendations'] ?? []),
      lifestyleRecommendations: List<String>.from(data['lifestyleRecommendations'] ?? []),
      wellnessAnalysis: data['wellnessAnalysis'],
      overallWellnessScore: (data['overallWellnessScore'] ?? 0.0).toDouble(),
      styleCompatibilityScore: (data['styleCompatibilityScore'] ?? 0.0).toDouble(),
      healthScore: (data['healthScore'] ?? 0.0).toDouble(),
      userDataSnapshot: data['userDataSnapshot'] ?? {},
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'wellnessPhotoUrl': wellnessPhotoUrl,
      'hairStyleRecommendations': hairStyleRecommendations,
      'clothingRecommendations': clothingRecommendations,
      'colorRecommendations': colorRecommendations,
      'skinCareRecommendations': skinCareRecommendations,
      'hairCareRecommendations': hairCareRecommendations,
      'bodyWellnessRecommendations': bodyWellnessRecommendations,
      'exerciseRecommendations': exerciseRecommendations,
      'nutritionRecommendations': nutritionRecommendations,
      'lifestyleRecommendations': lifestyleRecommendations,
      'wellnessAnalysis': wellnessAnalysis,
      'overallWellnessScore': overallWellnessScore,
      'styleCompatibilityScore': styleCompatibilityScore,
      'healthScore': healthScore,
      'userDataSnapshot': userDataSnapshot,
      'additionalData': additionalData,
    };
  }

  // Obtener resumen de puntuaciones
  Map<String, dynamic> getScoresSummary() {
    return {
      'overall': {
        'score': overallWellnessScore,
        'label': _getScoreLabel(overallWellnessScore),
        'description': 'Puntuación general de bienestar y estilo',
      },
      'style': {
        'score': styleCompatibilityScore,
        'label': _getScoreLabel(styleCompatibilityScore),
        'description': 'Compatibilidad con tu estilo personal',
      },
      'health': {
        'score': healthScore,
        'label': _getScoreLabel(healthScore),
        'description': 'Indicadores de salud y bienestar',
      },
    };
  }

  String _getScoreLabel(double score) {
    if (score >= 0.9) return 'Excelente';
    if (score >= 0.8) return 'Muy bueno';
    if (score >= 0.7) return 'Bueno';
    if (score >= 0.6) return 'Regular';
    if (score >= 0.5) return 'Necesita mejoras';
    return 'Requiere atención';
  }

  // Obtener recomendaciones prioritarias
  List<Map<String, dynamic>> getPriorityRecommendations() {
    final priorities = <Map<String, dynamic>>[];

    // Prioridad alta: salud y bienestar
    if (healthScore < 0.7) {
      priorities.addAll([
        {
          'category': 'Salud',
          'priority': 'Alta',
          'icon': 'health_and_safety',
          'color': 0xFFE53E3E,
          'recommendations': [
            ...exerciseRecommendations.take(2),
            ...nutritionRecommendations.take(2),
          ],
        }
      ]);
    }

    // Prioridad media: cuidado personal
    if (overallWellnessScore < 0.8) {
      priorities.add({
        'category': 'Cuidado Personal',
        'priority': 'Media',
        'icon': 'spa',
        'color': 0xFFFF8A00,
        'recommendations': [
          ...skinCareRecommendations.take(2),
          ...hairCareRecommendations.take(2),
        ],
      });
    }

    // Prioridad baja: estilo
    priorities.add({
      'category': 'Estilo',
      'priority': 'Baja',
      'icon': 'style',
      'color': 0xFF3182CE,
      'recommendations': [
        ...hairStyleRecommendations.take(2),
        ...clothingRecommendations.take(2),
      ],
    });

    return priorities;
  }

  // Obtener alertas de salud
  List<Map<String, dynamic>> getHealthAlerts() {
    final alerts = <Map<String, dynamic>>[];

    if (wellnessAnalysis != null) {
      final analysis = wellnessAnalysis!;

      // Verificar signos de cansancio
      if (analysis['fatigue_detected'] == true) {
        alerts.add({
          'type': 'warning',
          'title': 'Signos de cansancio detectados',
          'message': 'Considera mejorar tus hábitos de sueño',
          'recommendations': [
            'Dormir 7-8 horas diarias',
            'Establecer rutina de sueño',
            'Evitar pantallas antes de dormir',
          ],
        });
      }

      // Verificar estado de la piel
      if (analysis['skin_condition'] == 'poor') {
        alerts.add({
          'type': 'info',
          'title': 'Oportunidad de mejora en cuidado facial',
          'message': 'Tu piel podría beneficiarse de una rutina mejorada',
          'recommendations': skinCareRecommendations.take(3).toList(),
        });
      }

      // Verificar hidratación
      if (analysis['hydration_level'] == 'low') {
        alerts.add({
          'type': 'warning',
          'title': 'Posible deshidratación',
          'message': 'Aumenta tu consumo de agua diario',
          'recommendations': [
            'Beber al menos 2 litros de agua al día',
            'Consumir frutas con alto contenido de agua',
            'Usar humectantes faciales',
          ],
        });
      }
    }

    return alerts;
  }

  // Obtener plan de mejora personalizado
  Map<String, dynamic> getImprovementPlan() {
    return {
      'short_term': {
        'title': 'Plan a corto plazo (1-2 semanas)',
        'goals': [
          if (healthScore < 0.7) ...lifestyleRecommendations.take(2),
          if (overallWellnessScore < 0.8) ...skinCareRecommendations.take(1),
        ],
      },
      'medium_term': {
        'title': 'Plan a mediano plazo (1-3 meses)',
        'goals': [
          ...exerciseRecommendations.take(2),
          ...hairCareRecommendations.take(2),
        ],
      },
      'long_term': {
        'title': 'Plan a largo plazo (3+ meses)',
        'goals': [
          ...nutritionRecommendations.take(2),
          ...clothingRecommendations.take(2),
        ],
      },
    };
  }

  // Verificar si necesita actualización
  bool get needsUpdate {
    final daysSinceGenerated = DateTime.now().difference(generatedAt).inDays;
    return daysSinceGenerated > 14; // Actualizar cada 2 semanas
  }

  // Obtener compatibilidad con tendencias actuales
  double getTrendCompatibility() {
    // Algoritmo simple basado en el estilo del usuario
    final styleScore = styleCompatibilityScore;
    final healthScore = this.healthScore;

    // Las tendencias favorecen a personas con buen estado de salud y estilo definido
    return (styleScore * 0.6 + healthScore * 0.4);
  }

  // Generar insights personalizados
  List<String> getPersonalizedInsights() {
    final insights = <String>[];

    if (overallWellnessScore >= 0.8) {
      insights.add('¡Excelente! Tu bienestar general está en muy buen estado.');
    } else if (overallWellnessScore >= 0.6) {
      insights.add('Tienes una buena base, pero hay oportunidades de mejora.');
    } else {
      insights.add('Es un buen momento para enfocarte en tu bienestar personal.');
    }

    if (styleCompatibilityScore >= 0.8) {
      insights.add('Tu estilo está muy bien definido y te favorece.');
    } else {
      insights.add('Explorar nuevos estilos podría realzar tu apariencia.');
    }

    if (healthScore < 0.7) {
      insights.add('Pequeños cambios en tus hábitos pueden generar grandes resultados.');
    }

    return insights;
  }
}