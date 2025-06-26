// lib/core/services/chatbot_service.dart (ACTUALIZADO)
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/user_model.dart';
import '../../data/models/preference_model.dart';
import '../../data/models/face_analysis_model.dart';
import '../../data/models/hair_analysis_model.dart';
import '../errors/exceptions.dart';

class ChatbotService {
  static const String _baseUrl = 'https://router.huggingface.co/hyperbolic/v1/chat/completions';
  static const String _apiKey = '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';
  static const String _model = 'meta-llama/Llama-3.3-70B-Instruct';

  // Generar contexto personalizado del usuario con análisis completo
  String _generateUserContext(
      UserModel user,
      PreferenceModel? preferences,
      {FaceAnalysisModel? faceAnalysis, HairAnalysisModel? hairAnalysis}
      ) {
    final buffer = StringBuffer();

    buffer.write('Usuario: ${user.displayName ?? "Amigo/a"}');

    if (preferences != null) {
      if (preferences.gender != null) {
        buffer.write('\nGénero: ${preferences.gender}');
      }
      if (preferences.skinTone != null) {
        buffer.write('\nTono de piel: ${preferences.skinTone}');
      }
      if (preferences.favoriteColors.isNotEmpty) {
        buffer.write('\nColores favoritos: ${preferences.favoriteColors.join(", ")}');
      }
      if (preferences.favoriteStyles.isNotEmpty) {
        buffer.write('\nEstilos favoritos: ${preferences.favoriteStyles.join(", ")}');
      }
    }

    // Información del análisis facial
    if (faceAnalysis != null) {
      buffer.write('\nForma de rostro: ${faceAnalysis.faceShape} (confianza: ${(faceAnalysis.confidence * 100).toStringAsFixed(1)}%)');
    } else if (user.currentFaceShape != null) {
      buffer.write('\nForma de rostro: ${user.currentFaceShape}');
    }

    // Información del análisis de cabello
    if (hairAnalysis != null) {
      buffer.write('\nTipo de cabello: ${hairAnalysis.hairType} (confianza: ${(hairAnalysis.confidence * 100).toStringAsFixed(1)}%)');
    } else if (user.currentHairType != null) {
      buffer.write('\nTipo de cabello: ${user.currentHairType}');
    }

    // Información corporal
    if (user.bodyType != null) {
      buffer.write('\nTipo de cuerpo: ${user.bodyType}');
    }

    return buffer.toString();
  }

  // Sistema de prompts personalizado (actualizado)
  String _getSystemPrompt(String userContext, {bool isHairstyleConsultation = false}) {
    if (isHairstyleConsultation) {
      return _getHairstyleSystemPrompt(userContext);
    }

    return '''Eres HuapoAI, un asistente experto en moda y estilo personal. Tu personalidad es amigable, entusiasta y siempre dispuesto a ayudar.

INFORMACIÓN DEL USUARIO:
$userContext

INSTRUCCIONES:
- Saluda al usuario por su nombre de manera cálida y personal
- Usa la información del usuario para dar recomendaciones específicas
- Sé creativo y considera las tendencias actuales de moda
- Pregunta por el contexto específico (trabajo, fiesta, cita, casual, etc.) si no está claro
- Da consejos sobre colores que complementen su tono de piel
- Sugiere estilos que favorezcan su forma de rostro y tipo de cuerpo
- Mantén un tono conversacional y amigable
- Puedes usar emojis para hacer la conversación más divertida
- Si no tienes suficiente información, haz preguntas específicas
- No hables de otros temas que no sean referidos a moda o estilo o vida saludable
- Si vas a dar consejos de ropa o look, se conciso y preciso dando opciones directas

ESPECIALIDADES:
- Combinaciones de colores
- Estilos de ropa por tipo de cuerpo
- Cortes de cabello por forma de rostro
- Outfits para diferentes ocasiones
- Tendencias de moda actuales
- Consejos de styling y accesorios''';
  }

