// lib/data/models/hair_analysis_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HairAnalysisModel {
  final String id;
  final String userId;
  final String hairType;
  final double confidence;
  final String? imageUrl;
  final DateTime analyzedAt;
  final Map<String, dynamic>? additionalData;

  HairAnalysisModel({
    required this.id,
    required this.userId,
    required this.hairType,
    required this.confidence,
    this.imageUrl,
    required this.analyzedAt,
    this.additionalData,
  });

  factory HairAnalysisModel.fromRoboflowResponse({
    required String userId,
    required Map<String, dynamic> response,
    String? imageUrl,
  }) {
    final predictions = response['predictions'] as List;
    final prediction = predictions.isNotEmpty ? predictions[0] : null;

    // Normalizar el tipo de cabello
    String hairType = prediction?['class'] ?? 'Unknown';
    hairType = _normalizeHairType(hairType);

    return HairAnalysisModel(
      id: '',
      userId: userId,
      hairType: hairType,
      confidence: (prediction?['confidence'] ?? 0.0).toDouble(),
      imageUrl: imageUrl,
      analyzedAt: DateTime.now(),
      additionalData: {
        'classId': prediction?['class_id'],
        'rawResponse': response,
        'detection_id': prediction?['detection_id'],
        'coordinates': {
          'x': prediction?['x'],
          'y': prediction?['y'],
          'width': prediction?['width'],
          'height': prediction?['height'],
        },
      },
    );
  }

  factory HairAnalysisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HairAnalysisModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      hairType: data['hairType'] ?? '',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      analyzedAt: (data['analyzedAt'] as Timestamp).toDate(),
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'hairType': hairType,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'analyzedAt': Timestamp.fromDate(analyzedAt),
      'additionalData': additionalData,
    };
  }

  // Normalizar tipos de cabello de la API
  static String _normalizeHairType(String apiType) {
    switch (apiType.toLowerCase()) {
      case 'straight':
        return 'straight';
      case 'wavy':
        return 'wavy';
      case 'curly':
        return 'curly';
      case 'coily':
      case 'coil':
        return 'coily';
      default:
        return apiType.toLowerCase();
    }
  }

  // Método para obtener recomendaciones de cuidado según el tipo de cabello
  List<String> getHairCareRecommendations() {
    switch (hairType.toLowerCase()) {
      case 'straight':
        return [
          'Usa champús libres de sulfatos para evitar resecar',
          'Evita productos muy pesados que apelmacen',
          'Lava cada 2-3 días para controlar la grasa',
          'Usa protector térmico antes del peinado',
          'Cepilla desde las puntas hacia arriba'
        ];
      case 'wavy':
        return [
          'Usa productos para definir ondas naturales',
          'Evita cepillar en seco para prevenir frizz',
          'Seca con difusor en temperatura baja',
          'Aplica mascarillas hidratantes semanalmente',
          'Duerme con cabello recogido suavemente'
        ];
      case 'curly':
        return [
          'Hidrata intensivamente con mascarillas',
          'Usa la técnica de plopping para secar',
          'No uses champú todos los días',
          'Aplica leave-in cream en cabello húmedo',
          'Desenreda solo con acondicionador'
        ];
      case 'coily':
        return [
          'Hidratación profunda semanal es esencial',
          'Usa productos sin sulfatos ni siliconas',
          'Protege el cabello mientras duermes',
          'Desenreda únicamente con acondicionador',
          'Evita manipular en exceso'
        ];
      default:
        return [
          'Consulta con un especialista en cabello',
          'Experimenta con diferentes productos',
          'Mantén una rutina de hidratación',
          'Protege del calor y químicos'
        ];
    }
  }

  // Obtener recomendaciones de productos
  List<String> getProductRecommendations() {
    switch (hairType.toLowerCase()) {
      case 'straight':
        return [
          'Champú clarificante semanal',
          'Acondicionador ligero',
          'Sérum anti-frizz',
          'Spray voluminizador',
          'Protector térmico en spray'
        ];
      case 'wavy':
        return [
          'Champú sin sulfatos',
          'Acondicionador hidratante',
          'Crema para definir ondas',
          'Gel de fijación ligera',
          'Aceite capilar para puntas'
        ];
      case 'curly':
        return [
          'Co-wash (acondicionador limpiador)',
          'Mascarilla hidratante profunda',
          'Crema leave-in',
          'Gel definidor de rizos',
          'Aceite natural (coco, argán)'
        ];
      case 'coily':
        return [
          'Champú hidratante sin sulfatos',
          'Mascarilla reparadora intensiva',
          'Manteca capilar (karité, murumuru)',
          'Crema para peinar densa',
          'Aceites naturales múltiples'
        ];
      default:
        return [
          'Productos específicos para tu tipo',
          'Champú suave',
          'Acondicionador nutritivo',
          'Tratamiento semanal'
        ];
    }
  }

  // Obtener técnicas de peinado recomendadas
  List<String> getStylingTechniques() {
    switch (hairType.toLowerCase()) {
      case 'straight':
        return [
          'Secado con cepillo redondo para volumen',
          'Plancha con temperaturas medias',
          'Rulos grandes para ondas suaves',
          'Spray texturizante para cuerpo',
          'Peinados sleek y pulidos'
        ];
      case 'wavy':
        return [
          'Scrunching para realzar ondas',
          'Difusor en temperatura baja',
          'Trenzas húmedas para ondas definidas',
          'Twist-outs para textura',
          'Peinados semi-recogidos'
        ];
      case 'curly':
        return [
          'Plopping con camiseta de algodón',
          'Método LOC (Leave-in, Oil, Cream)',
          'Finger coiling para definir rizos',
          'Pineapple method para dormir',
          'Refresh con spray de agua'
        ];
      case 'coily':
        return [
          'Twist-outs y bantu knots',
          'Wash and go con gel fuerte',
          'Protective styles (trenzas, moños)',
          'Stretching techniques',
          'Oil pulling para hidratar'
        ];
      default:
        return [
          'Técnicas apropiadas para tu textura',
          'Protección nocturna',
          'Manipulación mínima',
          'Hidratación constante'
        ];
    }
  }

  // Descripción del tipo de cabello
  String getHairTypeDescription() {
    switch (hairType.toLowerCase()) {
      case 'straight':
        return 'Cabello liso: Naturalmente recto, con tendencia a la grasa en raíces.';
      case 'wavy':
        return 'Cabello ondulado: Con ondas naturales suaves en forma de S.';
      case 'curly':
        return 'Cabello rizado: Con rizos definidos y mucho volumen natural.';
      case 'coily':
        return 'Cabello crespo: Con textura muy rizada, densa y fuerte.';
      default:
        return 'Tipo de cabello único: Cada textura tiene sus propias necesidades.';
    }
  }

  // Obtener color representativo del tipo de cabello
  int getHairTypeColor() {
    switch (hairType.toLowerCase()) {
      case 'straight':
        return 0xFF4FC3F7; // Azul claro
      case 'wavy':
        return 0xFF81C784; // Verde claro
      case 'curly':
        return 0xFFAB47BC; // Púrpura
      case 'coily':
        return 0xFFFF7043; // Naranja
      default:
        return 0xFF9E9E9E; // Gris
    }
  }
}