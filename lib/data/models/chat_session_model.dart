import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSessionModel {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;
  final Map<String, dynamic>? userContext; // Contexto del usuario en esta sesión

  ChatSessionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.messageCount = 0,
    this.userContext,
  });

  factory ChatSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Nueva conversación',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      messageCount: data['messageCount'] ?? 0,
      userContext: data['userContext'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'messageCount': messageCount,
      'userContext': userContext,
    };
  }

  ChatSessionModel copyWith({
    String? title,
    DateTime? lastMessageAt,
    int? messageCount,
  }) {
    return ChatSessionModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      userContext: userContext,
    );
  }
}