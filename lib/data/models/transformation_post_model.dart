import 'package:cloud_firestore/cloud_firestore.dart';

class TransformationPostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final String title;
  final String description;
  final String beforeImageUrl;
  final String afterImageUrl;
  final List<String> tags;
  final String transformationType; // 'haircut', 'outfit', 'makeup', 'weight', 'style'
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final Map<String, dynamic>? analyticsData; // Datos del análisis de transformación

  TransformationPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.title,
    required this.description,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.tags = const [],
    required this.transformationType,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByCurrentUser = false,
    this.analyticsData,
  });

  factory TransformationPostModel.fromFirestore(DocumentSnapshot doc, {String? currentUserId}) {
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);

    return TransformationPostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoURL: data['userPhotoURL'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      beforeImageUrl: data['beforeImageUrl'] ?? '',
      afterImageUrl: data['afterImageUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      transformationType: data['transformationType'] ?? 'style',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likesCount: likes.length,
      commentsCount: data['commentsCount'] ?? 0,
      isLikedByCurrentUser: currentUserId != null ? likes.contains(currentUserId) : false,
      analyticsData: data['analyticsData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'title': title,
      'description': description,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'tags': tags,
      'transformationType': transformationType,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': [], // Se maneja por separado
      'commentsCount': commentsCount,
      'analyticsData': analyticsData,
    };
  }

  TransformationPostModel copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLikedByCurrentUser,
  }) {
    return TransformationPostModel(
      id: id,
      userId: userId,
      userName: userName,
      userPhotoURL: userPhotoURL,
      title: title,
      description: description,
      beforeImageUrl: beforeImageUrl,
      afterImageUrl: afterImageUrl,
      tags: tags,
      transformationType: transformationType,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      analyticsData: analyticsData,
    );
  }
}