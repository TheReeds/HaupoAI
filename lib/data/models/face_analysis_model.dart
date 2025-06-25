// lib/data/models/face_analysis_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FaceAnalysisModel {
  final String id;
  final String userId;
  final String faceShape;
  final double confidence;
  final String? imageUrl;
  final DateTime analyzedAt;
  final Map<String, dynamic>? additionalData;

  FaceAnalysisModel({
    required this.id,
    required this.userId,
    required this.faceShape,
    required this.confidence,
    this.imageUrl,
    required this.analyzedAt,
    this.additionalData,
  });

  factory FaceAnalysisModel.fromRoboflowResponse({
    required String userId,
    required Map<String, dynamic> response,
    String? imageUrl,
  }) {
    final predictions = response['predictions'] as List;
    final prediction = predictions.isNotEmpty ? predictions[0] : null;

    return FaceAnalysisModel(
      id: '',
      userId: userId,
      faceShape: prediction?['class'] ?? 'Unknown',
      confidence: (prediction?['confidence'] ?? 0.0).toDouble(),
      imageUrl: imageUrl,
      analyzedAt: DateTime.now(),
      additionalData: {
        'classId': prediction?['class_id'],
        'rawResponse': response,
      },
    );
  }

  factory FaceAnalysisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FaceAnalysisModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      faceShape: data['faceShape'] ?? '',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      analyzedAt: (data['analyzedAt'] as Timestamp).toDate(),
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'faceShape': faceShape,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'analyzedAt': Timestamp.fromDate(analyzedAt),
      'additionalData': additionalData,
    };
  }

  // Método para obtener recomendaciones de corte según la forma del rostro
  List<String> getHairStyleRecommendations() {
    switch (faceShape.toLowerCase()) {
      case 'oval':
        return [
          'Cortes en capas',
          'Flequillo lateral',
          'Bob largo',
          'Ondas sueltas',
          'Casi cualquier estilo te queda bien'
        ];
      case 'round':
        return [
          'Cortes con volumen en la parte superior',
          'Flequillo largo lateral',
          'Capas largas',
          'Evitar cortes muy cortos',
          'Bob asimétrico'
        ];
      case 'square':
        return [
          'Ondas suaves',
          'Cortes en capas',
          'Flequillo desfilado',
          'Bob con movimiento',
          'Evitar cortes muy rectos'
        ];
      case 'heart':
        return [
          'Flequillo completo',
          'Bob a la barbilla',
          'Capas hacia afuera',
          'Volumen en la parte inferior',
          'Evitar mucho volumen arriba'
        ];
      case 'diamond':
        return [
          'Flequillo lateral',
          'Volumen en frente y barbilla',
          'Ondas suaves',
          'Bob texturizado',
          'Evitar volumen en mejillas'
        ];
      case 'oblong':
        return [
          'Flequillo recto',
          'Cortes a la altura del hombro',
          'Ondas a los lados',
          'Bob con volumen lateral',
          'Evitar cortes muy largos'
        ];
      default:
        return [
          'Consulta con un estilista profesional',
          'Experimenta con diferentes estilos',
          'Considera tu textura de cabello',
        ];
    }
  }

  // Descripción de la forma del rostro
  String getShapeDescription() {
    switch (faceShape.toLowerCase()) {
      case 'oval':
        return 'Rostro ovalado: Proporcionado y equilibrado, la forma ideal.';
      case 'round':
        return 'Rostro redondo: Mejillas llenas y frente ancha, muy dulce.';
      case 'square':
        return 'Rostro cuadrado: Mandíbula fuerte y angular, muy elegante.';
      case 'heart':
        return 'Rostro corazón: Frente amplia que se estrecha hacia la barbilla.';
      case 'diamond':
        return 'Rostro diamante: Pómulos prominentes con frente y barbilla estrechas.';
      case 'oblong':
        return 'Rostro alargado: Más largo que ancho, rasgos elongados.';
      default:
        return 'Forma de rostro única: Cada rostro tiene su propia belleza.';
    }
  }
}
