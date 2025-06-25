// lib/core/errors/exceptions.dart

class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  AuthException(String message, {String? code}) : super(message, code: code);
}

class NetworkException extends AppException {
  NetworkException(String message, {String? code}) : super(message, code: code);
}

class StorageException extends AppException {
  StorageException(String message, {String? code}) : super(message, code: code);
}

class ValidationException extends AppException {
  ValidationException(String message, {String? code}) : super(message, code: code);
}