import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../core/services/personalized_recommendations_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/preference_model.dart';
import '../../data/models/personalized_recommendations_model.dart';
import '../../data/repositories/personalized_recommendations_repository.dart';
import '../../data/repositories/preference_repository.dart';

enum RecommendationsState {
  initial,
  loading,
  loaded,
  generating,
  error,
}

class RecommendationsProvider extends ChangeNotifier {
  final PersonalizedRecommendationsRepository _repository;
  final PreferenceRepository _preferenceRepository;
  final PersonalizedRecommendationsService _improvedService;

  RecommendationsState _state = RecommendationsState.initial;
  PersonalizedRecommendationsModel? _currentRecommendations;
  List<PersonalizedRecommendationsModel> _recommendationsHistory = [];
  PreferenceModel? _userPreferences;
  String? _errorMessage;
  double _generationProgress = 0.0;

  // Estadísticas
  Map<String, dynamic> _followingStats = {};
  Map<String, dynamic> _personalTrends = {};

  RecommendationsProvider({
    PersonalizedRecommendationsRepository? repository,
    PreferenceRepository? preferenceRepository,
    PersonalizedRecommendationsService? improvedService,
  })  : _repository = repository ?? PersonalizedRecommendationsRepository(),
        _preferenceRepository = preferenceRepository ?? PreferenceRepository(),
        _improvedService = improvedService ?? PersonalizedRecommendationsService();

  // Getters
  RecommendationsState get state => _state;
  PersonalizedRecommendationsModel? get currentRecommendations => _currentRecommendations;
  List<PersonalizedRecommendationsModel> get recommendationsHistory => _recommendationsHistory;
  PreferenceModel? get userPreferences => _userPreferences;
  String? get errorMessage => _errorMessage;
  double get generationProgress => _generationProgress;
  Map<String, dynamic> get followingStats => _followingStats;
  Map<String, dynamic> get personalTrends => _personalTrends;

  // Estado
  bool get isLoading => _state == RecommendationsState.loading;
  bool get isGenerating => _state == RecommendationsState.generating;
  bool get hasRecommendations => _currentRecommendations != null;
  bool get hasError => _state == RecommendationsState.error;
  bool get needsUpdate => _currentRecommendations?.needsUpdate ?? true;

  // Cargar datos iniciales
  Future<void> loadUserData(String userId) async {
    _setState(RecommendationsState.loading);
    _clearError();

    try {
      // Cargar en paralelo
      final results = await Future.wait([
        _repository.getLatestRecommendations(userId),
        _preferenceRepository.getPreferences(userId),
        _repository.getUserRecommendationsHistory(userId, limit: 10),
      ]);

      _currentRecommendations = results[0] as PersonalizedRecommendationsModel?;
      _userPreferences = results[1] as PreferenceModel?;
      _recommendationsHistory = results[2] as List<PersonalizedRecommendationsModel>;

      // Cargar estadísticas si hay recomendaciones
      if (_currentRecommendations != null) {
        await _loadStatistics(userId);
      }

      _setState(RecommendationsState.loaded);

    } catch (e) {
      _setError('Error cargando datos: ${e.toString()}');
    }
  }

  // Generar nuevas recomendaciones (versión mejorada)
  Future<bool> generateImprovedRecommendations({
    required UserModel user,
    File? wellnessPhoto,
  }) async {
    if (_userPreferences == null) {
      _setError('No se encontraron preferencias del usuario');
      return false;
    }

    _setState(RecommendationsState.generating);
    _setProgress(0.1);
    _clearError();

    try {
      _setProgress(0.3);

      // Usar el servicio mejorado
      final recommendations = await _improvedService.generateImprovedRecommendations(
        user: user,
        preferences: _userPreferences!,
        wellnessPhoto: wellnessPhoto,
      );

      _setProgress(0.8);

      // Guardar en repositorio
      final savedRecommendations = await _repository.generateAndSaveRecommendations(
        user: user,
        preferences: _userPreferences!,
        wellnessPhoto: wellnessPhoto,
      );

      _setProgress(0.9);

      // Actualizar estado local
      _currentRecommendations = savedRecommendations;
      _recommendationsHistory.insert(0, savedRecommendations);

      // Recargar estadísticas
      await _loadStatistics(user.uid);

      _setProgress(1.0);
      _setState(RecommendationsState.loaded);

      return true;

    } catch (e) {
      _setError('Error generando recomendaciones: ${e.toString()}');
      return false;
    }
  }

