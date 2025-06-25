// lib/data/models/auth_result.dart
import 'package:huapoai/data/models/user_model.dart';

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;
  final bool isNewUser;

  AuthResult({
    required this.isSuccess,
    this.user,
    this.error,
    this.isNewUser = false,
  });

  factory AuthResult.success(UserModel user, {bool isNewUser = false}) {
    return AuthResult(
      isSuccess: true,
      user: user,
      isNewUser: isNewUser,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult(
      isSuccess: false,
      error: error,
    );
  }
}