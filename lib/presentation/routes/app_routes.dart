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

        // Ruta de búsqueda (placeholder)
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const SearchScreen(),
        ),
      ],
    );
  }
}

// Pantalla de búsqueda temporal
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 100,
                color: Colors.grey,
              ),
              SizedBox(height: 24),
              Text(
                'Búsqueda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Esta funcionalidad estará disponible pronto.\nPodrás buscar posts, usuarios y consejos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}