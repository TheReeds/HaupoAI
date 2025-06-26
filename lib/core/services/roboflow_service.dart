// lib/core/services/roboflow_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../errors/exceptions.dart';
import '../../data/models/face_analysis_model.dart';
import '../../data/models/hair_analysis_model.dart';
import '../../data/models/body_analysis_model.dart';

class RoboflowService {
  static const String _baseUrl = 'https://serverless.roboflow.com';
  static const String _apiKey = 'kzEso6BdqfaNpl9MxyZn';
  static const String _faceShapeModel = 'face-shape-n9tfv/3';
  static const String _hairDetectionModel = 'hair-pddt2/1';
  static const String _bodyAnalysisModel = 'bodymeasure-sotdp/5';

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Analizar perfil completo: rostro, cabello y cuerpo desde archivo
  Future<Map<String, dynamic>> analyzeFullProfile({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Subir imagen temporal a Firebase Storage
      final tempImageUrl = await _uploadTempImage(userId, imageFile);

      // 2. Ejecutar todos los análisis en paralelo
      final results = await Future.wait([
        _callRoboflowAPI(model: _faceShapeModel, imageFile: imageFile),
        _callRoboflowAPI(model: _hairDetectionModel, imageFile: imageFile),
        _callRoboflowAPI(model: _bodyAnalysisModel, imageFile: imageFile),
      ]);

      final faceResult = results[0];
      final hairResult = results[1];
      final bodyResult = results[2];

      // 3. Crear modelos de análisis
      final faceAnalysis = FaceAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: faceResult,
        imageUrl: tempImageUrl,
      );

      final hairAnalysis = HairAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: hairResult,
        imageUrl: tempImageUrl,
      );

