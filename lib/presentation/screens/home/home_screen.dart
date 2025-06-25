// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.3),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'HuapoAI',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Notifications with badge
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: () {
                            // TODO: Implementar notificaciones
                          },
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile Menu
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'profile':
                                context.go('/profile');
                                break;
                              case 'logout':
                                _showLogoutDialog(context, authProvider);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      color: colorScheme.onSurface),
                                  const SizedBox(width: 12),
                                  const Text('Mi Perfil'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout_rounded,
                                      color: colorScheme.error),
                                  const SizedBox(width: 12),
                                  Text('Cerrar sesión',
                                      style: TextStyle(color: colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                          child: Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: authProvider.user?.photoURL != null
                                    ? NetworkImage(authProvider.user!.photoURL!)
                                    : null,
                                backgroundColor: colorScheme.primaryContainer,
                                child: authProvider.user?.photoURL == null
                                    ? Text(
                                  authProvider.user?.displayName
                                      ?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                    fontSize: 14,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Section
                          _buildWelcomeSection(context, authProvider),
                          const SizedBox(height: 32),

                          // Quick Actions
                          _buildQuickActions(context),
                          const SizedBox(height: 40),

                          // AI Analysis Section
                          _buildAnalysisSection(context),
                          const SizedBox(height: 32),

                          // Social Section
                          _buildSocialSection(context),
                          const SizedBox(height: 32),

                          // Health & Wellness
                          _buildHealthSection(context),
                          const SizedBox(height: 32),

                          // Daily Tip
                          _buildDailyTip(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-post'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Crear'),
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, ${authProvider.user?.displayName?.split(' ').first ?? 'Usuario'}! 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Descubre tu estilo perfecto con la ayuda de nuestra IA',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildQuickActionCard(
                context,
                'Análisis Facial',
                Icons.face_rounded,
                const Color(0xFF6366F1),
                    () => context.go('/face-analysis'),
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                context,
                'Análisis Corporal',
                Icons.accessibility_new_rounded,
                const Color(0xFF10B981),
                    () => context.go('/body-analysis'),
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                context,
                'Crear Post',
                Icons.add_photo_alternate_rounded,
                const Color(0xFFF59E0B),
                    () => context.go('/create-post'),
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                context,
                'Descubrir',
                Icons.explore_rounded,
                const Color(0xFFEF4444),
                    () => context.go('/discover'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(BuildContext context) {
    return _buildSection(
      context,
      'Análisis con IA',
      'Descubre tu mejor versión',
      Icons.psychology_rounded,
      const Color(0xFF8B5CF6),
      [
        _buildModernCard(
          context,
          'Análisis Facial',
          'Encuentra tu corte perfecto',
          Icons.face_rounded,
          const Color(0xFF3B82F6),
              () => context.go('/face-analysis'),
        ),
        _buildModernCard(
          context,
          'Análisis Corporal',
          'Descubre tu estilo ideal',
          Icons.accessibility_new_rounded,
          const Color(0xFF10B981),
              () => context.go('/body-analysis'),
        ),
      ],
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    return _buildSection(
      context,
      'Comunidad',
      'Conecta y comparte tu estilo',
      Icons.people_rounded,
      const Color(0xFFEC4899),
      [
        _buildModernCard(
          context,
          'Feed',
          'Explora looks increíbles',
          Icons.home_rounded,
          const Color(0xFF8B5CF6),
              () => context.go('/feed'),
        ),
        _buildModernCard(
          context,
          'Descubrir',
          'Encuentra inspiración',
          Icons.explore_rounded,
          const Color(0xFFF59E0B),
              () => context.go('/discover'),
        ),
      ],
    );
  }

  Widget _buildHealthSection(BuildContext context) {
    return _buildSection(
      context,
      'Bienestar',
      'Consejos personalizados para ti',
      Icons.favorite_rounded,
      const Color(0xFFEF4444),
      [
        _buildModernCard(
          context,
          'Consejos IA',
          'Recomendaciones únicas',
          Icons.lightbulb_rounded,
          const Color(0xFFF59E0B),
              () => context.go('/health-tips'),
        ),
        _buildModernCard(
          context,
          'Mi Progreso',
          'Seguimiento personal',
          Icons.trending_up_rounded,
          const Color(0xFF06B6D4),
              () => context.go('/health-progress'),
        ),
      ],
    );
  }

  Widget _buildSection(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color iconColor,
      List<Widget> cards,
      ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildModernCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.tertiaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: colorScheme.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Consejo del día',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Para obtener mejores resultados en tus análisis, asegúrate de tomar las fotos con buena iluminación natural y desde diferentes ángulos. ¡La luz natural siempre es tu mejor aliada!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onTertiaryContainer.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.go('/health-tips'),
            icon: Icon(
              Icons.arrow_forward_rounded,
              color: colorScheme.tertiary,
            ),
            label: Text(
              'Ver más consejos',
              style: TextStyle(
                color: colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}