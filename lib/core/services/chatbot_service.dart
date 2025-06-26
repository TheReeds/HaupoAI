// lib/core/services/chatbot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/user_model.dart';
import '../../data/models/preference_model.dart';
import '../errors/exceptions.dart';

class ChatbotService {
  static const String _baseUrl = 'https://router.huggingface.co/hyperbolic/v1/chat/completions';
  static const String _apiKey = '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';

  // Modelo gratuito/económico recomendado
  static const String _model = 'meta-llama/Llama-3.3-70B-Instruct';

  // Generar contexto personalizado del usuario
  String _generateUserContext(UserModel user, PreferenceModel? preferences) {
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

    if (user.currentFaceShape != null) {
      buffer.write('\nForma de rostro: ${user.currentFaceShape}');
    }

    if (user.bodyType != null) {
      buffer.write('\nTipo de cuerpo: ${user.bodyType}');
    }

    return buffer.toString();
  }

  // Sistema de prompts personalizado
  String _getSystemPrompt(String userContext) {
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

  // Enviar mensaje al chatbot
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
          'X-Title': 'HuapoAI Fashion Assistant', // opcional pero válido
        },
        body: json.encode({
          'model': _model,
          'messages': messages,
          'max_tokens': 500,
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

    // Procesar la respuesta para extraer información estructurada
    return {
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
      'userContext': userContext,
    };
  }

  // Analizar foto de outfit (función futura)
  Future<String> analyzeOutfitPhoto(
      UserModel user,
      PreferenceModel? preferences,
      String photoDescription,
      ) async {
    final userContext = _generateUserContext(user, preferences);
    final systemPrompt = _getSystemPrompt(userContext);

    final message = '''Analiza este outfit que llevo puesto: $photoDescription
    
Dame tu opinión honesta sobre:
- Si los colores me favorecen
- Si el estilo se adapta a mi tipo de cuerpo
- Qué mejorarías
- Puntuación del 1 al 10
- Sugerencias específicas''';

    return await _sendMessage(systemPrompt, message, []);
  }

  // Obtener tendencias personalizadas
  Future<String> getPersonalizedTrends(
      UserModel user,
      PreferenceModel? preferences,
      String season,
      ) async {
    final userContext = _generateUserContext(user, preferences);
    final systemPrompt = _getSystemPrompt(userContext);

    final message = '''¿Qué tendencias de moda para $season se adaptarían mejor a mi estilo y características?
    
Considera:
- Mi tipo de cuerpo y forma de rostro
- Mis colores y estilos favoritos
- Tendencias actuales de $season
- Cómo adaptar las tendencias a mi personalidad''';

    return await _sendMessage(systemPrompt, message, []);
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