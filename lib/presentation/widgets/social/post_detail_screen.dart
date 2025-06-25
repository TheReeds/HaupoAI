import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:huapoai/presentation/widgets/social/post_card.dart';

import '../../../data/models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Mostrar opciones del post
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PostCard(
              post: post,
              onLike: () {
                // TODO: Implementar like
              },
              onComment: () {
                // TODO: Mostrar comentarios
              },
              onShare: () {
                // TODO: Compartir
              },
            ),
            const SizedBox(height: 16),
            // Aquí podrían ir posts relacionados
          ],
        ),
      ),
    );
  }
}