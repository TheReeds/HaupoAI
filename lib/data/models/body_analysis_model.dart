// lib/data/models/body_analysis_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BodyAnalysisModel {
  final String id;
  final String userId;
  final String bodyType; // ecto, meso, endo
  final String bodyShape; // invert, pear, rectangle, etc.
  final String gender; // man, woman
  final double bodyTypeConfidence;
  final double bodyShapeConfidence;
  final double genderConfidence;
  final String? imageUrl;
  final DateTime analyzedAt;
  final Map<String, dynamic>? additionalData;

  BodyAnalysisModel({
    required this.id,
    required this.userId,
    required this.bodyType,
    required this.bodyShape,
    required this.gender,
    required this.bodyTypeConfidence,
    required this.bodyShapeConfidence,
    required this.genderConfidence,
    this.imageUrl,
    required this.analyzedAt,
    this.additionalData,
  });

  factory BodyAnalysisModel.fromRoboflowResponse({
    required String userId,
    required Map<String, dynamic> response,
    String? imageUrl,
  }) {
    final predictions = response['predictions'] as Map<String, dynamic>;

    // Extraer los diferentes tipos de predicciones
    final ectoData = predictions['ecto'] as Map<String, dynamic>?;
    final mesoData = predictions['meso'] as Map<String, dynamic>?;
    final endoData = predictions['endo'] as Map<String, dynamic>?;
    final invertData = predictions['invert'] as Map<String, dynamic>?;
    final pearData = predictions['pear'] as Map<String, dynamic>?;
    final rectangleData = predictions['rectangle'] as Map<String, dynamic>?;
    final manData = predictions['man'] as Map<String, dynamic>?;
    final womanData = predictions['woman'] as Map<String, dynamic>?;

    // Determinar el tipo de cuerpo con mayor confianza
    String bodyType = 'unknown';
    double bodyTypeConfidence = 0.0;

    final bodyTypes = <String, double>{
      if (ectoData != null) 'ecto': ectoData['confidence']?.toDouble() ?? 0.0,
      if (mesoData != null) 'meso': mesoData['confidence']?.toDouble() ?? 0.0,
      if (endoData != null) 'endo': endoData['confidence']?.toDouble() ?? 0.0,
    };

    if (bodyTypes.isNotEmpty) {
      final maxEntry = bodyTypes.entries.reduce((a, b) => a.value > b.value ? a : b);
      bodyType = maxEntry.key;
      bodyTypeConfidence = maxEntry.value;
    }

    // Determinar la forma del cuerpo
    String bodyShape = 'unknown';
    double bodyShapeConfidence = 0.0;

    final bodyShapes = <String, double>{
      if (invertData != null) 'invert': invertData['confidence']?.toDouble() ?? 0.0,
      if (pearData != null) 'pear': pearData['confidence']?.toDouble() ?? 0.0,
      if (rectangleData != null) 'rectangle': rectangleData['confidence']?.toDouble() ?? 0.0,
    };

    if (bodyShapes.isNotEmpty) {
      final maxEntry = bodyShapes.entries.reduce((a, b) => a.value > b.value ? a : b);
      bodyShape = maxEntry.key;
      bodyShapeConfidence = maxEntry.value;
    }

    // Determinar el género
    String gender = 'unknown';
    double genderConfidence = 0.0;

    final genders = <String, double>{
      if (manData != null) 'man': manData['confidence']?.toDouble() ?? 0.0,
      if (womanData != null) 'woman': womanData['confidence']?.toDouble() ?? 0.0,
    };

    if (genders.isNotEmpty) {
      final maxEntry = genders.entries.reduce((a, b) => a.value > b.value ? a : b);
      gender = maxEntry.key;
      genderConfidence = maxEntry.value;
    }

    return BodyAnalysisModel(
      id: '',
      userId: userId,
      bodyType: bodyType,
      bodyShape: bodyShape,
      gender: gender,
      bodyTypeConfidence: bodyTypeConfidence,
      bodyShapeConfidence: bodyShapeConfidence,
      genderConfidence: genderConfidence,
      imageUrl: imageUrl,
      analyzedAt: DateTime.now(),
      additionalData: {
        'rawResponse': response,
        'allPredictions': predictions,
      },
    );
  }

  factory BodyAnalysisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BodyAnalysisModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      bodyType: data['bodyType'] ?? '',
      bodyShape: data['bodyShape'] ?? '',
      gender: data['gender'] ?? '',
      bodyTypeConfidence: (data['bodyTypeConfidence'] ?? 0.0).toDouble(),
      bodyShapeConfidence: (data['bodyShapeConfidence'] ?? 0.0).toDouble(),
      genderConfidence: (data['genderConfidence'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      analyzedAt: (data['analyzedAt'] as Timestamp).toDate(),
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bodyType': bodyType,
      'bodyShape': bodyShape,
      'gender': gender,
      'bodyTypeConfidence': bodyTypeConfidence,
      'bodyShapeConfidence': bodyShapeConfidence,
      'genderConfidence': genderConfidence,
      'imageUrl': imageUrl,
      'analyzedAt': Timestamp.fromDate(analyzedAt),
      'additionalData': additionalData,
    };
  }

  // Método para obtener recomendaciones de ropa según el análisis corporal
  List<String> getClothingRecommendations() {
    final recommendations = <String>[];

    // Recomendaciones por tipo de cuerpo
    switch (bodyType.toLowerCase()) {
      case 'ecto':
        recommendations.addAll([
          'Capas múltiples para añadir volumen',
          'Patrones horizontales y texturas gruesas',
          'Chaquetas estructuradas y blazers',
          'Pantalones de corte recto o bootcut',
        ]);
        break;
      case 'meso':
        recommendations.addAll([
          'Ropa que resalte tu silueta natural',
          'Cortes ajustados pero no apretados',
          'Cinturones para definir la cintura',
          'Colores sólidos y patrones simples',
        ]);
        break;
      case 'endo':
        recommendations.addAll([
          'Líneas verticales para alargar la silueta',
          'Colores oscuros y monocromáticos',
          'Cortes en A y empire waist',
          'Evitar patrones muy llamativos',
        ]);
        break;
    }

    // Recomendaciones por forma del cuerpo
    switch (bodyShape.toLowerCase()) {
      case 'invert':
        recommendations.addAll([
          'Pantalones de colores claros o patrones',
          'Faldas A-line y pantalones bootcut',
          'Tops más ajustados en la parte superior',
          'Evitar hombreras muy pronunciadas',
        ]);
        break;
      case 'pear':
        recommendations.addAll([
          'Tops con detalles llamativos',
          'Colores claros en la parte superior',
          'Pantalones oscuros y de líneas limpias',
          'Chaquetas que terminen en la cadera',
        ]);
        break;
      case 'rectangle':
        recommendations.addAll([
          'Crear curvas con cinturones',
          'Peplum tops y chaquetas ajustadas',
          'Capas para añadir dimensión',
          'Patrones y texturas interesantes',
        ]);
        break;
    }

    // Recomendaciones por género (si aplica)
    if (gender.toLowerCase() == 'woman') {
      recommendations.addAll([
        'Considera vestidos que favorezcan tu silueta',
        'Experimenta con diferentes tipos de faldas',
        'Los accesorios pueden cambiar completamente un look',
      ]);
    } else if (gender.toLowerCase() == 'man') {
      recommendations.addAll([
        'Un buen traje bien ajustado es esencial',
        'Invierte en camisas de calidad',
        'Los accesorios masculinos marcan la diferencia',
      ]);
    }

    // Recomendaciones generales
    recommendations.addAll([
      'La confianza es el mejor accesorio',
      'Adapta las tendencias a tu tipo de cuerpo',
      'La comodidad y el estilo pueden ir de la mano',
    ]);

    return recommendations;
  }

  // Obtener colores recomendados
  List<String> getColorRecommendations() {
    final colors = <String>[];

    switch (bodyType.toLowerCase()) {
      case 'ecto':
        colors.addAll([
          'Colores claros y brillantes',
          'Pasteles y tonos cálidos',
          'Patrones llamativos',
        ]);
        break;
      case 'meso':
        colors.addAll([
          'Colores vibrantes y sólidos',
          'Tonos que resalten tu tono de piel',
          'Combinaciones contrastantes',
        ]);
        break;
      case 'endo':
        colors.addAll([
          'Colores oscuros y monocromáticos',
          'Azul marino, negro, gris oscuro',
          'Un color brillante como acento',
        ]);
        break;
    }

    return colors;
  }

  // Obtener tipos de cortes recomendados
  List<String> getCutRecommendations() {
    final cuts = <String>[];

    switch (bodyShape.toLowerCase()) {
      case 'invert':
        cuts.addAll([
          'Corte A-line en faldas y vestidos',
          'Pantalones bootcut o flare',
          'Tops ajustados en torso',
        ]);
        break;
      case 'pear':
        cuts.addAll([
          'Tops con detalles en hombros',
          'Chaquetas que terminen en cadera',
          'Pantalones de corte recto',
        ]);
        break;
      case 'rectangle':
        cuts.addAll([
          'Cortes que creen curvas',
          'Peplum y cintura definida',
          'Capas asimétricas',
        ]);
        break;
    }

    return cuts;
  }

  // Descripción del análisis corporal
  String getBodyAnalysisDescription() {
    return 'Tipo: ${_getBodyTypeName(bodyType)} | '
        'Forma: ${_getBodyShapeName(bodyShape)} | '
        'Género: ${_getGenderName(gender)}';
  }

  String _getBodyTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'ecto':
        return 'Ectomorfo (delgado)';
      case 'meso':
        return 'Mesomorfo (atlético)';
      case 'endo':
        return 'Endomorfo (redondeado)';
      default:
        return 'Tipo único';
    }
  }

  String _getBodyShapeName(String shape) {
    switch (shape.toLowerCase()) {
      case 'invert':
        return 'Triángulo invertido';
      case 'pear':
        return 'Pera';
      case 'rectangle':
        return 'Rectángulo';
      default:
        return 'Forma única';
    }
  }

  String _getGenderName(String genderValue) {
    switch (genderValue.toLowerCase()) {
      case 'man':
        return 'Masculino';
      case 'woman':
        return 'Femenino';
      default:
        return 'No especificado';
    }
  }

  // Obtener color representativo del análisis
  int getBodyTypeColor() {
    switch (bodyType.toLowerCase()) {
      case 'ecto':
        return 0xFF2196F3; // Azul
      case 'meso':
        return 0xFF4CAF50; // Verde
      case 'endo':
        return 0xFFFF9800; // Naranja
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  // Obtener la confianza promedio del análisis
  double get averageConfidence {
    return (bodyTypeConfidence + bodyShapeConfidence + genderConfidence) / 3;
  }

  // Verificar si el análisis es confiable
  bool get isReliable {
    return bodyTypeConfidence >= 0.6 &&
        bodyShapeConfidence >= 0.6 &&
        genderConfidence >= 0.6;
  }
}