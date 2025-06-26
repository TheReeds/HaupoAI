// lib/presentation/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/social/create_post_screen.dart';
import '../screens/social/discover_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/setup_preferences_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_preferences_screen.dart';
import '../screens/analysis/face_analysis_screen.dart';
import '../screens/analysis/body_analysis_screen.dart';
import '../screens/social/feed_screen.dart';
import '../screens/health/health_tips_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/social/create_transformation_screen.dart';
import '../screens/social/transformations_feed_screen.dart';
import '../screens/style/color_palette_screen.dart';
// ======== NUEVOS IMPORTS PARA RECOMENDACIONES ========
import '../screens/wellness/personalized_recommendations_screen.dart';
import '../widgets/recommendations/recommendations_category_screen.dart';
import '../widgets/recommendations/recommendations_history_screen.dart';
import '../widgets/recommendations/recommendations_trends_screen.dart';

class AppRoutes {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final authState = authProvider.state;
        final isAuthenticated = authProvider.isAuthenticated;
        final needsOnboarding = authProvider.needsOnboarding;
        final isInitialized = authProvider.isInitialized;

        print('Redirect - State: $authState, isAuthenticated: $isAuthenticated, needsOnboarding: $needsOnboarding, isInitialized: $isInitialized, path: ${state.uri}');

        if (!isInitialized) {
          if (state.uri.toString() != '/splash') {
            return '/splash';
          }
          return null;
        }

        if (state.uri.toString() == '/splash' && isInitialized) {
          if (!isAuthenticated) {
            return '/login';
          } else if (needsOnboarding) {
            return '/setup-preferences';
          } else {
            return '/home';
          }
        }

        if (!isAuthenticated) {
          if (state.uri.toString() != '/login' && state.uri.toString() != '/register') {
            return '/login';
          }
          return null;
        }

        if (needsOnboarding) {
          if (state.uri.toString() != '/setup-preferences') {
            return '/setup-preferences';
          }
          return null;
        }

        if (isAuthenticated &&
            (state.uri.toString() == '/login' || state.uri.toString() == '/register')) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Rutas de autenticación
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/setup-preferences',
          name: 'setup-preferences',
          builder: (context, state) => const SetupPreferencesScreen(),
        ),

        // Rutas principales
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),

        // Rutas de perfil
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/edit-preferences',
          name: 'edit-preferences',
          builder: (context, state) => const EditPreferencesScreen(),
        ),

        // Rutas de análisis
        GoRoute(
          path: '/face-analysis',
          name: 'face-analysis',
          builder: (context, state) => const FaceAnalysisScreen(),
        ),
        GoRoute(
          path: '/body-analysis',
          name: 'body-analysis',
          builder: (context, state) => const BodyAnalysisScreen(),
        ),

        // ======== RUTAS DE RECOMENDACIONES PERSONALIZADAS ========

        // Pantalla principal de recomendaciones personalizadas
        GoRoute(
          path: '/personalized-recommendations',
          name: 'personalized-recommendations',
          builder: (context, state) => const PersonalizedRecommendationsScreen(),
        ),

        // Recomendaciones por categoría específica
        GoRoute(
          path: '/recommendations/category/:category',
          name: 'recommendations-category',
          builder: (context, state) {
            final category = state.pathParameters['category']!;
            return RecommendationsCategoryScreen(category: category);
          },
        ),

        // Historial de recomendaciones
        GoRoute(
          path: '/recommendations/history',
          name: 'recommendations-history',
          builder: (context, state) => const RecommendationsHistoryScreen(),
        ),

        // Tendencias y progreso personal
        GoRoute(
          path: '/recommendations/trends',
          name: 'recommendations-trends',
          builder: (context, state) => const RecommendationsTrendsScreen(),
        ),

        // ======== FIN RUTAS DE RECOMENDACIONES ========

        // Rutas sociales
        GoRoute(
          path: '/feed',
          name: 'feed',
          builder: (context, state) => const FeedScreen(),
        ),
        GoRoute(
          path: '/discover',
          name: 'discover',
          builder: (context, state) => const DiscoverScreen(),
        ),
        GoRoute(
          path: '/create-post',
          name: 'create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),

        // Rutas de Chat con IA
        GoRoute(
          path: '/chat',
          name: 'chat',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: '/chat/:sessionId',
          name: 'chat-session',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId'];
            return ChatScreen(sessionId: sessionId);
          },
        ),

        // Rutas de Transformaciones
        GoRoute(
          path: '/transformations',
          name: 'transformations',
          builder: (context, state) => const TransformationsFeedScreen(),
        ),
        GoRoute(
          path: '/create-transformation',
          name: 'create-transformation',
          builder: (context, state) => const CreateTransformationScreen(),
        ),

        // Rutas de Estilo y Colores
        GoRoute(
          path: '/color-palette',
          name: 'color-palette',
          builder: (context, state) => const ColorPaletteScreen(),
        ),

        // Rutas de salud
        GoRoute(
          path: '/health-tips',
          name: 'health-tips',
          builder: (context, state) => const HealthTipsScreen(),
        ),
        GoRoute(
          path: '/health-progress',
          name: 'health-progress',
          builder: (context, state) => const HealthProgressScreen(),
        ),

        // Ruta de búsqueda mejorada
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const ImprovedSearchScreen(),
        ),

        // Rutas adicionales para funcionalidades futuras
        GoRoute(
          path: '/outfit-generator',
          name: 'outfit-generator',
          builder: (context, state) => const OutfitGeneratorScreen(),
        ),
        GoRoute(
          path: '/style-quiz',
          name: 'style-quiz',
          builder: (context, state) => const StyleQuizScreen(),
        ),
        GoRoute(
          path: '/wardrobe',
          name: 'wardrobe',
          builder: (context, state) => const WardrobeScreen(),
        ),
      ],
    );
  }
}

