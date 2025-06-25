// lib/data/repositories/preference_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/preference_model.dart';

class PreferenceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guardar preferencias
  Future<void> savePreferences(PreferenceModel preferences) async {
    await _firestore
        .collection('user_preferences')
        .doc(preferences.userId)
        .set(preferences.toFirestore());
  }

  // Obtener preferencias de un usuario
  Future<PreferenceModel?> getPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(userId)
          .get();

      if (doc.exists) {
        return PreferenceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener preferencias: $e');
    }
  }

  // Actualizar preferencias
  Future<void> updatePreferences(PreferenceModel preferences) async {
    final updatedPreferences = preferences.copyWith(
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('user_preferences')
        .doc(preferences.userId)
        .update(updatedPreferences.toFirestore());
  }

  // Eliminar preferencias
  Future<void> deletePreferences(String userId) async {
    await _firestore
        .collection('user_preferences')
        .doc(userId)
        .delete();
  }

  // Stream de preferencias (para actualizaciones en tiempo real)
  Stream<PreferenceModel?> preferencesStream(String userId) {
    return _firestore
        .collection('user_preferences')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return PreferenceModel.fromFirestore(doc);
      }
      return null;
    });
  }
}