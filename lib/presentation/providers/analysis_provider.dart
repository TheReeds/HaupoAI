// lib/presentation/providers/analysis_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/face_analysis_model.dart';
import '../../data/models/hair_analysis_model.dart';
import '../../data/repositories/face_analysis_repository.dart';
import 'dart:io';

enum AnalysisState {
  idle,
  analyzing,
  completed,
  error,
}

class AnalysisProvider extends ChangeNotifier {
  final FaceAnalysisRepository _repository = FaceAnalysisRepository();

  AnalysisState _state = AnalysisState.idle;
  FaceAnalysisModel? _latestFaceAnalysis;
  HairAnalysisModel? _latestHairAnalysis;
  List<FaceAnalysisModel> _faceAnalysisHistory = [];
  List<HairAnalysisModel> _hairAnalysisHistory = [];
  String? _errorMessage;
  double _analysisProgress = 0.0;

  // Getters
  AnalysisState get state => _state;
  FaceAnalysisModel? get latestFaceAnalysis => _latestFaceAnalysis;
  HairAnalysisModel? get latestHairAnalysis => _latestHairAnalysis;
  List<FaceAnalysisModel> get faceAnalysisHistory => _faceAnalysisHistory;
  List<HairAnalysisModel> get hairAnalysisHistory => _hairAnalysisHistory;
  String? get errorMessage => _errorMessage;
  double get analysisProgress => _analysisProgress;
  bool get isAnalyzing => _state == AnalysisState.analyzing;
  bool get hasCompleteAnalysis => _latestFaceAnalysis != null && _latestHairAnalysis != null;

  // Realizar análisis completo desde archivo
  Future<bool> performCompleteAnalysis({
    required String userId,
    required File imageFile,
  }) async {
    _setState(AnalysisState.analyzing);
    _setProgress(0.1);
    _clearError();

    try {
      _setProgress(0.3);

      // Realizar análisis completo
      final results = await _repository.analyzeCompleteProfile(
        userId: userId,
        imageFile: imageFile,
      );

      _setProgress(0.8);

      // Actualizar estado local
      _latestFaceAnalysis = results['faceAnalysis'];
      _latestHairAnalysis = results['hairAnalysis'];

      // Recargar historiales
      await _loadAnalysisHistories(userId);

      _setProgress(1.0);
      _setState(AnalysisState.completed);

      return true;
    } catch (e) {
      _setError('Error en análisis completo: ${e.toString()}');
      return false;
    }
  }

  // Realizar análisis completo desde foto de perfil
  Future<bool> performCompleteAnalysisFromProfile({
    required String userId,
    required String photoURL,
  }) async {
    _setState(AnalysisState.analyzing);
    _setProgress(0.1);
    _clearError();

    try {
      _setProgress(0.3);

      // Realizar análisis completo
      final results = await _repository.analyzeCompleteProfileFromPhoto(
        userId: userId,
        photoURL: photoURL,
      );

      _setProgress(0.8);

      // Actualizar estado local
      _latestFaceAnalysis = results['faceAnalysis'];
      _latestHairAnalysis = results['hairAnalysis'];

      // Recargar historiales
      await _loadAnalysisHistories(userId);

      _setProgress(1.0);
      _setState(AnalysisState.completed);

      return true;
    } catch (e) {
      _setError('Error en análisis completo: ${e.toString()}');
      return false;
    }
  }

  // Realizar solo análisis facial (método legacy)
  Future<bool> performFaceAnalysis({
    required String userId,
    required File imageFile,
  }) async {
    _setState(AnalysisState.analyzing);
    _setProgress(0.1);
    _clearError();

    try {
      _setProgress(0.5);

      final analysis = await _repository.analyzeFace(
        userId: userId,
        imageFile: imageFile,
      );

      _latestFaceAnalysis = analysis;
      await _loadFaceAnalysisHistory(userId);

      _setProgress(1.0);
      _setState(AnalysisState.completed);

      return true;
    } catch (e) {
      _setError('Error en análisis facial: ${e.toString()}');
      return false;
    }
  }

  // Guardar análisis en perfil de usuario
  Future<bool> saveAnalysisToProfile(String userId) async {
    if (_latestFaceAnalysis == null && _latestHairAnalysis == null) {
      _setError('No hay análisis para guardar');
      return false;
    }

    try {
      await _repository.saveAnalysisToUserProfile(
        userId: userId,
        faceAnalysis: _latestFaceAnalysis,
        hairAnalysis: _latestHairAnalysis,
      );

      return true;
    } catch (e) {
      _setError('Error al guardar en perfil: ${e.toString()}');
      return false;
    }
  }

  // Cargar análisis existentes
  Future<void> loadLatestAnalyses(String userId) async {
    try {
      final results = await _repository.getLatestCompleteAnalysis(userId);
      _latestFaceAnalysis = results['faceAnalysis'];
      _latestHairAnalysis = results['hairAnalysis'];

      await _loadAnalysisHistories(userId);

      notifyListeners();
    } catch (e) {
      print('Error cargando análisis: $e');
    }
  }

  // Cargar historiales de análisis
  Future<void> _loadAnalysisHistories(String userId) async {
    try {
      final futures = await Future.wait([
        _repository.getUserFaceAnalyses(userId),
        _repository.getUserHairAnalyses(userId),
      ]);

      _faceAnalysisHistory = futures[0] as List<FaceAnalysisModel>;
      _hairAnalysisHistory = futures[1] as List<HairAnalysisModel>;
    } catch (e) {
      print('Error cargando historiales: $e');
    }
  }

