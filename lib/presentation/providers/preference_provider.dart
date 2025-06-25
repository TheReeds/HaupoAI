// lib/presentation/providers/preference_provider.dart
import 'package:flutter/cupertino.dart';

class PreferenceProvider extends ChangeNotifier {
  Map<String, dynamic>? _preferences;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Actualizar preferencias
  void updatePreferences(Map<String, dynamic> preferences) {
    _preferences = preferences;
    notifyListeners();
  }

  // Limpiar preferencias
  void clearPreferences() {
    _preferences = null;
    notifyListeners();
  }

  // Set loading
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}