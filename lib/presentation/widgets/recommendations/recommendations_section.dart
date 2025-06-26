// lib/presentation/widgets/recommendations/recommendations_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/personalized_recommendations_repository.dart';
import '../../../data/repositories/preference_repository.dart';
import '../../../data/models/personalized_recommendations_model.dart';
import '../../../data/models/preference_model.dart';
import '../common/custom_button.dart';

class RecommendationsSection extends StatefulWidget {
  const RecommendationsSection({super.key});

  @override
  State<RecommendationsSection> createState() => _RecommendationsSectionState();
}

class _RecommendationsSectionState extends State<RecommendationsSection> {
  final PersonalizedRecommendationsRepository _recommendationsRepository =
  PersonalizedRecommendationsRepository();
  final PreferenceRepository _preferenceRepository = PreferenceRepository();

  PersonalizedRecommendationsModel? _latestRecommendations;
  bool _isLoading = false;
  bool _hasPreferences = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendationsData();
  }

  Future<void> _loadRecommendationsData() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar si el usuario necesita nuevas recomendaciones
      final needsUpdate = await _recommendationsRepository.needsNewRecommendations(userId);

      if (!needsUpdate) {
        // Cargar las recomendaciones existentes
        final recommendations = await _recommendationsRepository.getLatestRecommendations(userId);
        setState(() {
          _latestRecommendations = recommendations;
        });
      }

      // Verificar si tiene preferencias
      final preferences = await _preferenceRepository.getPreferences(userId);
      setState(() {
        _hasPreferences = preferences != null;
      });

    } catch (e) {
      print('Error cargando recomendaciones: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recomendaciones IA',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Personalizadas para ti',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_latestRecommendations != null)
                TextButton(
                  onPressed: () => context.go('/personalized-recommendations'),
                  child: const Text('Ver todas'),
                ),
            ],
          ),

          const SizedBox(height: 20),

          if (_isLoading)
            _buildLoadingState()
          else if (_latestRecommendations != null)
            _buildRecommendationsContent()
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando recomendaciones...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.tertiaryContainer.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Estado según completitud del perfil
          if (!user!.hasCompleteAnalysis) ...[
            Icon(
              Icons.psychology_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Análisis Requerido',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tu análisis personal para obtener recomendaciones ultra-personalizadas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildAnalysisProgress(user),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Completar Análisis',
              icon: Icons.analytics_rounded,
              onPressed: () => _navigateToMissingAnalysis(user),
            ),
          ] else if (!_hasPreferences) ...[
            Icon(
              Icons.palette_outlined,
              size: 48,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Preferencias Requeridas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configura tus preferencias de estilo y colores para recomendaciones precisas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Configurar Preferencias',
              icon: Icons.settings_rounded,
              onPressed: () => context.go('/edit-preferences'),
            ),
          ] else ...[
            Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: colorScheme.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Todo Listo!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu perfil está completo. Genera tus primeras recomendaciones personalizadas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Generar Recomendaciones',
              icon: Icons.auto_awesome_rounded,
              onPressed: () => context.go('/personalized-recommendations'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisProgress(user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          'Progreso del análisis:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProgressItem(
                'Rostro',
                user.hasFaceAnalysis,
                Icons.face_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressItem(
                'Cabello',
                user.hasHairAnalysis,
                Icons.content_cut_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressItem(
                'Cuerpo',
                user.hasBodyAnalysis,
                Icons.accessibility_new_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressItem(String label, bool completed, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed
            ? colorScheme.primaryContainer
            : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            completed ? Icons.check_circle : icon,
            color: completed
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: completed
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: completed ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recommendations = _latestRecommendations!;

    return Column(
      children: [
        // Puntuaciones de bienestar resumidas
        _buildScoresSummary(recommendations),

        const SizedBox(height: 20),

        // Recomendaciones destacadas
        _buildHighlightedRecommendations(recommendations),

        const SizedBox(height: 20),

        // Alertas prioritarias si las hay
        ...recommendations.getHealthAlerts().take(1).map(
              (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPriorityAlert(alert),
          ),
        ),

        // Acciones rápidas
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildScoresSummary(PersonalizedRecommendationsModel recommendations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scores = recommendations.getScoresSummary();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu Puntuación de Bienestar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScoreItem(
                  'General',
                  scores['overall']['score'],
                  scores['overall']['label'],
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreItem(
                  'Estilo',
                  scores['style']['score'],
                  scores['style']['label'],
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreItem(
                  'Salud',
                  scores['health']['score'],
                  scores['health']['label'],
                  const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, String scoreLabel, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${(score * 100).toInt()}%',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scoreLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedRecommendations(PersonalizedRecommendationsModel recommendations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtener las mejores recomendaciones de cada categoría
    final highlights = [
      {
        'title': 'Estilo de Cabello',
        'icon': Icons.content_cut_rounded,
        'color': const Color(0xFF6366F1),
        'recommendations': recommendations.hairStyleRecommendations.take(2).toList(),
      },
      {
        'title': 'Colores Perfectos',
        'icon': Icons.palette_rounded,
        'color': const Color(0xFFEC4899),
        'recommendations': recommendations.colorRecommendations.take(2).toList(),
      },
      {
        'title': 'Cuidado Personal',
        'icon': Icons.spa_rounded,
        'color': const Color(0xFF10B981),
        'recommendations': recommendations.skinCareRecommendations.take(2).toList(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendaciones Destacadas',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...highlights.map((highlight) {
          final recommendations = highlight['recommendations'] as List<String>;
          if (recommendations.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (highlight['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (highlight['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      highlight['icon'] as IconData,
                      color: highlight['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      highlight['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: highlight['color'] as Color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: highlight['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriorityAlert(Map<String, dynamic> alert) {
    final theme = Theme.of(context);
    final alertType = alert['type'] as String;

    Color alertColor;
    IconData alertIcon;

    switch (alertType) {
      case 'warning':
        alertColor = Colors.orange;
        alertIcon = Icons.warning_rounded;
        break;
      case 'error':
        alertColor = Colors.red;
        alertIcon = Icons.error_rounded;
        break;
      case 'info':
        alertColor = Colors.blue;
        alertIcon = Icons.info_rounded;
        break;
      default:
        alertColor = Colors.grey;
        alertIcon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            alertIcon,
            color: alertColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] as String,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/personalized-recommendations'),
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('Ver Todas'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _generateNewRecommendations,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
          ),
        ),
      ],
    );
  }

  void _navigateToMissingAnalysis(user) {
    if (!user.hasFaceAnalysis) {
      context.go('/face-analysis');
    } else if (!user.hasBodyAnalysis) {
      context.go('/body-analysis');
    } else {
      context.go('/face-analysis'); // Por defecto
    }
  }

  Future<void> _generateNewRecommendations() async {
    context.go('/personalized-recommendations');
  }
}