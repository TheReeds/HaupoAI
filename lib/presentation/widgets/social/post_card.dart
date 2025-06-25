// lib/presentation/widgets/social/post_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/social_repository.dart';
import '../../providers/auth_provider.dart';
import '../../screens/social/image_gallery_screen.dart';
import 'comments_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  final SocialRepository _socialRepository = SocialRepository();
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser;
    _likesCount = widget.post.likesCount;

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    // Animación de like
    if (_isLiked) {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }

    try {
      await _socialRepository.toggleLike(widget.post.id, userId);
    } catch (e) {
      // Revertir cambios si hay error
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al dar like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del post
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post.userPhotoURL != null
                      ? CachedNetworkImageProvider(widget.post.userPhotoURL!)
                      : null,
                  child: widget.post.userPhotoURL == null
                      ? Text(
                    widget.post.userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTime(widget.post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(context),
                ),
              ],
            ),
          ),

          // Descripción
          if (widget.post.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          // Imágenes
          if (widget.post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildImageCarousel(),
          ],

          // Tags
          if (widget.post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: widget.post.tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
          ],

          // Acciones
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Botón de like con animación
                AnimatedBuilder(
                  animation: _likeAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _likeAnimation.value,
                      child: IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : null,
                        ),
                        onPressed: _toggleLike,
                      ),
                    );
                  },
                ),
                Text(
                  '$_likesCount',
                  style: TextStyle(
                    fontWeight: _likesCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 16),

                // Botón de comentarios
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: _showComments,
                ),
                Text('${widget.post.commentsCount}'),

                const Spacer(),

                // Botón de compartir
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: widget.onShare ?? _sharePost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.post.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _showImageFullScreen(0),
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrls.first,
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Icon(Icons.error),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: widget.post.imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showImageFullScreen(index),
            child: CachedNetworkImage(
              imageUrl: widget.post.imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.error),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageFullScreen(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
          imageUrls: widget.post.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.currentUserId == widget.post.userId) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar editar
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Reportar'),
                onTap: () {
                  Navigator.pop(context);
                  _reportPost();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copiar enlace'),
              onTap: () {
                Navigator.pop(context);
                _copyLink();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar eliminación
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función de eliminar próximamente')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _reportPost() {
    // TODO: Implementar reportar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de reportar próximamente')),
    );
  }

  void _copyLink() {
    // TODO: Implementar copiar enlace
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado al portapapeles')),
    );
  }

  void _sharePost() {
    // TODO: Implementar compartir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de compartir próximamente')),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