  // Sistema de prompts especializado para peinados
  String _getHairstyleSystemPrompt(String userContext) {
    return '''Eres HuapoAI, un experto estilista y consultor de peinados con amplia experiencia en barbería moderna y estilismo profesional.

INFORMACIÓN DEL USUARIO:
$userContext

ERES EXPERTO EN:
🔹 **Fade Cuts**: Low fade, Mid fade, High fade, Skin fade, Drop fade, Taper fade
🔹 **Cortes Clásicos**: Buzz cut, Crew cut, Caesar cut, Ivy League
🔹 **Cortes Modernos**: Undercut, Pompadour, Quiff, Side part, Slick back
🔹 **Cortes Texturizados**: Messy top, Textured crop, Fringe, Spiky hair
🔹 **Cortes Largos**: Man bun, Top knot, Flow, Surfer hair

RECOMENDACIONES POR FORMA DE ROSTRO:
- **Oval**: Casi todos los estilos funcionan
- **Redondo**: Altura arriba, evitar volumen lateral
- **Cuadrado**: Suavizar con ondas, evitar geométricos
- **Corazón**: Equilibrar frente amplia
- **Diamante**: Volumen en frente y barbilla
- **Alargado**: Volumen lateral, evitar mucha altura

RECOMENDACIONES POR TIPO DE CABELLO:
- **Liso**: Fades, pompadours, slick backs
- **Ondulado**: Texturas naturales, quiffs, messy styles
- **Rizado**: Define rizos, considera encogimiento
- **Crespo**: Respeta textura, fades altos, afros

INSTRUCCIONES DE RESPUESTA:
- Sé directo con nombres específicos de cortes
- Explica qué significa cada término técnico brevemente
- Da 2-3 opciones concretas máximo
- Incluye consejos de mantenimiento
- Menciona productos si es relevante
- Usa emojis para visualizar
- Mantén tono amigable pero profesional

FORMATO DE RESPUESTA IDEAL:
"✂️ **[Nombre del corte]**
- Por qué te queda: [razón específica]
- Mantenimiento: [frecuencia]
- Productos: [si aplica]"

Solo habla de peinados, cortes, cuidado capilar y barbería.''';
  }

