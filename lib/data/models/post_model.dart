// lib/data/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final String description;
  final List<String> imageUrls;
  final List<String> tags;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.description,
    this.imageUrls = const [],
    this.tags = const [],
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByCurrentUser = false,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc, {String? currentUserId}) {
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);

    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoURL: data['userPhotoURL'],
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likesCount: likes.length,
      commentsCount: data['commentsCount'] ?? 0,
      isLikedByCurrentUser: currentUserId != null ? likes.contains(currentUserId) : false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'description': description,
      'imageUrls': imageUrls,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': [], // Se maneja por separado
      'commentsCount': commentsCount,
    };
  }

  PostModel copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLikedByCurrentUser,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      userName: userName,
      userPhotoURL: userPhotoURL,
      description: description,
      imageUrls: imageUrls,
      tags: tags,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}

// lib/data/models/comment_model.dart
class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoURL: data['userPhotoURL'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// lib/data/models/health_tip_model.dart
class HealthTipModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'diet', 'exercise', 'lifestyle', 'skincare'
  final String? imageUrl;
  final List<String> tags;
  final String targetBodyType; // 'all', 'ectomorph', 'mesomorph', 'endomorph'
  final DateTime createdAt;
  final bool isPersonalized;

  HealthTipModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    this.tags = const [],
    this.targetBodyType = 'all',
    required this.createdAt,
    this.isPersonalized = false,
  });

  factory HealthTipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthTipModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      targetBodyType: data['targetBodyType'] ?? 'all',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPersonalized: data['isPersonalized'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'tags': tags,
      'targetBodyType': targetBodyType,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPersonalized': isPersonalized,
    };
  }
}