  Future<void> _loadFaceAnalysisHistory(String userId) async {
    try {
      _faceAnalysisHistory = await _repository.getUserFaceAnalyses(userId);
    } catch (e) {
      print('Error cargando historial facial: $e');
    }
  }

  // Obtener estadísticas de análisis
  Future<Map<String, dynamic>> getAnalysisStats(String userId) async {
    try {
      return await _repository.getCompleteAnalysisStats(userId);
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {};
    }
  }

  // Eliminar análisis específico
  Future<bool> deleteFaceAnalysis(String analysisId, String userId) async {
    try {
      await _repository.deleteFaceAnalysis(analysisId);
      await _loadFaceAnalysisHistory(userId);

      // Si era el último análisis, limpiar
      if (_latestFaceAnalysis?.id == analysisId) {
        _latestFaceAnalysis = _faceAnalysisHistory.isNotEmpty ? _faceAnalysisHistory.first : null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error eliminando análisis: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteHairAnalysis(String analysisId, String userId) async {
    try {
      await _repository.deleteHairAnalysis(analysisId);
      await _loadAnalysisHistories(userId);

      // Si era el último análisis, limpiar
      if (_latestHairAnalysis?.id == analysisId) {
        _latestHairAnalysis = _hairAnalysisHistory.isNotEmpty ? _hairAnalysisHistory.first : null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error eliminando análisis: ${e.toString()}');
      return false;
    }
  }

  // Eliminar todos los análisis de un usuario
  Future<bool> deleteAllAnalyses(String userId) async {
    try {
      await _repository.deleteAllUserAnalyses(userId);

      // Limpiar estado local
      _latestFaceAnalysis = null;
      _latestHairAnalysis = null;
      _faceAnalysisHistory.clear();
      _hairAnalysisHistory.clear();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error eliminando análisis: ${e.toString()}');
      return false;
    }
  }

  // Obtener recomendaciones combinadas
  List<String> getCombinedRecommendations() {
    if (_latestFaceAnalysis == null || _latestHairAnalysis == null) {
      return [];
    }

    final faceShape = _latestFaceAnalysis!.faceShape.toLowerCase();
    final hairType = _latestHairAnalysis!.hairType.toLowerCase();

    // Lógica para recomendaciones específicas basadas en la combinación
    final recommendations = <String>[];

    // Combinaciones específicas
    if (faceShape == 'round' && hairType == 'straight') {
      recommendations.addAll([
        'Capas largas para alargar visualmente el rostro',
        'Volumen en la coronilla para equilibrar proporciones',
        'Evita cortes muy cortos que acentúen la redondez',
      ]);
    } else if (faceShape == 'oval' && hairType == 'curly') {
      recommendations.addAll([
        'Tienes la combinación perfecta - casi todo te queda bien',
        'Prueba diferentes largos según tu estilo personal',
        'Define tus rizos con productos específicos para cabello rizado',
      ]);
    } else if (faceShape == 'square' && hairType == 'wavy') {
      recommendations.addAll([
        'Las ondas naturales suavizan la mandíbula angular',
        'Capas suaves alrededor del rostro para feminizar',
        'Evita cortes muy geométricos o rectos',
      ]);
    } else if (faceShape == 'heart' && hairType == 'straight') {
      recommendations.addAll([
        'Flequillo completo para equilibrar la frente ancha',
        'Volumen en la parte inferior para balancear',
        'Cortes que añadan anchura cerca de la mandíbula',
      ]);
    } else {
      // Recomendaciones generales
      recommendations.addAll([
        'Combina las recomendaciones específicas de tu rostro y cabello',
        'Considera tu textura natural al elegir estilos',
        'Mantén tu cabello saludable con cuidados apropiados',
      ]);
    }

    // Agregar recomendaciones generales
    recommendations.addAll([
      'Usa productos adecuados para tu tipo de cabello específico',
      'Considera tu estilo de vida al elegir cortes de mantenimiento',
      'Programa citas regulares para mantener la forma del corte',
      'Experimenta con diferentes técnicas de peinado',
    ]);

    return recommendations;
  }

  // Obtener productos recomendados combinados
  List<String> getCombinedProductRecommendations() {
    if (_latestHairAnalysis == null) return [];

    return _latestHairAnalysis!.getProductRecommendations();
  }

  // Obtener técnicas de peinado recomendadas
  List<String> getCombinedStylingTechniques() {
    if (_latestHairAnalysis == null) return [];

    return _latestHairAnalysis!.getStylingTechniques();
  }

  // Resetear estado
  void reset() {
    _state = AnalysisState.idle;
    _latestFaceAnalysis = null;
    _latestHairAnalysis = null;
    _faceAnalysisHistory.clear();
    _hairAnalysisHistory.clear();
    _errorMessage = null;
    _analysisProgress = 0.0;
    notifyListeners();
  }

  // Métodos privados
  void _setState(AnalysisState state) {
    _state = state;
    notifyListeners();
  }

  void _setProgress(double progress) {
    _analysisProgress = progress;
    notifyListeners();
  }

  void _setError(String error) {
    _state = AnalysisState.error;
    _errorMessage = error;
    _analysisProgress = 0.0;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_state == AnalysisState.error) {
      _state = AnalysisState.idle;
    }
  }

  // Limpiar error manualmente
  void clearError() {
    _clearError();
    notifyListeners();
  }
}