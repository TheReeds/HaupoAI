// lib/data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'dart:io';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Actualizar información del usuario
  Future<UserModel> updateUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toFirestore());

    return user;
  }

  // Actualizar onboarding status
  Future<UserModel> updateOnboardingStatus(String userId, bool completed) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'isOnboardingCompleted': completed});

    // Obtener el documento actualizado
    final doc = await _firestore.collection('users').doc(userId).get();
    return UserModel.fromFirestore(doc);
  }

  // Subir foto de perfil
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      // Crear referencia al archivo
      final ref = _storage
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

      // Subir archivo
      final uploadTask = await ref.putFile(imageFile);

      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir la foto: $e');
    }
  }

  // Actualizar foto de perfil
  Future<UserModel> updateProfilePhoto(String userId, File imageFile) async {
    try {
      // Subir la nueva imagen
      final photoURL = await uploadProfilePhoto(userId, imageFile);

      // Actualizar en Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updatePhotoURL(photoURL);
        await currentUser.reload();
      }

      // Actualizar en Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'photoURL': photoURL});

      // Obtener el documento actualizado
      final doc = await _firestore.collection('users').doc(userId).get();
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error al actualizar la foto de perfil: $e');
    }
  }

  // Actualizar display name
  Future<UserModel> updateDisplayName(String userId, String displayName) async {
    try {
      // Actualizar en Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(displayName);
        await currentUser.reload();
      }

      // Actualizar en Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'displayName': displayName});

      // Obtener el documento actualizado
      final doc = await _firestore.collection('users').doc(userId).get();
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error al actualizar el nombre: $e');
    }
  }

  // Obtener usuario por ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  // Stream del usuario
  Stream<UserModel?> userStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }
}