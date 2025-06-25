// lib/core/services/roboflow_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../errors/exceptions.dart';
import '../../data/models/face_analysis_model.dart';

class RoboflowService {
  static const String _baseUrl = 'https://serverless.roboflow.com';
  static const String _apiKey = 'kzEso6BdqfaNpl9MxyZn';
  static const String _faceShapeModel = 'face-shape-n9tfv/3';

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Analizar forma del rostro desde archivo
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
      print('Error en analyzeFaceShape: $e'); // Para debugging
      throw AppException('Error en análisis facial: ${e.toString()}');
    }
  }

  // Analizar forma del rostro desde URL
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
      print('Error en analyzeFaceShapeFromUrl: $e'); // Para debugging
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

      print('Roboflow API Response Status: ${response.statusCode}'); // Debug
      print('Roboflow API Response Body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _validateRoboflowResponse(result);
        return result;
      } else {
        throw AppException(
          'Error en API de Roboflow: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error de conexión con Roboflow: ${e.toString()}');
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
        _validateRoboflowResponse(result);
        return result;
      } else {
        throw AppException(
          'Error en API de Roboflow: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error de conexión con Roboflow: ${e.toString()}');
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

      print('Uploading to: analysis/$userId/$fileName'); // Debug

      final ref = _storage.ref().child('analysis/$userId/$fileName');

      // Configurar metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'purpose': 'face_analysis',
          'timestamp': timestamp.toString(),
        },
      );

      final uploadTask = await ref.putFile(imageFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('Upload successful. URL: $downloadUrl'); // Debug

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e'); // Debug
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
  void _validateRoboflowResponse(Map<String, dynamic> response) {
    print('Validating Roboflow response: $response'); // Debug

    if (!response.containsKey('predictions')) {
      throw AppException('Respuesta inválida de Roboflow: falta campo predictions');
    }

    final predictions = response['predictions'] as List;
    if (predictions.isEmpty) {
      throw AppException('No se detectó ningún rostro en la imagen');
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
}