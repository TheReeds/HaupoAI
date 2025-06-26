import 'package:cloud_firestore/cloud_firestore.dart';

class ColorPaletteModel {
  final String id;
  final String userId;
  final String paletteName;
  final List<String> idealColors; // Colores hex
  final List<String> avoidColors; // Colores hex
  final List<Map<String, dynamic>> combinations; // Combinaciones recomendadas
  final String reasoning; // Explicación de por qué estos colores
  final DateTime createdAt;
  final bool isPersonalized;
  final Map<String, dynamic>? baseAnalysis; // Análisis base (tono piel, etc.)

  ColorPaletteModel({
    required this.id,
    required this.userId,
    required this.paletteName,
    required this.idealColors,
    required this.avoidColors,
    required this.combinations,
    required this.reasoning,
    required this.createdAt,
    this.isPersonalized = true,
    this.baseAnalysis,
  });

  factory ColorPaletteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ColorPaletteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      paletteName: data['paletteName'] ?? '',
      idealColors: List<String>.from(data['idealColors'] ?? []),
      avoidColors: List<String>.from(data['avoidColors'] ?? []),
      combinations: List<Map<String, dynamic>>.from(data['combinations'] ?? []),
      reasoning: data['reasoning'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPersonalized: data['isPersonalized'] ?? true,
      baseAnalysis: data['baseAnalysis'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'paletteName': paletteName,
      'idealColors': idealColors,
      'avoidColors': avoidColors,
      'combinations': combinations,
      'reasoning': reasoning,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPersonalized': isPersonalized,
      'baseAnalysis': baseAnalysis,
    };
  }

  // Método copyWith para crear copias con cambios específicos
  ColorPaletteModel copyWith({
    String? id,
    String? userId,
    String? paletteName,
    List<String>? idealColors,
    List<String>? avoidColors,
    List<Map<String, dynamic>>? combinations,
    String? reasoning,
    DateTime? createdAt,
    bool? isPersonalized,
    Map<String, dynamic>? baseAnalysis,
  }) {
    return ColorPaletteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      paletteName: paletteName ?? this.paletteName,
      idealColors: idealColors ?? this.idealColors,
      avoidColors: avoidColors ?? this.avoidColors,
      combinations: combinations ?? this.combinations,
      reasoning: reasoning ?? this.reasoning,
      createdAt: createdAt ?? this.createdAt,
      isPersonalized: isPersonalized ?? this.isPersonalized,
      baseAnalysis: baseAnalysis ?? this.baseAnalysis,
    );
  }

  // Crear paleta desde respuesta de IA
  factory ColorPaletteModel.fromAIResponse({
    required String userId,
    required String aiResponse,
    Map<String, dynamic>? analysisData,
  }) {
    // Aquí podrías parsear la respuesta de IA para extraer colores específicos
    // Por ahora, creamos una paleta básica
    return ColorPaletteModel(
      id: '',
      userId: userId,
      paletteName: 'Paleta Personalizada - ${DateTime.now().day}/${DateTime.now().month}',
      idealColors: _extractColorsFromResponse(aiResponse, 'ideal'),
      avoidColors: _extractColorsFromResponse(aiResponse, 'avoid'),
      combinations: _extractCombinationsFromResponse(aiResponse),
      reasoning: aiResponse,
      createdAt: DateTime.now(),
      isPersonalized: true,
      baseAnalysis: analysisData,
    );
  }

  // Métodos helpers para extraer información de la respuesta de IA
  static List<String> _extractColorsFromResponse(String response, String type) {
    // Implementar lógica para extraer colores de la respuesta
    // Por ahora, devolvemos colores de ejemplo
    if (type == 'ideal') {
      return ['#2E86AB', '#A23B72', '#F18F01', '#C73E1D', '#8B5A2B'];
    } else {
      return ['#FF6B6B', '#4ECDC4', '#45B7D1'];
    }
  }

  static List<Map<String, dynamic>> _extractCombinationsFromResponse(String response) {
    // Implementar lógica para extraer combinaciones
    return [
      {'name': 'Elegante', 'colors': ['#2E86AB', '#FFFFFF', '#8B5A2B']},
      {'name': 'Casual', 'colors': ['#A23B72', '#F18F01', '#FFFFFF']},
      {'name': 'Formal', 'colors': ['#000000', '#FFFFFF', '#C73E1D']},
    ];
  }
}