  // Consulta específica de peinados (NUEVA FUNCIÓN)
  Future<String> sendHairstyleMessage({
    required String message,
    required UserModel user,
    PreferenceModel? preferences,
    FaceAnalysisModel? faceAnalysis,
    HairAnalysisModel? hairAnalysis,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final userContext = _generateUserContext(
      user,
      preferences,
      faceAnalysis: faceAnalysis,
      hairAnalysis: hairAnalysis,
    );
    final systemPrompt = _getSystemPrompt(userContext, isHairstyleConsultation: true);

    return await _sendMessage(
      systemPrompt,
      message,
      conversationHistory ?? [],
    );
  }

  // Iniciar conversación con saludo personalizado
  Future<String> startConversation(UserModel user, PreferenceModel? preferences) async {
    final userContext = _generateUserContext(user, preferences);
    final systemPrompt = _getSystemPrompt(userContext);

    final welcomeMessage = '''¡Hola! Soy tu asistente personal de moda. ¿En qué te puedo ayudar hoy? 
Puedo darte consejos sobre:
- Outfits para ocasiones específicas
- Combinaciones de colores perfectas para ti
- Estilos que favorezcan tu figura
- Tendencias que se adapten a tu personalidad
¡Cuéntame qué tienes en mente! ✨''';

    return await _sendMessage(systemPrompt, welcomeMessage, []);
  }

  // Enviar mensaje al chatbot (función original actualizada)
  Future<String> sendMessage(
      String message,
      UserModel user,
      PreferenceModel? preferences,
      List<Map<String, String>> conversationHistory,
      ) async {
    final userContext = _generateUserContext(user, preferences);
    final systemPrompt = _getSystemPrompt(userContext);

    return await _sendMessage(systemPrompt, message, conversationHistory);
  }

  // Generar recomendaciones automáticas de peinados (NUEVA FUNCIÓN)
  Future<String> generateHairstyleRecommendations({
    required UserModel user,
    required FaceAnalysisModel faceAnalysis,
    required HairAnalysisModel hairAnalysis,
    PreferenceModel? preferences,
  }) async {
    final userContext = _generateUserContext(
      user,
      preferences,
      faceAnalysis: faceAnalysis,
      hairAnalysis: hairAnalysis,
    );
    final systemPrompt = _getSystemPrompt(userContext, isHairstyleConsultation: true);

    final autoQuery = '''
Basándote en mi análisis completo, dame 3 recomendaciones específicas de cortes/peinados perfectos para mí.

Para cada recomendación incluye:
1. Nombre técnico del corte
2. Por qué funciona para mi combinación rostro-cabello
3. Nivel de mantenimiento (bajo/medio/alto)
4. Si está de moda actualmente

Sé directo y específico. Explica los términos técnicos brevemente.
''';

    return await _sendMessage(systemPrompt, autoQuery, []);
  }

  // Método privado para comunicarse con OpenRouter
  Future<String> _sendMessage(
      String systemPrompt,
      String userMessage,
      List<Map<String, String>> conversationHistory,
      ) async {
    try {
      final messages = <Map<String, String>>[];

      // Agregar prompt del sistema
      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });

      // Agregar historial de conversación
      messages.addAll(conversationHistory);

      // Agregar mensaje actual del usuario
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'X-Title': 'HuapoAI Fashion Assistant',
        },
        body: json.encode({
          'model': _model,
          'messages': messages,
          'max_tokens': 600, // Aumentado para respuestas más detalladas
          'temperature': 0.7,
          'top_p': 1,
          'frequency_penalty': 0,
          'presence_penalty': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        throw AppException('Error del servidor: ${response.statusCode}');
      }

    } catch (e) {
      print('Error en chatbot: $e');
      throw AppException('Error de conexión: ${e.toString()}');
    }
  }

  // Generar recomendación específica para una ocasión
  Future<String> getOutfitRecommendation(
      UserModel user,
      PreferenceModel? preferences,
      String occasion,
      String? weather,
      String? budget,
      ) async {
    final userContext = _generateUserContext(user, preferences);
    final systemPrompt = _getSystemPrompt(userContext);

    String message = 'Necesito un outfit para: $occasion';
    if (weather != null) message += '\nClima: $weather';
    if (budget != null) message += '\nPresupuesto: $budget';
    message += '\n¿Qué me recomiendas?';

    return await _sendMessage(systemPrompt, message, []);
  }

  // Generar paleta de colores personalizada
  Future<Map<String, dynamic>> generateColorPalette(
      UserModel user,
      PreferenceModel? preferences,
      ) async {
    final userContext = _generateUserContext(user, preferences);
    final systemPrompt = _getSystemPrompt(userContext);

    final message = '''Basándote en mi información personal, genera una paleta de colores personalizada que incluya:
1. 5 colores principales que me favorezcan
2. 3 colores que debo evitar
3. Combinaciones perfectas para outfits
4. Explicación de por qué estos colores me quedan bien

Responde en formato estructurado para que sea fácil de entender.''';

    final response = await _sendMessage(systemPrompt, message, []);

    return {
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
      'userContext': userContext,
    };
  }

  // Obtener consultas rápidas para peinados (NUEVA FUNCIÓN)
  List<String> getHairstyleQuickQueries({
    FaceAnalysisModel? faceAnalysis,
    HairAnalysisModel? hairAnalysis
  }) {
    if (faceAnalysis != null && hairAnalysis != null) {
      return [
        'Cortes modernos para mí',
        'Fade cuts recomendados',
        'Peinados formales',
        'Estilos casuales',
        'Tendencias 2025',
        'Mantenimiento de mi corte',
        'Productos para mi cabello',
      ];
    }

    return [
      'Cortes de moda actuales',
      'Qué tipos de fade existen',
      'Diferencia entre pompadour y quiff',
      'Cortes para cabello rizado',
      'Estilos de barbería moderna',
    ];
  }

  // Validar si el servicio está disponible
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}