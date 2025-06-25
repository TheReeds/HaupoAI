// lib/data/repositories/social_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';
import 'dart:io';

class SocialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============ POSTS ============

  // Crear un nuevo post
  Future<String> createPost({
    required String userId,
    required String userName,
    String? userPhotoURL,
    required String description,
    required List<File> images,
    List<String> tags = const [],
  }) async {
    try {
      // Subir imágenes
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('posts/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final uploadTask = await ref.putFile(images[i]);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Crear post
      final post = PostModel(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoURL: userPhotoURL,
        description: description,
        imageUrls: imageUrls,
        tags: tags,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('posts').add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear post: $e');
    }
  }

  // Obtener feed de posts
  Stream<List<PostModel>> getPostsFeed({String? currentUserId, int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc, currentUserId: currentUserId))
          .toList();
    });
  }

  // Obtener posts de un usuario específico
  Stream<List<PostModel>> getUserPosts(String userId, {String? currentUserId}) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc, currentUserId: currentUserId))
          .toList();
    });
  }

  // Dar/quitar like a un post
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);

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

  // ============ COMENTARIOS ============

  // Agregar comentario
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoURL,
    required String content,
  }) async {
    final comment = CommentModel(
      id: '',
      postId: postId,
      userId: userId,
      userName: userName,
      userPhotoURL: userPhotoURL,
      content: content,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      // Agregar comentario
      final commentRef = _firestore.collection('comments').doc();
      transaction.set(commentRef, comment.toFirestore());

      // Incrementar contador de comentarios del post
      final postRef = _firestore.collection('posts').doc(postId);
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });
  }

  // Obtener comentarios de un post
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
    });
  }

  // ============ TIPS DE SALUD ============

  // Obtener tips de salud personalizados
  Future<List<HealthTipModel>> getHealthTips({
    String? bodyType,
    String? category,
    int limit = 10,
  }) async {
    Query query = _firestore.collection('health_tips');

    if (bodyType != null && bodyType != 'all') {
      query = query.where('targetBodyType', whereIn: ['all', bodyType]);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => HealthTipModel.fromFirestore(doc)).toList();
  }

  // Crear tip de salud personalizado (para admin o IA)
  Future<void> createHealthTip(HealthTipModel tip) async {
    await _firestore.collection('health_tips').add(tip.toFirestore());
  }

  // ============ BÚSQUEDA ============

  // Buscar posts por tags
  Future<List<PostModel>> searchPostsByTags(List<String> tags, {String? currentUserId}) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('tags', arrayContainsAny: tags)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc, currentUserId: currentUserId))
        .toList();
  }

  // Buscar posts por descripción
  Future<List<PostModel>> searchPostsByDescription(String searchTerm, {String? currentUserId}) async {
    // Nota: Firestore no tiene búsqueda de texto completo nativa
    // Para una implementación completa, considera usar Algolia o ElasticSearch
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final posts = snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc, currentUserId: currentUserId))
        .where((post) => post.description.toLowerCase().contains(searchTerm.toLowerCase()))
        .toList();

    return posts;
  }
}