// ======== PANTALLAS PLACEHOLDER MEJORADAS ========

// Pantalla de búsqueda mejorada
class ImprovedSearchScreen extends StatefulWidget {
  const ImprovedSearchScreen({super.key});

  @override
  State<ImprovedSearchScreen> createState() => _ImprovedSearchScreenState();
}

class _ImprovedSearchScreenState extends State<ImprovedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todo';

  final List<String> _categories = ['Todo', 'Posts', 'Usuarios', 'Consejos', 'Transformaciones'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar posts, usuarios, consejos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
              ),
              onSubmitted: (value) {
                // Implementar búsqueda
              },
            ),
          ),

          // Categorías
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: colorScheme.surfaceVariant,
                    selectedColor: colorScheme.primaryContainer,
                  ),
                );
              },
            ),
          ),

          // Contenido
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 80,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Búsqueda Inteligente',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Encuentra posts, usuarios, consejos de estilo\ny transformaciones increíbles.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '🔍 Búsqueda avanzada disponible pronto',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla placeholder para generador de outfits
class OutfitGeneratorScreen extends StatelessWidget {
  const OutfitGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Outfits'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.checkroom_rounded, size: 100, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Generador de Outfits IA',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Crea outfits perfectos basados en:\n• Tu análisis personal\n• El clima\n• La ocasión\n• Tu guardarropa',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                '🤖 Próximamente disponible',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla placeholder para quiz de estilo
class StyleQuizScreen extends StatelessWidget {
  const StyleQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz de Estilo'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_rounded, size: 100, color: Colors.purple),
              SizedBox(height: 24),
              Text(
                'Quiz de Estilo Personal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Descubre tu estilo único con nuestro\nquiz interactivo personalizado.\n\n✨ Preguntas inteligentes\n🎯 Resultados precisos\n💡 Recomendaciones personalizadas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                '📝 En desarrollo',
                style: TextStyle(fontSize: 18, color: Colors.purple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla placeholder para guardarropa virtual
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Guardarropa'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.checkroom_outlined, size: 100, color: Colors.green),
              SizedBox(height: 24),
              Text(
                'Guardarropa Virtual',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Organiza tu ropa de manera inteligente:\n\n👔 Categorización automática\n📱 Fotos de tus prendas\n🔄 Combinaciones sugeridas\n📊 Estadísticas de uso',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                '👗 Función avanzada próximamente',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla placeholder para progreso de salud
class HealthProgressScreen extends StatelessWidget {
  const HealthProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded, size: 100, color: Colors.orange),
              SizedBox(height: 24),
              Text(
                'Seguimiento de Progreso',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Monitorea tu evolución en estilo:\n\n📈 Gráficos de progreso\n🎯 Metas personalizadas\n🏆 Logros desbloqueados\n📸 Comparativas temporales',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                '📊 Sistema de métricas en desarrollo',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}