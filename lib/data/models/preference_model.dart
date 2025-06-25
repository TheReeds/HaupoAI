// lib/data/models/preference_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PreferenceModel {
  final String userId;
  final String? gender;
  final String? skinTone;
  final List<String> favoriteColors;
  final List<String> favoriteStyles;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PreferenceModel({
    required this.userId,
    this.gender,
    this.skinTone,
    this.favoriteColors = const [],
    this.favoriteStyles = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // Crear desde Firestore
  factory PreferenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PreferenceModel(
      userId: doc.id,
      gender: data['gender'],
      skinTone: data['skinTone'],
      favoriteColors: List<String>.from(data['favoriteColors'] ?? []),
      favoriteStyles: List<String>.from(data['favoriteStyles'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'gender': gender,
      'skinTone': skinTone,
      'favoriteColors': favoriteColors,
      'favoriteStyles': favoriteStyles,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : null,
    };
  }

  // Copiar con cambios
  PreferenceModel copyWith({
    String? gender,
    String? skinTone,
    List<String>? favoriteColors,
    List<String>? favoriteStyles,
    DateTime? updatedAt,
  }) {
    return PreferenceModel(
      userId: userId,
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      favoriteColors: favoriteColors ?? this.favoriteColors,
      favoriteStyles: favoriteStyles ?? this.favoriteStyles,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Crear desde formulario de setup
  factory PreferenceModel.fromSetup({
    required String userId,
    String? gender,
    String? skinTone,
    Set<String>? selectedColors,
    Set<String>? selectedStyles,
  }) {
    return PreferenceModel(
      userId: userId,
      gender: gender,
      skinTone: skinTone,
      favoriteColors: selectedColors?.toList() ?? [],
      favoriteStyles: selectedStyles?.toList() ?? [],
      createdAt: DateTime.now(),
    );
  }
}