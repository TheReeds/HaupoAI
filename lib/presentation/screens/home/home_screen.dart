// lib/presentation/screens/home/improved_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../data/models/transformation_post_model.dart';
import '../../../data/models/post_model.dart';
import '../../widgets/social/transformation_card.dart';
import '../../widgets/social/mini_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _ImprovedHomeScreenState();
}

class _ImprovedHomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ChatRepository _chatRepository = ChatRepository();
  final SocialRepository _socialRepository = SocialRepository();
  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
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
    _pageController.dispose();
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
              // Modern App Bar con gradiente
              _buildModernAppBar(context, authProvider),

              // Contenido Principal
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Sección de Bienvenida Personalizada
                        _buildPersonalizedWelcome(context, authProvider),

                        // Chat Bot Access
                        _buildChatBotAccess(context, authProvider),

                        // Análisis Rápido
                        _buildQuickAnalysis(context, authProvider),

                        // Transformaciones Destacadas
                        _buildFeaturedTransformations(context),

                        // Paleta de Colores Personal
                        _buildPersonalColorPalette(context, authProvider),

                        // Últimas Publicaciones
                        _buildRecentPosts(context),

                        // Consejos Diarios
                        _buildDailyTips(context),

                        const SizedBox(height: 100), // Espacio para FAB
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFABMenu(context),
    );
  }

  Widget _buildModernAppBar(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 160,
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
                colorScheme.primaryContainer.withOpacity(0.8),
                colorScheme.tertiaryContainer.withOpacity(0.6),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Logo y título
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HuapoAI',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Tu asistente de estilo personal',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Notificaciones
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Perfil
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: _buildProfileButton(context, authProvider),
        ),
      ],
    );
  }

  Widget _buildProfileButton(BuildContext context, AuthProvider authProvider) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go('/profile');
            break;
          case 'preferences':
            context.go('/edit-preferences');
            break;
          case 'logout':
            _showLogoutDialog(context, authProvider);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Mi Perfil'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'preferences',
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Mis Preferencias'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error),
            title: Text('Cerrar sesión',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Hero(
        tag: 'profile_avatar',
        child: CircleAvatar(
          radius: 20,
          backgroundImage: authProvider.user?.photoURL != null
              ? NetworkImage(authProvider.user!.photoURL!)
              : null,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: authProvider.user?.photoURL == null
              ? Text(
            authProvider.user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildPersonalizedWelcome(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = authProvider.user;

    return Container(
      margin: const EdgeInsets.all(24),
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
        borderRadius: BorderRadius.circular(24),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${user?.displayName?.split(' ').first ?? 'Usuario'}! ✨',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPersonalizedGreeting(user),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAnalysisStatusCards(context, user),
        ],
      ),
    );
  }

  String _getPersonalizedGreeting(user) {
    if (user?.hasFaceAnalysis == true && user?.hasBodyAnalysis == true) {
      return 'Tu perfil está completo. ¡Obtén recomendaciones personalizadas!';
    } else if (user?.hasFaceAnalysis == true) {
      return 'Ya tienes tu análisis facial. ¿Qué tal un análisis corporal?';
    } else if (user?.hasBodyAnalysis == true) {
      return 'Tienes tu análisis corporal. ¡Completa con el análisis facial!';
    } else {
      return 'Comencemos con un análisis para darte las mejores recomendaciones.';
    }
  }

  Widget _buildAnalysisStatusCards(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            context,
            'Rostro',
            user?.hasFaceAnalysis == true ? 'Analizado' : 'Pendiente',
            user?.hasFaceAnalysis == true
                ? Icons.check_circle_rounded
                : Icons.face_rounded,
            user?.hasFaceAnalysis == true
                ? colorScheme.primary
                : colorScheme.outline,
                () => context.go('/face-analysis'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            context,
            'Cuerpo',
            user?.hasBodyAnalysis == true ? 'Analizado' : 'Pendiente',
            user?.hasBodyAnalysis == true
                ? Icons.check_circle_rounded
                : Icons.accessibility_new_rounded,
            user?.hasBodyAnalysis == true
                ? colorScheme.primary
                : colorScheme.outline,
                () => context.go('/body-analysis'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      BuildContext context,
      String title,
      String status,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBotAccess(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/chat'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.tertiaryContainer,
                  colorScheme.tertiaryContainer.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colorScheme.tertiary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Pregúntame cualquier cosa!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consejos personalizados de moda y estilo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onTertiaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.tertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAnalysis(BuildContext context, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis Rápido',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAnalysisCard(
                  context,
                  'Análisis Facial',
                  'Encuentra tu corte perfecto',
                  Icons.face_rounded,
                  const Color(0xFF6366F1),
                      () => context.go('/face-analysis'),
                ),
                const SizedBox(width: 16),
                _buildQuickAnalysisCard(
                  context,
                  'Análisis Corporal',
                  'Descubre tu estilo ideal',
                  Icons.accessibility_new_rounded,
                  const Color(0xFF10B981),
                      () => context.go('/body-analysis'),
                ),
                const SizedBox(width: 16),
                _buildQuickAnalysisCard(
                  context,
                  'Paleta de Colores',
                  'Colores que te favorecen',
                  Icons.palette_rounded,
                  const Color(0xFFEC4899),
                      () => _generateColorPalette(context, authProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAnalysisCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTransformations(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transformaciones Destacadas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/transformations'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: StreamBuilder<List<TransformationPostModel>>(
              stream: _chatRepository.getTransformationsFeed(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transformations = snapshot.data ?? [];

                if (transformations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.transform_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay transformaciones aún',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/create-transformation'),
                          child: const Text('Crear la primera'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: transformations.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 16),
                      child: TransformationCard(
                        transformation: transformations[index],
                        isCompact: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalColorPalette(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu Paleta Personal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Basada en tu análisis personal',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mostrar paleta de colores
          FutureBuilder(
            future: _chatRepository.getLatestUserColorPalette(authProvider.user?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final palette = snapshot.data;
              if (palette == null) {
                return _buildGeneratePaletteButton(context, authProvider);
              }

              return Column(
                children: [
                  // Colores ideales
                  _buildColorRow('Colores que te favorecen', palette.idealColors),
                  const SizedBox(height: 16),
                  // Colores a evitar
                  _buildColorRow('Colores a evitar', palette.avoidColors),
                  const SizedBox(height: 16),
                  // Botón para regenerar
                  TextButton.icon(
                    onPressed: () => _generateColorPalette(context, authProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Actualizar paleta'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String title, List<String> colors) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: colors.take(5).map((colorHex) {
            return Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _hexToColor(colorHex),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGeneratePaletteButton(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.palette_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Genera tu paleta personalizada',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _generateColorPalette(context, authProvider),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Generar paleta'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPosts(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimas Publicaciones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/feed'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: StreamBuilder<List<PostModel>>(
              stream: _socialRepository.getPostsFeed(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay publicaciones aún',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/create-post'),
                          child: const Text('Crear la primera'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      child: MiniPostCard(post: posts[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondaryContainer,
            colorScheme.secondaryContainer.withOpacity(0.7),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tips_and_updates_rounded,
                  color: colorScheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Consejo del día',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getDailyTip(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSecondaryContainer.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/health-tips'),
                  icon: const Icon(Icons.library_books_rounded),
                  label: const Text('Más consejos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.secondary,
                    side: BorderSide(color: colorScheme.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/chat'),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Pregúntame'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                  side: BorderSide(color: colorScheme.secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFABMenu(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateMenu(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Crear'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Qué quieres crear?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildCreateOption(
                  context,
                  'Publicación',
                  Icons.photo_camera_outlined,
                  const Color(0xFF6366F1),
                      () {
                    Navigator.pop(context);
                    context.go('/create-post');
                  },
                ),
                _buildCreateOption(
                  context,
                  'Transformación',
                  Icons.transform_rounded,
                  const Color(0xFF10B981),
                      () {
                    Navigator.pop(context);
                    context.go('/create-transformation');
                  },
                ),
                _buildCreateOption(
                  context,
                  'Análisis',
                  Icons.analytics_outlined,
                  const Color(0xFFEC4899),
                      () {
                    Navigator.pop(context);
                    _showAnalysisOptions(context);
                  },
                ),
                _buildCreateOption(
                  context,
                  'Pregunta',
                  Icons.chat_bubble_outline_rounded,
                  const Color(0xFFF59E0B),
                      () {
                    Navigator.pop(context);
                    context.go('/chat');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalysisOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tipo de Análisis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.face_rounded),
              title: const Text('Análisis Facial'),
              subtitle: const Text('Forma de rostro y cortes'),
              onTap: () {
                Navigator.pop(context);
                context.go('/face-analysis');
              },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new_rounded),
              title: const Text('Análisis Corporal'),
              subtitle: const Text('Tipo de cuerpo y estilos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/body-analysis');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getDailyTip() {
    final tips = [
      'Los colores que armonicen con tu tono de piel te harán lucir más radiante y saludable.',
      'Para fotos de análisis, usa luz natural y evita sombras fuertes en el rostro.',
      'Los patrones verticales alargan la figura, mientras que los horizontales la ensanchan.',
      'Combina máximo 3 colores en un outfit para mantener el equilibrio visual.',
      'Los accesorios pueden transformar completamente un look básico.',
      'La confianza es el mejor accesorio que puedes llevar con cualquier outfit.',
    ];

    final today = DateTime.now();
    final index = today.day % tips.length;
    return tips[index];
  }

  void _generateColorPalette(BuildContext context, AuthProvider authProvider) async {
    // Implementar generación de paleta de colores
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando tu paleta personalizada...'),
        duration: Duration(seconds: 2),
      ),
    );

    // Aquí iría la lógica para generar la paleta usando el chatbot
    context.go('/color-palette');
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}