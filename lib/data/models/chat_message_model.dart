// lib/data/models/chat_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String userId;
  final String content;
  final String sender; // 'user' o 'assistant'
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
    this.metadata,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      sender: data['sender'] ?? 'user',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'sender': sender,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  // Crear mensaje del usuario
  factory ChatMessageModel.user({
    required String userId,
    required String content,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: '',
      userId: userId,
      content: content,
      sender: 'user',
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      metadata: metadata,
    );
  }

  // Crear mensaje del asistente
  factory ChatMessageModel.assistant({
    required String userId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: '',
      userId: userId,
      content: content,
      sender: 'assistant',
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }
}
