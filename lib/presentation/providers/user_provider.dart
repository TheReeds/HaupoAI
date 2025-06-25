// lib/presentation/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Actualizar usuario
  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Limpiar usuario
  void clearUser() {
    _user = null;
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