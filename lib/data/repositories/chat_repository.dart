// lib/data/repositories/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../models/transformation_post_model.dart';
import '../models/color_palette_model.dart';
import 'dart:io';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============ CHAT SESSIONS ============

  // Crear nueva sesión de chat
  Future<String> createChatSession(String userId, String title, Map<String, dynamic>? userContext) async {
    final session = ChatSessionModel(
      id: '',
      userId: userId,
      title: title,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      userContext: userContext,
    );

    final docRef = await _firestore.collection('chat_sessions').add(session.toFirestore());
    return docRef.id;
  }

  // Obtener sesiones de chat del usuario
  Stream<List<ChatSessionModel>> getUserChatSessions(String userId) {
    return _firestore
        .collection('chat_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatSessionModel.fromFirestore(doc))
        .toList());
  }

  // Actualizar sesión de chat
  Future<void> updateChatSession(String sessionId, {
    String? title,
    DateTime? lastMessageAt,
    int? messageCount,
  }) async {
    final updateData = <String, dynamic>{};
    if (title != null) updateData['title'] = title;
    if (lastMessageAt != null) updateData['lastMessageAt'] = Timestamp.fromDate(lastMessageAt);
    if (messageCount != null) updateData['messageCount'] = messageCount;

    await _firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .update(updateData);
  }

  // ============ CHAT MESSAGES ============

  // Guardar mensaje en Firestore
  Future<String> saveChatMessage(String sessionId, ChatMessageModel message) async {
    final docRef = await _firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .add(message.toFirestore());

    // Actualizar última actividad de la sesión
    await updateChatSession(
      sessionId,
      lastMessageAt: message.timestamp,
    );

    return docRef.id;
  }

  // Stream de mensajes de una sesión
  Stream<List<ChatMessageModel>> getChatMessages(String sessionId) {
    return _firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList());
  }

  // Obtener últimos mensajes para contexto
  Future<List<Map<String, String>>> getRecentMessagesForContext(String sessionId, int limit) async {
    final snapshot = await _firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.reversed.map((doc) {
      final data = doc.data();
      return {
        'role': data['sender'] == 'user' ? 'user' : 'assistant',
        'content': data['content'] as String,
      };
    }).toList();
  }

  // ============ TRANSFORMATION POSTS ============

  // Crear post de transformación
  Future<String> createTransformationPost({
    required String userId,
    required String userName,
    String? userPhotoURL,
    required String title,
    required String description,
    required File beforeImage,
    required File afterImage,
    required String transformationType,
    List<String> tags = const [],
    Map<String, dynamic>? analyticsData,
  }) async {
    try {
      // Subir imágenes
      final beforeImageUrl = await _uploadTransformationImage(
          userId,
          beforeImage,
          'before_${DateTime.now().millisecondsSinceEpoch}'
      );

      final afterImageUrl = await _uploadTransformationImage(
          userId,
          afterImage,
          'after_${DateTime.now().millisecondsSinceEpoch}'
      );

      // Crear post
      final post = TransformationPostModel(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoURL: userPhotoURL,
        title: title,
        description: description,
        beforeImageUrl: beforeImageUrl,
        afterImageUrl: afterImageUrl,
        transformationType: transformationType,
        tags: tags,
        createdAt: DateTime.now(),
        analyticsData: analyticsData,
      );

      final docRef = await _firestore
          .collection('transformation_posts')
          .add(post.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear post de transformación: $e');
    }
  }

  // Subir imagen de transformación
  Future<String> _uploadTransformationImage(String userId, File imageFile, String fileName) async {
    final ref = _storage.ref().child('transformations/$userId/$fileName.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  // Obtener feed de transformaciones
  Stream<List<TransformationPostModel>> getTransformationsFeed({
    String? currentUserId,
    String? transformationType,
    int limit = 20,
  }) {
    Query query = _firestore.collection('transformation_posts');

    if (transformationType != null) {
      query = query.where('transformationType', isEqualTo: transformationType);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransformationPostModel.fromFirestore(doc, currentUserId: currentUserId))
        .toList());
  }

  // Obtener transformaciones de un usuario
  Stream<List<TransformationPostModel>> getUserTransformations(String userId, {String? currentUserId}) {
    return _firestore
        .collection('transformation_posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransformationPostModel.fromFirestore(doc, currentUserId: currentUserId))
        .toList());
  }

  // Toggle like en transformación
  Future<void> toggleTransformationLike(String postId, String userId) async {
    final postRef = _firestore.collection('transformation_posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) throw Exception('Post no encontrado');

      final likes = List<String>.from(postDoc.data()!['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      transaction.update(postRef, {'likes': likes});
    });
  }

  // ============ COLOR PALETTES ============

  // Guardar paleta de colores
  Future<String> saveColorPalette(ColorPaletteModel palette) async {
    final docRef = await _firestore
        .collection('color_palettes')
        .add(palette.toFirestore());
    return docRef.id;
  }

  // Obtener paletas del usuario
  Stream<List<ColorPaletteModel>> getUserColorPalettes(String userId) {
    return _firestore
        .collection('color_palettes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ColorPaletteModel.fromFirestore(doc))
        .toList());
  }

  // Obtener paleta más reciente del usuario
  Future<ColorPaletteModel?> getLatestUserColorPalette(String userId) async {
    final snapshot = await _firestore
        .collection('color_palettes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ColorPaletteModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // ============ ANALYTICS Y BÚSQUEDA ============

  // Buscar transformaciones por tipo
  Future<List<TransformationPostModel>> searchTransformationsByType(
      String transformationType,
      {String? currentUserId}
      ) async {
    final snapshot = await _firestore
        .collection('transformation_posts')
        .where('transformationType', isEqualTo: transformationType)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => TransformationPostModel.fromFirestore(doc, currentUserId: currentUserId))
        .toList();
  }

  // Obtener transformaciones populares
  Future<List<TransformationPostModel>> getPopularTransformations({String? currentUserId}) async {
    // Por ahora ordenamos por fecha, pero podrías implementar un sistema de popularidad
    final snapshot = await _firestore
        .collection('transformation_posts')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => TransformationPostModel.fromFirestore(doc, currentUserId: currentUserId))
        .toList();
  }

  // Eliminar sesión de chat
  Future<void> deleteChatSession(String sessionId) async {
    // Eliminar todos los mensajes primero
    final messagesSnapshot = await _firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Eliminar la sesión
    batch.delete(_firestore.collection('chat_sessions').doc(sessionId));

    await batch.commit();
  }

  // Obtener estadísticas de chat del usuario
  Future<Map<String, dynamic>> getChatStats(String userId) async {
    final sessionsSnapshot = await _firestore
        .collection('chat_sessions')
        .where('userId', isEqualTo: userId)
        .get();

    int totalSessions = sessionsSnapshot.docs.length;
    int totalMessages = 0;

    for (final sessionDoc in sessionsSnapshot.docs) {
      final messagesSnapshot = await sessionDoc.reference
          .collection('messages')
          .get();
      totalMessages += messagesSnapshot.docs.length;
    }

    return {
      'totalSessions': totalSessions,
      'totalMessages': totalMessages,
      'averageMessagesPerSession': totalSessions > 0 ? totalMessages / totalSessions : 0,
    };
  }

  // Limpiar chats antiguos (utilidad de mantenimiento)
  Future<void> cleanupOldChats(String userId, {int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    final oldSessionsSnapshot = await _firestore
        .collection('chat_sessions')
        .where('userId', isEqualTo: userId)
        .where('lastMessageAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _firestore.batch();

    for (final sessionDoc in oldSessionsSnapshot.docs) {
      // Eliminar mensajes de la sesión
      final messagesSnapshot = await sessionDoc.reference
          .collection('messages')
          .get();

      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      // Eliminar la sesión
      batch.delete(sessionDoc.reference);
    }

    if (oldSessionsSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}