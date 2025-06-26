// lib/core/services/hairstyle_recommendation_service.dart
import '../../data/models/user_model.dart';
import '../../data/models/preference_model.dart';
import '../../data/models/face_analysis_model.dart';
import '../../data/models/hair_analysis_model.dart';
import '../../data/models/hairstyle_recommendation_model.dart';
import 'chatbot_service.dart';
import 'image_search_service.dart';
import '../errors/exceptions.dart';

class HairstyleRecommendationService {
  final ChatbotService _chatbotService;
  final ImageSearchService _imageSearchService;

  HairstyleRecommendationService({
    ChatbotService? chatbotService,
    ImageSearchService? imageSearchService,
  })  : _chatbotService = chatbotService ?? ChatbotService(),
        _imageSearchService = imageSearchService ?? ImageSearchService();

  // Generar recomendaciones completas con imágenes
  Future<HairstyleRecommendationSet> generateRecommendationsWithImages({
    required UserModel user,
    required FaceAnalysisModel faceAnalysis,
    required HairAnalysisModel hairAnalysis,
    PreferenceModel? preferences,
  }) async {
    try {
      // 1. Obtener recomendaciones estructuradas del chatbot
      final chatResponse = await _getChatbotRecommendations(
        user: user,
        faceAnalysis: faceAnalysis,
        hairAnalysis: hairAnalysis,
        preferences: preferences,
      );

      // 2. Extraer nombres de cortes de la respuesta
      final styleNames = _extractStyleNamesFromResponse(chatResponse);

      // 3. Buscar imágenes para cada estilo
      final imageResults = await _imageSearchService.searchMultipleHairstyles(styleNames);

      // 4. Crear set de recomendaciones combinadas
      final recommendationSet = HairstyleRecommendationSet.fromChatAndImages(
        chatResponse: chatResponse,
        imageResults: imageResults,
        faceShape: faceAnalysis.faceShape,
        hairType: hairAnalysis.hairType,
      );

      return recommendationSet;
    } catch (e) {
      throw AppException('Error generando recomendaciones: ${e.toString()}');
    }
  }

  // Obtener recomendaciones del chatbot con formato estructurado
  Future<String> _getChatbotRecommendations({
    required UserModel user,
    required FaceAnalysisModel faceAnalysis,
    required HairAnalysisModel hairAnalysis,
    PreferenceModel? preferences,
  }) async {
    // Query específico para obtener respuesta estructurada
    final structuredQuery = '''
Basándote en mi análisis:
- Forma de rostro: ${faceAnalysis.faceShape}
- Tipo de cabello: ${hairAnalysis.hairType}

Dame EXACTAMENTE 3 recomendaciones de cortes/peinados en este formato:

✂️ **[NOMBRE EXACTO DEL CORTE]**
- Por qué te queda: [razón específica]
- Mantenimiento: [Bajo/Medio/Alto]
- Productos: [productos específicos]
- Dificultad: [Fácil/Medio/Difícil]

💇 **[NOMBRE EXACTO DEL CORTE 2]**
- Por qué te queda: [razón específica]
- Mantenimiento: [Bajo/Medio/Alto]
- Productos: [productos específicos]
- Dificultad: [Fácil/Medio/Difícil]

🎯 **[NOMBRE EXACTO DEL CORTE 3]**
- Por qué te queda: [razón específica]
- Mantenimiento: [Bajo/Medio/Alto]
- Productos: [productos específicos]
- Dificultad: [Fácil/Medio/Difícil]

Usa nombres técnicos específicos como "Mid Fade", "Textured Crop", "Classic Pompadour", etc.
''';

    return await _chatbotService.sendHairstyleMessage(
      message: structuredQuery,
      user: user,
      preferences: preferences,
      faceAnalysis: faceAnalysis,
      hairAnalysis: hairAnalysis,
    );
  }

  // Extraer nombres de estilos de la respuesta del chatbot
  List<String> _extractStyleNamesFromResponse(String response) {
    final styleNames = <String>[];
    final lines = response.split('\n');

    for (final line in lines) {
      // Buscar líneas que contengan nombres de cortes
      if ((line.contains('✂️') || line.contains('💇') || line.contains('🎯')) &&
          line.contains('**')) {
        // Extraer el nombre entre los asteriscos
        final match = RegExp(r'\*\*([^*]+)\*\*').firstMatch(line);
        if (match != null) {
          final styleName = match.group(1)?.trim();
          if (styleName != null && styleName.isNotEmpty) {
            styleNames.add(styleName);
          }
        }
      }
    }

    // Si no encuentra nombres específicos, usar términos genéricos
    if (styleNames.isEmpty) {
      styleNames.addAll(['men fade haircut', 'modern men hairstyle', 'barbershop cut']);
    }

    return styleNames.take(3).toList(); // Máximo 3 estilos
  }

