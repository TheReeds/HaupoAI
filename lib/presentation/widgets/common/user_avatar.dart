// lib/presentation/widgets/common/user_avatar.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final String? displayName;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.photoURL,
    this.displayName,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: _buildAvatarContent(context),
    );

    final avatarWithBorder = showBorder
        ? Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: avatar,
    )
        : avatar;

    return onTap != null
        ? GestureDetector(
      onTap: onTap,
      child: avatarWithBorder,
    )
        : avatarWithBorder;
  }

  Widget _buildAvatarContent(BuildContext context) {
    if (photoURL != null && photoURL!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoURL!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(context),
          errorWidget: (context, url, error) => _buildInitials(context),
          // Forzar renovación del caché añadiendo timestamp
          cacheKey: '${photoURL}_${DateTime.now().millisecondsSinceEpoch ~/ 300000}', // Cache por 5 minutos
        ),
      );
    } else {
      return _buildInitials(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: radius * 0.6,
          height: radius * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(BuildContext context) {
    final initials = _getInitials();
    final fontSize = radius * 0.6;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0].substring(0, 1).toUpperCase();
      }
    }
    return 'U';
  }
}

// lib/presentation/widgets/common/refreshable_user_avatar.dart
class RefreshableUserAvatar extends StatefulWidget {
  final String? photoURL;
  final String? displayName;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTap;

  const RefreshableUserAvatar({
    super.key,
    this.photoURL,
    this.displayName,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor,
    this.onTap,
  });

  @override
  State<RefreshableUserAvatar> createState() => _RefreshableUserAvatarState();
}

class _RefreshableUserAvatarState extends State<RefreshableUserAvatar> {
  String? _cachedPhotoURL;

  @override
  void initState() {
    super.initState();
    _cachedPhotoURL = widget.photoURL;
  }

  @override
  void didUpdateWidget(RefreshableUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Forzar actualización si la URL cambió
    if (oldWidget.photoURL != widget.photoURL) {
      setState(() {
        _cachedPhotoURL = widget.photoURL;
      });
      // Limpiar caché de la imagen anterior
      if (oldWidget.photoURL != null) {
        CachedNetworkImage.evictFromCache(oldWidget.photoURL!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      photoURL: _cachedPhotoURL,
      displayName: widget.displayName,
      radius: widget.radius,
      showBorder: widget.showBorder,
      borderColor: widget.borderColor,
      onTap: widget.onTap,
    );
  }
}