  // Generar recomendaciones estándar
  Future<bool> generateRecommendations({
    required UserModel user,
    File? wellnessPhoto,
  }) async {
    if (_userPreferences == null) {
      _setError('No se encontraron preferencias del usuario');
      return false;
    }

    _setState(RecommendationsState.generating);
    _setProgress(0.1);
    _clearError();

    try {
      _setProgress(0.5);

      final recommendations = await _repository.generateAndSaveRecommendations(
        user: user,
        preferences: _userPreferences!,
        wellnessPhoto: wellnessPhoto,
      );

      _setProgress(0.9);

      _currentRecommendations = recommendations;
      _recommendationsHistory.insert(0, recommendations);

      await _loadStatistics(user.uid);

      _setProgress(1.0);
      _setState(RecommendationsState.loaded);

      return true;

    } catch (e) {
      _setError('Error generando recomendaciones: ${e.toString()}');
      return false;
    }
  }

  // Marcar recomendación como seguida
  Future<void> markRecommendationAsFollowed(String category, int index) async {
    if (_currentRecommendations == null) return;

    try {
      await _repository.markRecommendationAsFollowed(
        _currentRecommendations!.id,
        category,
        index,
      );

      // Recargar estadísticas
      await _loadStatistics(_currentRecommendations!.userId);

    } catch (e) {
      print('Error marcando recomendación: $e');
    }
  }

  // Obtener recomendaciones por categoría
  Future<List<String>> getRecommendationsByCategory(String userId, String category) async {
    try {
      return await _repository.getRecommendationsByCategory(userId, category);
    } catch (e) {
      print('Error obteniendo recomendaciones por categoría: $e');
      return [];
    }
  }

  // Generar recomendaciones mejoradas por categoría
  Future<List<String>> generateEnhancedRecommendations({
    required UserModel user,
    required String category,
    Map<String, dynamic>? wellnessAnalysis,
  }) async {
    if (_userPreferences == null) return [];

    try {
      return await _repository.generateEnhancedRecommendations(
        user: user,
        preferences: _userPreferences!,
        category: category,
        wellnessAnalysis: wellnessAnalysis,
      );
    } catch (e) {
      print('Error generando recomendaciones mejoradas: $e');
      return [];
    }
  }

  // Cargar estadísticas
  Future<void> _loadStatistics(String userId) async {
    try {
      final results = await Future.wait([
        _repository.getFollowingStats(userId),
        _repository.getPersonalTrends(userId),
      ]);

      _followingStats = results[0] as Map<String, dynamic>;
      _personalTrends = results[1] as Map<String, dynamic>;

    } catch (e) {
      print('Error cargando estadísticas: $e');
    }
  }

  // Exportar reporte
  Future<Map<String, dynamic>?> exportReport(String userId) async {
    try {
      return await _repository.exportRecommendationsReport(userId);
    } catch (e) {
      _setError('Error exportando reporte: ${e.toString()}');
      return null;
    }
  }

  // Eliminar recomendaciones
  Future<bool> deleteRecommendations(String recommendationId) async {
    try {
      await _repository.deleteRecommendations(recommendationId);

      // Actualizar listas locales
      _recommendationsHistory.removeWhere((r) => r.id == recommendationId);

      if (_currentRecommendations?.id == recommendationId) {
        _currentRecommendations = _recommendationsHistory.isNotEmpty
            ? _recommendationsHistory.first
            : null;
      }

      notifyListeners();
      return true;

    } catch (e) {
      _setError('Error eliminando recomendaciones: ${e.toString()}');
      return false;
    }
  }

  // Buscar recomendaciones similares
  Future<List<PersonalizedRecommendationsModel>> findSimilarRecommendations({
    required String userId,
    required String category,
    int limit = 5,
  }) async {
    try {
      return await _repository.findSimilarRecommendations(
        userId: userId,
        category: category,
        limit: limit,
      );
    } catch (e) {
      print('Error buscando recomendaciones similares: $e');
      return [];
    }
  }

  // Verificar si necesita nuevas recomendaciones
  Future<bool> checkNeedsUpdate(String userId) async {
    try {
      return await _repository.needsNewRecommendations(userId);
    } catch (e) {
      return true;
    }
  }

  // Métodos de estado
  void _setState(RecommendationsState state) {
    _state = state;
    notifyListeners();
  }

  void _setProgress(double progress) {
    _generationProgress = progress;
    notifyListeners();
  }

  void _setError(String error) {
    _state = RecommendationsState.error;
    _errorMessage = error;
    _generationProgress = 0.0;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_state == RecommendationsState.error) {
      _state = _currentRecommendations != null
          ? RecommendationsState.loaded
          : RecommendationsState.initial;
    }
  }

  // Limpiar error manualmente
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Reset completo
  void reset() {
    _state = RecommendationsState.initial;
    _currentRecommendations = null;
    _recommendationsHistory.clear();
    _userPreferences = null;
    _errorMessage = null;
    _generationProgress = 0.0;
    _followingStats.clear();
    _personalTrends.clear();
    notifyListeners();
  }
}