  // Generar recomendación rápida para un tipo específico
  Future<HairstyleRecommendation> generateQuickRecommendation({
    required UserModel user,
    required String styleType, // 'formal', 'casual', 'trendy', etc.
    FaceAnalysisModel? faceAnalysis,
    HairAnalysisModel? hairAnalysis,
    PreferenceModel? preferences,
  }) async {
    try {
      final query = '''
Recomiéndame 1 corte específico de estilo $styleType para:
- Rostro: ${faceAnalysis?.faceShape ?? 'No especificado'}
- Cabello: ${hairAnalysis?.hairType ?? 'No especificado'}

Formato:
✂️ **[NOMBRE EXACTO]**
- Por qué te queda: [razón]
- Mantenimiento: [nivel]
- Productos: [lista]
''';

      final response = await _chatbotService.sendHairstyleMessage(
        message: query,
        user: user,
        preferences: preferences,
        faceAnalysis: faceAnalysis,
        hairAnalysis: hairAnalysis,
      );

      // Buscar imagen para este estilo específico
      final styleName = _extractStyleNamesFromResponse(response).first;
      final images = await _imageSearchService.searchHairstyleImages(styleName, limit: 3);

      return HairstyleRecommendation.fromChatResponse(response, images);
    } catch (e) {
      throw AppException('Error generando recomendación rápida: ${e.toString()}');
    }
  }

  // Obtener tendencias actuales con imágenes
  Future<List<HairstyleRecommendation>> getCurrentTrends({
    required UserModel user,
    FaceAnalysisModel? faceAnalysis,
    HairAnalysisModel? hairAnalysis,
  }) async {
    try {
      const trendingStyles = [
        'Mid Fade',
        'Textured Crop',
        'Modern Pompadour',
        'Buzz Cut Fade',
        'Quiff Style'
      ];

      final recommendations = <HairstyleRecommendation>[];

      for (final style in trendingStyles.take(3)) {
        final images = await _imageSearchService.searchHairstyleImages(style, limit: 2);

        recommendations.add(HairstyleRecommendation(
          name: style,
          description: 'Tendencia actual 2024-2025',
          whyItWorks: 'Estilo moderno y versátil',
          maintenanceLevel: 'Medio',
          products: ['Pasta texturizante', 'Spray fijador'],
          images: images,
          isTrending: true,
          difficulty: 'Medio',
        ));

        // Pequeño delay para evitar rate limiting
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return recommendations;
    } catch (e) {
      throw AppException('Error obteniendo tendencias: ${e.toString()}');
    }
  }

  // Buscar estilos similares basados en una imagen
  Future<List<HairstyleRecommendation>> findSimilarStyles(String referenceStyleName) async {
    try {
      // Definir estilos relacionados
      final similarStylesMap = {
        'fade': ['Low Fade', 'Mid Fade', 'High Fade', 'Drop Fade'],
        'pompadour': ['Classic Pompadour', 'Modern Pompadour', 'Disconnected Pompadour'],
        'undercut': ['Classic Undercut', 'Textured Undercut', 'Long Undercut'],
        'buzz': ['Buzz Cut', 'Crew Cut', 'Induction Cut'],
        'quiff': ['Classic Quiff', 'Textured Quiff', 'Side Swept Quiff'],
      };

      String baseStyle = referenceStyleName.toLowerCase();
      List<String> similarStyles = [];

      // Encontrar estilos relacionados
      for (final entry in similarStylesMap.entries) {
        if (baseStyle.contains(entry.key)) {
          similarStyles = entry.value;
          break;
        }
      }

      // Si no encuentra coincidencias, usar estilos populares
      if (similarStyles.isEmpty) {
        similarStyles = ['Classic Fade', 'Textured Crop', 'Side Part'];
      }

      final recommendations = <HairstyleRecommendation>[];

      for (final style in similarStyles.take(3)) {
        final images = await _imageSearchService.searchHairstyleImages(style, limit: 2);

        recommendations.add(HairstyleRecommendation(
          name: style,
          description: 'Estilo similar recomendado',
          whyItWorks: 'Variación del estilo que buscas',
          maintenanceLevel: 'Medio',
          products: ['Producto de peinado', 'Spray fijador'],
          images: images,
          isTrending: false,
          difficulty: 'Medio',
        ));

        await Future.delayed(const Duration(milliseconds: 300));
      }

      return recommendations;
    } catch (e) {
      throw AppException('Error buscando estilos similares: ${e.toString()}');
    }
  }

  // Validar disponibilidad de servicios
  Future<bool> areServicesAvailable() async {
    try {
      final chatbotAvailable = await _chatbotService.isServiceAvailable();
      final imagesAvailable = await _imageSearchService.isServiceAvailable();

      return chatbotAvailable && imagesAvailable;
    } catch (e) {
      return false;
    }
  }
}