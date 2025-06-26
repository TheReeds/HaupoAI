// lib/data/models/hairstyle_recommendation_model.dart
class HairstyleRecommendation {
  final String name;
  final String description;
  final String whyItWorks;
  final String maintenanceLevel;
  final List<String> products;
  final List<Map<String, dynamic>> images;
  final bool isTrending;
  final String difficulty;

  HairstyleRecommendation({
    required this.name,
    required this.description,
    required this.whyItWorks,
    required this.maintenanceLevel,
    required this.products,
    required this.images,
    this.isTrending = false,
    required this.difficulty,
  });

  // Crear desde respuesta del chatbot
  factory HairstyleRecommendation.fromChatResponse(
      String chatResponse,
      List<Map<String, dynamic>> images,
      ) {
    // Parsear la respuesta del chatbot para extraer información estructurada
    final lines = chatResponse.split('\n');
    String name = 'Corte Recomendado';
    String description = '';
    String whyItWorks = '';
    String maintenanceLevel = 'Medio';
    List<String> products = [];
    String difficulty = 'Medio';
    bool isTrending = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('**') && line.endsWith('**')) {
        // Extraer nombre del corte
        name = line.replaceAll('**', '').replaceAll('✂️', '').trim();
      } else if (line.contains('Por qué te queda:') || line.contains('Por qué funciona:')) {
        whyItWorks = line.split(':').last.trim();
      } else if (line.contains('Mantenimiento:')) {
        maintenanceLevel = line.split(':').last.trim();
      } else if (line.contains('Productos:')) {
        final productText = line.split(':').last.trim();
        products = productText.split(',').map((p) => p.trim()).toList();
      } else if (line.contains('Dificultad:')) {
        difficulty = line.split(':').last.trim();
      } else if (line.contains('tendencia') || line.contains('moda') || line.contains('2024') || line.contains('2025')) {
        isTrending = true;
      } else if (line.isNotEmpty && !line.startsWith('-') && !line.startsWith('•')) {
        description += line + ' ';
      }
    }

    return HairstyleRecommendation(
      name: name,
      description: description.trim(),
      whyItWorks: whyItWorks,
      maintenanceLevel: maintenanceLevel,
      products: products,
      images: images,
      isTrending: isTrending,
      difficulty: difficulty,
    );
  }

  // Método para obtener el nivel de mantenimiento como enum
  MaintenanceLevel get maintenanceLevelEnum {
    switch (maintenanceLevel.toLowerCase()) {
      case 'bajo':
      case 'low':
        return MaintenanceLevel.low;
      case 'alto':
      case 'high':
        return MaintenanceLevel.high;
      default:
        return MaintenanceLevel.medium;
    }
  }

  // Método para obtener color según el nivel de mantenimiento
  int get maintenanceColor {
    switch (maintenanceLevelEnum) {
      case MaintenanceLevel.low:
        return 0xFF4CAF50; // Verde
      case MaintenanceLevel.medium:
        return 0xFFFF9800; // Naranja
      case MaintenanceLevel.high:
        return 0xFFF44336; // Rojo
    }
  }

  // Método para obtener la imagen principal
  String? get primaryImageUrl {
    return images.isNotEmpty ? images.first['url'] : null;
  }

  // Método para obtener imagen de preview
  String? get previewImageUrl {
    return images.isNotEmpty ? images.first['preview'] : null;
  }

  // Convertir a Map para serialización
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'whyItWorks': whyItWorks,
      'maintenanceLevel': maintenanceLevel,
      'products': products,
      'images': images,
      'isTrending': isTrending,
      'difficulty': difficulty,
    };
  }

  // Crear desde Map
  factory HairstyleRecommendation.fromMap(Map<String, dynamic> map) {
    return HairstyleRecommendation(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      whyItWorks: map['whyItWorks'] ?? '',
      maintenanceLevel: map['maintenanceLevel'] ?? 'Medio',
      products: List<String>.from(map['products'] ?? []),
      images: List<Map<String, dynamic>>.from(map['images'] ?? []),
      isTrending: map['isTrending'] ?? false,
      difficulty: map['difficulty'] ?? 'Medio',
    );
  }
}

enum MaintenanceLevel { low, medium, high }

// Modelo para múltiples recomendaciones
class HairstyleRecommendationSet {
  final List<HairstyleRecommendation> recommendations;
  final String faceShape;
  final String hairType;
  final DateTime generatedAt;

  HairstyleRecommendationSet({
    required this.recommendations,
    required this.faceShape,
    required this.hairType,
    required this.generatedAt,
  });

  // Crear desde respuesta del chatbot y resultados de búsqueda de imágenes
  factory HairstyleRecommendationSet.fromChatAndImages({
    required String chatResponse,
    required Map<String, List<Map<String, dynamic>>> imageResults,
    required String faceShape,
    required String hairType,
  }) {
    final recommendations = <HairstyleRecommendation>[];

    // Dividir la respuesta en secciones de recomendaciones
    final sections = _parseRecommendationSections(chatResponse);

    for (int i = 0; i < sections.length && i < 3; i++) {
      final section = sections[i];
      final styleName = _extractStyleName(section);
      final images = imageResults[styleName] ?? [];

      recommendations.add(
          HairstyleRecommendation.fromChatResponse(section, images)
      );
    }

    return HairstyleRecommendationSet(
      recommendations: recommendations,
      faceShape: faceShape,
      hairType: hairType,
      generatedAt: DateTime.now(),
    );
  }

  // Parsear secciones de recomendaciones del texto del chatbot
  static List<String> _parseRecommendationSections(String chatResponse) {
    final sections = <String>[];
    final lines = chatResponse.split('\n');
    String currentSection = '';

    for (final line in lines) {
      if (line.trim().startsWith('✂️') || line.trim().startsWith('💇')) {
        if (currentSection.isNotEmpty) {
          sections.add(currentSection.trim());
        }
        currentSection = line + '\n';
      } else {
        currentSection += line + '\n';
      }
    }

    if (currentSection.isNotEmpty) {
      sections.add(currentSection.trim());
    }

    return sections;
  }

  // Extraer nombre del estilo para búsqueda de imágenes
  static String _extractStyleName(String section) {
    final lines = section.split('\n');

    for (final line in lines) {
      if (line.contains('**') && (line.contains('✂️') || line.contains('💇'))) {
        return line
            .replaceAll('✂️', '')
            .replaceAll('💇', '')
            .replaceAll('**', '')
            .trim();
      }
    }

    return 'men haircut';
  }

  // Obtener recomendación más popular (con más mantenimiento bajo)
  HairstyleRecommendation? get mostPopular {
    if (recommendations.isEmpty) return null;

    return recommendations.firstWhere(
          (rec) => rec.maintenanceLevelEnum == MaintenanceLevel.low,
      orElse: () => recommendations.first,
    );
  }

  // Obtener recomendación más trending
  HairstyleRecommendation? get mostTrending {
    if (recommendations.isEmpty) return null;

    return recommendations.firstWhere(
          (rec) => rec.isTrending,
      orElse: () => recommendations.first,
    );
  }

  // Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'faceShape': faceShape,
      'hairType': hairType,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}