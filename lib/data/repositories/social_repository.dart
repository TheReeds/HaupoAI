// lib/data/repositories/social_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
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

  // Obtener feed de posts con datos de usuario actualizados
  Stream<List<PostModel>> getPostsFeed({String? currentUserId, int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {

      List<PostModel> posts = [];

      for (var doc in snapshot.docs) {
        try {
          // Crear post básico desde Firestore
          PostModel post = PostModel.fromFirestore(doc, currentUserId: currentUserId);

          // Obtener datos actualizados del usuario
          UserModel? userData = await _getUserData(post.userId);

          if (userData != null) {
            // Actualizar datos del usuario en el post
            post = PostModel(
              id: post.id,
              userId: post.userId,
              userName: userData.displayName ?? post.userName,
              userPhotoURL: userData.photoURL,
              description: post.description,
              imageUrls: post.imageUrls,
              tags: post.tags,
              createdAt: post.createdAt,
              likesCount: post.likesCount,
              commentsCount: post.commentsCount,
              isLikedByCurrentUser: post.isLikedByCurrentUser,
            );
          }

          posts.add(post);
        } catch (e) {
          print('Error procesando post ${doc.id}: $e');
          // Si hay error, agregar el post sin actualizar datos de usuario
          posts.add(PostModel.fromFirestore(doc, currentUserId: currentUserId));
        }
      }

      return posts;
    });
  }

  // Obtener posts de un usuario específico
  Stream<List<PostModel>> getUserPosts(String userId, {String? currentUserId}) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {

      List<PostModel> posts = [];
      UserModel? userData = await _getUserData(userId);

      for (var doc in snapshot.docs) {
        try {
          PostModel post = PostModel.fromFirestore(doc, currentUserId: currentUserId);

          if (userData != null) {
            post = PostModel(
              id: post.id,
              userId: post.userId,
              userName: userData.displayName ?? post.userName,
              userPhotoURL: userData.photoURL,
              description: post.description,
              imageUrls: post.imageUrls,
              tags: post.tags,
              createdAt: post.createdAt,
              likesCount: post.likesCount,
              commentsCount: post.commentsCount,
              isLikedByCurrentUser: post.isLikedByCurrentUser,
            );
          }

          posts.add(post);
        } catch (e) {
          print('Error procesando post ${doc.id}: $e');
          posts.add(PostModel.fromFirestore(doc, currentUserId: currentUserId));
        }
      }

      return posts;
    });
  }

  // Método auxiliar para obtener datos del usuario
  Future<UserModel?> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
    } catch (e) {
      print('Error obteniendo datos de usuario $userId: $e');
    }
    return null;
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

  // Agregar comentario con datos actualizados del usuario
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoURL,
    required String content,
  }) async {

    // Obtener datos actualizados del usuario
    UserModel? userData = await _getUserData(userId);

    final comment = CommentModel(
      id: '',
      postId: postId,
      userId: userId,
      userName: userData?.displayName ?? userName,
      userPhotoURL: userData?.photoURL ?? userPhotoURL,
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

  // Obtener comentarios de un post con datos actualizados
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {

      List<CommentModel> comments = [];

      for (var doc in snapshot.docs) {
        try {
          CommentModel comment = CommentModel.fromFirestore(doc);

          // Obtener datos actualizados del usuario
          UserModel? userData = await _getUserData(comment.userId);

          if (userData != null) {
            comment = CommentModel(
              id: comment.id,
              postId: comment.postId,
              userId: comment.userId,
              userName: userData.displayName ?? comment.userName,
              userPhotoURL: userData.photoURL,
              content: comment.content,
              createdAt: comment.createdAt,
            );
          }

          comments.add(comment);
        } catch (e) {
          print('Error procesando comentario ${doc.id}: $e');
          comments.add(CommentModel.fromFirestore(doc));
        }
      }

      return comments;
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

  // Buscar posts por tags con datos actualizados
  Future<List<PostModel>> searchPostsByTags(List<String> tags, {String? currentUserId}) async {
    Query query = _firestore.collection('posts');

    if (tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    final snapshot = await query
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    List<PostModel> posts = [];

    for (var doc in snapshot.docs) {
      try {
        PostModel post = PostModel.fromFirestore(doc, currentUserId: currentUserId);

        // Obtener datos actualizados del usuario
        UserModel? userData = await _getUserData(post.userId);

        if (userData != null) {
          post = PostModel(
            id: post.id,
            userId: post.userId,
            userName: userData.displayName ?? post.userName,
            userPhotoURL: userData.photoURL,
            description: post.description,
            imageUrls: post.imageUrls,
            tags: post.tags,
            createdAt: post.createdAt,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            isLikedByCurrentUser: post.isLikedByCurrentUser,
          );
        }

        posts.add(post);
      } catch (e) {
        print('Error procesando post ${doc.id}: $e');
        posts.add(PostModel.fromFirestore(doc, currentUserId: currentUserId));
      }
    }

    return posts;
  }

  // Buscar posts por descripción
  Future<List<PostModel>> searchPostsByDescription(String searchTerm, {String? currentUserId}) async {
    // Para búsqueda de texto completo, considera usar Algolia o similar en producción
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    List<PostModel> posts = [];

    for (var doc in snapshot.docs) {
      try {
        PostModel post = PostModel.fromFirestore(doc, currentUserId: currentUserId);

        if (post.description.toLowerCase().contains(searchTerm.toLowerCase())) {
          // Obtener datos actualizados del usuario
          UserModel? userData = await _getUserData(post.userId);

          if (userData != null) {
            post = PostModel(
              id: post.id,
              userId: post.userId,
              userName: userData.displayName ?? post.userName,
              userPhotoURL: userData.photoURL,
              description: post.description,
              imageUrls: post.imageUrls,
              tags: post.tags,
              createdAt: post.createdAt,
              likesCount: post.likesCount,
              commentsCount: post.commentsCount,
              isLikedByCurrentUser: post.isLikedByCurrentUser,
            );
          }

          posts.add(post);
        }
      } catch (e) {
        print('Error procesando post ${doc.id}: $e');
      }
    }

    return posts;
  }

  // Actualizar todos los posts de un usuario cuando cambia su perfil
  Future<void> updateUserDataInPosts(String userId, String? newDisplayName, String? newPhotoURL) async {
    try {
      final batch = _firestore.batch();

      // Obtener todos los posts del usuario
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      // Actualizar cada post
      for (var doc in postsSnapshot.docs) {
        final updateData = <String, dynamic>{};
        if (newDisplayName != null) {
          updateData['userName'] = newDisplayName;
        }
        if (newPhotoURL != null) {
          updateData['userPhotoURL'] = newPhotoURL;
        }

        if (updateData.isNotEmpty) {
          batch.update(doc.reference, updateData);
        }
      }

      // Obtener todos los comentarios del usuario
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();

      // Actualizar cada comentario
      for (var doc in commentsSnapshot.docs) {
        final updateData = <String, dynamic>{};
        if (newDisplayName != null) {
          updateData['userName'] = newDisplayName;
        }
        if (newPhotoURL != null) {
          updateData['userPhotoURL'] = newPhotoURL;
        }

        if (updateData.isNotEmpty) {
          batch.update(doc.reference, updateData);
        }
      }

      await batch.commit();
      print('Datos de usuario actualizados en posts y comentarios');
    } catch (e) {
      print('Error actualizando datos de usuario: $e');
    }
  }
}