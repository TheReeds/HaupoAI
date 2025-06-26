// lib/presentation/widgets/social/transformation_card.dart
import 'package:flutter/material.dart';
import '../../../data/models/transformation_post_model.dart';

class TransformationCard extends StatefulWidget {
  final TransformationPostModel transformation;
  final bool isCompact;
  final VoidCallback? onTap;

  const TransformationCard({
    super.key,
    required this.transformation,
    this.isCompact = false,
    this.onTap,
  });

  @override
  State<TransformationCard> createState() => _TransformationCardState();
}

class _TransformationCardState extends State<TransformationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _showBefore = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleImage() {
    setState(() {
      _showBefore = !_showBefore;
    });

    if (_showBefore) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: widget.isCompact ? 2 : 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 16),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del usuario
            if (!widget.isCompact) _buildUserHeader(context),

            // Imagen de transformación con animación
            _buildTransformationImage(context),

            // Contenido
            Padding(
              padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    widget.transformation.title,
                    style: widget.isCompact
                        ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )
                        : theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: widget.isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (!widget.isCompact) ...[
                    const SizedBox(height: 8),
                    // Descripción
                    Text(
                      widget.transformation.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Tags
                    _buildTags(context),
                    const SizedBox(height: 12),

                    // Acciones
                    _buildActions(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.transformation.userPhotoURL != null
                ? NetworkImage(widget.transformation.userPhotoURL!)
                : null,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: widget.transformation.userPhotoURL == null
                ? Text(
              widget.transformation.userName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.transformation.userName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getTransformationTypeText(widget.transformation.transformationType),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Tiempo transcurrido
          Text(
            _getTimeAgo(widget.transformation.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformationImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Contenedor de las imágenes
        Container(
          height: widget.isCompact ? 160 : 250,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(widget.isCompact ? 12 : 16),
              bottom: widget.isCompact
                  ? Radius.zero
                  : const Radius.circular(8),
            ),
          ),
          child: Stack(
            children: [
              // Imagen "Antes"
              AnimatedOpacity(
                opacity: _showBefore ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.transformation.beforeImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Imagen "Después"
              AnimatedOpacity(
                opacity: _showBefore ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.transformation.afterImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Overlay con efecto de deslizamiento
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * _slideAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.transformation.afterImageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Indicadores de "Antes" y "Después"
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _showBefore
                  ? colorScheme.error.withOpacity(0.9)
                  : colorScheme.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _showBefore ? 'ANTES' : 'DESPUÉS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // Botón de toggle
        Positioned(
          bottom: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleImage,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // Indicador de deslizamiento
        if (!widget.isCompact)
          Positioned(
            bottom: 40,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swipe_left_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Desliza para comparar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.transformation.tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: widget.transformation.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Like
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.transformation.isLikedByCurrentUser
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: widget.transformation.isLikedByCurrentUser
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.transformation.likesCount}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Comentarios
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.transformation.commentsCount}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Compartir
        Icon(
          Icons.share_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ],
    );
  }

  String _getTransformationTypeText(String type) {
    switch (type) {
      case 'haircut':
        return 'Transformación de cabello';
      case 'outfit':
        return 'Cambio de look';
      case 'makeup':
        return 'Transformación de maquillaje';
      case 'weight':
        return 'Transformación física';
      case 'style':
        return 'Cambio de estilo';
      default:
        return 'Transformación';
    }
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}