      final bodyAnalysis = BodyAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: bodyResult,
        imageUrl: tempImageUrl,
      );

      return {
        'faceAnalysis': faceAnalysis,
        'hairAnalysis': hairAnalysis,
        'bodyAnalysis': bodyAnalysis,
        'imageUrl': tempImageUrl,
      };

    } catch (e) {
      print('Error en analyzeFullProfile: $e');
      throw AppException('Error en análisis completo: ${e.toString()}');
    }
  }

  // Analizar perfil completo desde URL
  Future<Map<String, dynamic>> analyzeFullProfileFromUrl({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Ejecutar todos los análisis en paralelo
      final results = await Future.wait([
        _callRoboflowAPIFromUrl(model: _faceShapeModel, imageUrl: imageUrl),
        _callRoboflowAPIFromUrl(model: _hairDetectionModel, imageUrl: imageUrl),
        _callRoboflowAPIFromUrl(model: _bodyAnalysisModel, imageUrl: imageUrl),
      ]);

      final faceResult = results[0];
      final hairResult = results[1];
      final bodyResult = results[2];

      // 2. Crear modelos de análisis
      final faceAnalysis = FaceAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: faceResult,
        imageUrl: imageUrl,
      );

      final hairAnalysis = HairAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: hairResult,
        imageUrl: imageUrl,
      );

      final bodyAnalysis = BodyAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: bodyResult,
        imageUrl: imageUrl,
      );

      return {
        'faceAnalysis': faceAnalysis,
        'hairAnalysis': hairAnalysis,
        'bodyAnalysis': bodyAnalysis,
        'imageUrl': imageUrl,
      };

    } catch (e) {
      print('Error en analyzeFullProfileFromUrl: $e');
      throw AppException('Error en análisis completo: ${e.toString()}');
    }
  }

  // Analizar solo cuerpo desde archivo
  Future<BodyAnalysisModel> analyzeBodyType({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Subir imagen temporal a Firebase Storage
      final tempImageUrl = await _uploadTempImage(userId, imageFile);

      // 2. Analizar con Roboflow
      final analysisResult = await _callRoboflowAPI(
        model: _bodyAnalysisModel,
        imageFile: imageFile,
      );

      // 3. Crear modelo de análisis
      final bodyAnalysis = BodyAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: analysisResult,
        imageUrl: tempImageUrl,
      );

      return bodyAnalysis;

    } catch (e) {
      print('Error en analyzeBodyType: $e');
      throw AppException('Error en análisis corporal: ${e.toString()}');
    }
  }

  // Analizar solo cuerpo desde URL
  Future<BodyAnalysisModel> analyzeBodyTypeFromUrl({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Analizar con Roboflow usando URL
      final analysisResult = await _callRoboflowAPIFromUrl(
        model: _bodyAnalysisModel,
        imageUrl: imageUrl,
      );

      // 2. Crear modelo de análisis
      final bodyAnalysis = BodyAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: analysisResult,
        imageUrl: imageUrl,
      );

      return bodyAnalysis;

    } catch (e) {
      print('Error en analyzeBodyTypeFromUrl: $e');
      throw AppException('Error en análisis corporal: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> analyzeCompleteProfile({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Subir imagen temporal a Firebase Storage
      final tempImageUrl = await _uploadTempImage(userId, imageFile);

      // 2. Ejecutar ambos análisis en paralelo
      final results = await Future.wait([
        _callRoboflowAPI(model: _faceShapeModel, imageFile: imageFile),
        _callRoboflowAPI(model: _hairDetectionModel, imageFile: imageFile),
      ]);

      final faceResult = results[0];
      final hairResult = results[1];

      // 3. Crear modelos de análisis
      final faceAnalysis = FaceAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: faceResult,
        imageUrl: tempImageUrl,
      );

      final hairAnalysis = HairAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: hairResult,
        imageUrl: tempImageUrl,
      );

      return {
        'faceAnalysis': faceAnalysis,
        'hairAnalysis': hairAnalysis,
        'imageUrl': tempImageUrl,
      };

    } catch (e) {
      print('Error en analyzeCompleteProfile: $e');
      throw AppException('Error en análisis completo: ${e.toString()}');
    }
  }

  // Analizar desde URL
  Future<Map<String, dynamic>> analyzeCompleteProfileFromUrl({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Ejecutar ambos análisis en paralelo
      final results = await Future.wait([
        _callRoboflowAPIFromUrl(model: _faceShapeModel, imageUrl: imageUrl),
        _callRoboflowAPIFromUrl(model: _hairDetectionModel, imageUrl: imageUrl),
      ]);

      final faceResult = results[0];
      final hairResult = results[1];

      // 2. Crear modelos de análisis
      final faceAnalysis = FaceAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: faceResult,
        imageUrl: imageUrl,
      );

      final hairAnalysis = HairAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: hairResult,
        imageUrl: imageUrl,
      );

      return {
        'faceAnalysis': faceAnalysis,
        'hairAnalysis': hairAnalysis,
        'imageUrl': imageUrl,
      };

    } catch (e) {
      print('Error en analyzeCompleteProfileFromUrl: $e');
      throw AppException('Error en análisis completo: ${e.toString()}');
    }
  }

  // Métodos legacy para compatibilidad (solo análisis facial)
  Future<FaceAnalysisModel> analyzeFaceShape({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Subir imagen temporal a Firebase Storage
      final tempImageUrl = await _uploadTempImage(userId, imageFile);

      // 2. Analizar con Roboflow
      final analysisResult = await _callRoboflowAPI(
        model: _faceShapeModel,
        imageFile: imageFile,
      );

      // 3. Crear modelo de análisis
      final faceAnalysis = FaceAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: analysisResult,
        imageUrl: tempImageUrl,
      );

      return faceAnalysis;

    } catch (e) {
      print('Error en analyzeFaceShape: $e');
      throw AppException('Error en análisis facial: ${e.toString()}');
    }
  }

  Future<FaceAnalysisModel> analyzeFaceShapeFromUrl({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Verificar autenticación
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw AppException('Usuario no autenticado o UID incorrecto');
      }

      // 1. Analizar con Roboflow usando URL
      final analysisResult = await _callRoboflowAPIFromUrl(
        model: _faceShapeModel,
        imageUrl: imageUrl,
      );

      // 2. Crear modelo de análisis
      final faceAnalysis = FaceAnalysisModel.fromRoboflowResponse(
        userId: userId,
        response: analysisResult,
        imageUrl: imageUrl,
      );

      return faceAnalysis;

    } catch (e) {
      print('Error en analyzeFaceShapeFromUrl: $e');
      throw AppException('Error en análisis facial: ${e.toString()}');
    }
  }

  // Llamada a la API de Roboflow con archivo
  Future<Map<String, dynamic>> _callRoboflowAPI({
    required String model,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$model?api_key=$_apiKey');

      // Leer imagen como bytes y convertir a base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: base64Image,
      );

      print('Roboflow API Response Status ($model): ${response.statusCode}');
      print('Roboflow API Response Body ($model): ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _validateRoboflowResponse(result, model);
        return result;
      } else {
        throw AppException(
          'Error en API de Roboflow ($model): ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error de conexión con Roboflow ($model): ${e.toString()}');
    }
  }

  // Llamada a la API de Roboflow con URL
  Future<Map<String, dynamic>> _callRoboflowAPIFromUrl({
    required String model,
    required String imageUrl,
  }) async {
    try {
      // Primero descargar la imagen
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw AppException('No se pudo descargar la imagen desde la URL');
      }

      // Convertir a base64 y usar el mismo método que con archivos
      final base64Image = base64Encode(imageResponse.bodyBytes);

      final url = Uri.parse('$_baseUrl/$model?api_key=$_apiKey');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: base64Image,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _validateRoboflowResponse(result, model);
        return result;
      } else {
        throw AppException(
          'Error en API de Roboflow ($model): ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error de conexión con Roboflow ($model): ${e.toString()}');
    }
  }

  // CORREGIDO: Subir imagen temporal con nombre compatible con las reglas
  Future<String> _uploadTempImage(String userId, File imageFile) async {
    try {
      // Generar nombre de archivo compatible con las reglas de Storage
      // Formato: userId_timestamp.ext
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${userId}_analysis_$timestamp.$extension';

      print('Uploading to: analysis/$userId/$fileName');

      final ref = _storage.ref().child('analysis/$userId/$fileName');

      // Configurar metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'purpose': 'complete_analysis',
          'timestamp': timestamp.toString(),
        },
      );

      final uploadTask = await ref.putFile(imageFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('Upload successful. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw AppException('Error subiendo imagen: ${e.toString()}');
    }
  }

  // Obtener content type basado en la extensión
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  // Validar respuesta de Roboflow
  void _validateRoboflowResponse(Map<String, dynamic> response, String model) {
    print('Validating Roboflow response for $model: $response');

    if (model.contains('bodymeasure')) {
      // Validación especial para análisis corporal
      if (!response.containsKey('predictions')) {
        throw AppException('Respuesta inválida de Roboflow: falta campo predictions');
      }

      final predictions = response['predictions'] as Map<String, dynamic>;
      if (predictions.isEmpty) {
        throw AppException('No se detectó información corporal en la imagen');
      }

      // Verificar que al menos una predicción tenga confianza aceptable
      bool hasValidPrediction = false;
      predictions.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final confidence = value['confidence'];
          if (confidence != null && confidence >= 0.3) {
            hasValidPrediction = true;
          }
        }
      });

      if (!hasValidPrediction) {
        throw AppException(
          'Confianza muy baja en análisis corporal. '
              'Intenta con una imagen de cuerpo completo más clara.',
        );
      }
    } else {
      // Validación para análisis facial y de cabello
      if (!response.containsKey('predictions')) {
        throw AppException('Respuesta inválida de Roboflow: falta campo predictions');
      }

      final predictions = response['predictions'] as List;
      if (predictions.isEmpty) {
        if (model.contains('face-shape')) {
          throw AppException('No se detectó ningún rostro en la imagen');
        } else if (model.contains('hair')) {
          throw AppException('No se detectó cabello en la imagen');
        } else {
          throw AppException('No se detectó contenido relevante en la imagen');
        }
      }

      final prediction = predictions[0];
      if (!prediction.containsKey('class') || !prediction.containsKey('confidence')) {
        throw AppException('Respuesta inválida: faltan campos requeridos');
      }

      final confidence = prediction['confidence'];
      if (confidence < 0.3) {
        throw AppException(
          'Confianza muy baja (${(confidence * 100).toStringAsFixed(1)}%). '
              'Intenta con una imagen más clara.',
        );
      }
    }
  }

  // Limpiar imágenes temporales
  Future<void> cleanupTempImages(String userId) async {
    try {
      final ref = _storage.ref().child('analysis/$userId');
      final result = await ref.listAll();

      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      print('Error limpiando imágenes temporales: $e');
      // No lanzar error, es limpieza opcional
    }
  }

  // Obtener información sobre formas de rostro
  static Map<String, Map<String, dynamic>> getFaceShapeInfo() {
    return {
      'oval': {
        'name': 'Ovalado',
        'description': 'Forma equilibrada y proporcionada',
        'characteristics': [
          'Frente ligeramente más ancha que la barbilla',
          'Pómulos son la parte más ancha',
          'Rostro es 1.5 veces más largo que ancho',
          'Mandíbula redondeada'
        ],
        'celebrities': ['Beyoncé', 'Jessica Alba', 'Blake Lively'],
        'color': Color(0xFF4CAF50),
      },
      'round': {
        'name': 'Redondo',
        'description': 'Rostro con mejillas llenas y curvas suaves',
        'characteristics': [
          'Ancho y largo similares',
          'Mejillas llenas',
          'Frente ancha',
          'Mandíbula suave y redondeada'
        ],
        'celebrities': ['Selena Gomez', 'Chrissy Teigen', 'Kirsten Dunst'],
        'color': Color(0xFF2196F3),
      },
      'square': {
        'name': 'Cuadrado',
        'description': 'Rostro angular con mandíbula fuerte',
        'characteristics': [
          'Frente, pómulos y mandíbula de ancho similar',
          'Mandíbula angular y definida',
          'Líneas más rectas que curvas',
          'Rostro de proporciones similares'
        ],
        'celebrities': ['Angelina Jolie', 'Olivia Wilde', 'Keira Knightley'],
        'color': Color(0xFF9C27B0),
      },
      'heart': {
        'name': 'Corazón',
        'description': 'Frente amplia que se estrecha hacia la barbilla',
        'characteristics': [
          'Frente es la parte más ancha',
          'Pómulos de ancho medio',
          'Barbilla puntiaguda',
          'Puede tener línea de cabello en forma de corazón'
        ],
        'celebrities': ['Scarlett Johansson', 'Reese Witherspoon', 'Jennifer Lawrence'],
        'color': Color(0xFFE91E63),
      },
      'diamond': {
        'name': 'Diamante',
        'description': 'Pómulos prominentes con frente y barbilla estrechas',
        'characteristics': [
          'Pómulos son la parte más ancha',
          'Frente estrecha',
          'Barbilla puntiaguda',
          'Rostro angular en el centro'
        ],
        'celebrities': ['Rihanna', 'Halle Berry', 'Jennifer Lopez'],
        'color': Color(0xFF00BCD4),
      },
      'oblong': {
        'name': 'Alargado',
        'description': 'Rostro más largo que ancho',
        'characteristics': [
          'Rostro notablemente más largo que ancho',
          'Frente, pómulos y mandíbula de ancho similar',
          'Mentón alargado',
          'Proporciones verticales prominentes'
        ],
        'celebrities': ['Sarah Jessica Parker', 'Liv Tyler', 'Gisele Bündchen'],
        'color': Color(0xFFFF9800),
      },
    };
  }

  // Obtener información sobre tipos de cabello
  static Map<String, Map<String, dynamic>> getHairTypeInfo() {
    return {
      'straight': {
        'name': 'Liso',
        'description': 'Cabello naturalmente recto y suave',
        'characteristics': [
          'Textura lisa y uniforme',
          'Tendencia a verse grasoso rápidamente',
          'Difícil de mantener ondas',
          'Brillo natural'
        ],
        'care_tips': [
          'Usa champús sin sulfatos',
          'Evita productos muy pesados',
          'Lava cada 2-3 días',
          'Usa protector térmico'
        ],
        'color': Color(0xFF4FC3F7),
      },
      'wavy': {
        'name': 'Ondulado',
        'description': 'Cabello con ondas naturales suaves',
        'characteristics': [
          'Patrón de ondas en forma de S',
          'Textura media',
          'Tendencia al frizz',
          'Volumen natural'
        ],
        'care_tips': [
          'Usa productos para definir ondas',
          'Evita cepillar en seco',
          'Usa difusor al secar',
          'Aplica mascarillas hidratantes'
        ],
        'color': Color(0xFF81C784),
      },
      'curly': {
        'name': 'Rizado',
        'description': 'Cabello con rizos definidos y volumen',
        'characteristics': [
          'Rizos en forma de espiral',
          'Textura gruesa',
          'Tendencia a la sequedad',
          'Mucho volumen natural'
        ],
        'care_tips': [
          'Hidrata intensivamente',
          'Usa técnica de plopping',
          'No uses champú diario',
          'Aplica leave-in cream'
        ],
        'color': Color(0xFFAB47BC),
      },
      'coily': {
        'name': 'Crespo',
        'description': 'Cabello con textura muy rizada y densa',
        'characteristics': [
          'Patrón de rizos muy cerrados',
          'Textura densa y fuerte',
          'Muy propenso a la sequedad',
          'Frágil cuando está húmedo'
        ],
        'care_tips': [
          'Hidratación profunda semanal',
          'Usa productos sin sulfatos ni siliconas',
          'Protege mientras duermes',
          'Desenreda solo con acondicionador'
        ],
        'color': Color(0xFFFF7043),
      },
    };
  }

  // Obtener información sobre tipos de cuerpo
  static Map<String, Map<String, dynamic>> getBodyTypeInfo() {
    return {
      'ecto': {
        'name': 'Ectomorfo',
        'description': 'Complexión delgada y esbelta naturalmente',
        'characteristics': [
          'Metabolismo rápido',
          'Estructura ósea pequeña',
          'Hombros y caderas estrechos',
          'Dificultad para ganar peso'
        ],
        'clothing_tips': [
          'Añadir capas para crear volumen',
          'Patrones horizontales y texturas gruesas',
          'Colores claros y brillantes',
          'Chaquetas estructuradas'
        ],
        'color': Color(0xFF2196F3),
      },
      'meso': {
        'name': 'Mesomorfo',
        'description': 'Complexión atlética y naturalmente musculosa',
        'characteristics': [
          'Estructura ósea media',
          'Hombros anchos',
          'Cintura definida',
          'Facilidad para ganar músculo'
        ],
        'clothing_tips': [
          'Ropa que resalte la silueta natural',
          'Cortes ajustados pero cómodos',
          'Colores sólidos y vibrantes',
          'Cinturones para definir cintura'
        ],
        'color': Color(0xFF4CAF50),
      },
      'endo': {
        'name': 'Endomorfo',
        'description': 'Complexión redondeada con tendencia a almacenar grasa',
        'characteristics': [
          'Estructura ósea grande',
          'Metabolismo más lento',
          'Facilidad para ganar peso',
          'Curvas naturales'
        ],
        'clothing_tips': [
          'Líneas verticales para alargar',
          'Colores oscuros y monocromáticos',
          'Cortes en A y empire waist',
          'Evitar patrones muy llamativos'
        ],
        'color': Color(0xFFFF9800),
      },
    };
  }

  // Obtener información sobre formas de cuerpo
  static Map<String, Map<String, dynamic>> getBodyShapeInfo() {
    return {
      'invert': {
        'name': 'Triángulo Invertido',
        'description': 'Hombros más anchos que caderas',
        'characteristics': [
          'Hombros anchos',
          'Caderas estrechas',
          'Torso proporcionado',
          'Piernas delgadas'
        ],
        'clothing_tips': [
          'Pantalones de colores claros',
          'Faldas A-line y bootcut',
          'Tops ajustados',
          'Evitar hombreras pronunciadas'
        ],
        'color': Color(0xFFE91E63),
      },
      'pear': {
        'name': 'Pera',
        'description': 'Caderas más anchas que hombros',
        'characteristics': [
          'Hombros estrechos',
          'Caderas anchas',
          'Cintura definida',
          'Muslos más llenos'
        ],
        'clothing_tips': [
          'Tops con detalles llamativos',
          'Colores claros arriba',
          'Pantalones oscuros',
          'Chaquetas que terminen en cadera'
        ],
        'color': Color(0xFF9C27B0),
      },
      'rectangle': {
        'name': 'Rectángulo',
        'description': 'Hombros, cintura y caderas de medidas similares',
        'characteristics': [
          'Silueta recta',
          'Cintura poco definida',
          'Proporciones equilibradas',
          'Distribución uniforme'
        ],
        'clothing_tips': [
          'Crear curvas con cinturones',
          'Peplum tops y chaquetas ajustadas',
          'Capas para añadir dimensión',
          'Patrones y texturas interesantes'
        ],
        'color': Color(0xFF00BCD4),
      },
    };
  }
}