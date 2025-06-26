// lib/presentation/screens/recommendations/recommendations_trends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recommendations_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class RecommendationsTrendsScreen extends StatefulWidget {
  const RecommendationsTrendsScreen({super.key});

  @override
  State<RecommendationsTrendsScreen> createState() => _RecommendationsTrendsScreenState();
}

class _RecommendationsTrendsScreenState extends State<RecommendationsTrendsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadTrendsData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _loadTrendsData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final recommendationsProvider = context.read<RecommendationsProvider>();
      final userId = authProvider.user?.uid;

      if (userId != null && !recommendationsProvider.hasRecommendations) {
        recommendationsProvider.loadUserData(userId);
      }
    });
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
      appBar: AppBar(
        title: const Text('Tendencias Personales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showInfoDialog,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información sobre tendencias',
          ),
        ],
      ),
      body: Consumer<RecommendationsProvider>(
        builder: (context, provider, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContent(context, provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecommendationsProvider provider) {
    final trends = provider.personalTrends;
    final stats = provider.followingStats;

    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (trends.isEmpty || trends['hasEnoughData'] != true) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con resumen
          _buildTrendsHeader(context, trends),

          const SizedBox(height: 24),

          // Estadísticas de seguimiento
          if (stats.isNotEmpty) _buildFollowingStats(context, stats),

          const SizedBox(height: 24),

          // Tendencias de puntuaciones
          _buildScoresTrends(context, trends['trends']['scoresTrend']),

          const SizedBox(height: 24),

          // Cambios en recomendaciones
          _buildRecommendationChanges(context, trends['trends']['recommendationChanges']),

          const SizedBox(height: 24),

          // Progreso de bienestar
          if (trends['trends']['wellnessProgress']?['hasData'] == true)
            _buildWellnessProgress(context, trends['trends']['wellnessProgress']),

          const SizedBox(height: 24),

          // Insights y sugerencias
          _buildInsightsSection(context, trends),

          const SizedBox(height: 32),

          // Acciones
          _buildActionsSection(context),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Analizando tus tendencias...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esto puede tomar unos momentos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tendencias en Desarrollo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Necesitas al menos 2 análisis de recomendaciones para ver tus tendencias personales.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.secondary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Qué puedes ver aquí?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Evolución de tus puntuaciones de bienestar\n'
                        '• Cambios en tus recomendaciones\n'
                        '• Progreso en tu cuidado personal\n'
                        '• Estadísticas de seguimiento\n'
                        '• Insights personalizados',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Generar Más Recomendaciones',
              icon: Icons.auto_awesome_rounded,
              onPressed: () => context.go('/personalized-recommendations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsHeader(BuildContext context, Map<String, dynamic> trends) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dataPoints = trends['dataPoints'] ?? 0;
    final timeSpan = trends['timeSpan'] ?? 0;

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
            blurRadius: 15,
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
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
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
                      'Tu Evolución Personal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Análisis basado en $dataPoints recomendaciones',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  context,
                  'Análisis',
                  '$dataPoints',
                  Icons.analytics_outlined,
                  colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeaderStat(
                  context,
                  'Período',
                  '${timeSpan}d',
                  Icons.calendar_today_outlined,
                  colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingStats(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final totalRecommendations = stats['totalRecommendations'] ?? 0;
    final followedRecommendations = stats['followedRecommendations'] ?? 0;
    final followingRate = stats['followingRate'] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Estadísticas de Seguimiento',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total',
                    totalRecommendations.toString(),
                    Icons.lightbulb_outline_rounded,
                    const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Seguidas',
                    followedRecommendations.toString(),
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Tasa',
                    '${(followingRate * 100).toInt()}%',
                    Icons.trending_up_rounded,
                    const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(context, followingRate),
            const SizedBox(height: 12),
            Text(
              _getFollowingRateMessage(followingRate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso de Seguimiento',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(progress),
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return const Color(0xFF10B981); // Verde
    if (progress >= 0.6) return const Color(0xFFF59E0B); // Amarillo
    if (progress >= 0.4) return const Color(0xFFEC4899); // Rosa
    return const Color(0xFFEF4444); // Rojo
  }

  String _getFollowingRateMessage(double rate) {
    if (rate >= 0.8) return '¡Excelente! Sigues muy bien las recomendaciones.';
    if (rate >= 0.6) return 'Buen trabajo siguiendo las recomendaciones.';
    if (rate >= 0.4) return 'Hay oportunidad de seguir más recomendaciones.';
    return 'Intenta seguir más recomendaciones para mejores resultados.';
  }

  Widget _buildScoresTrends(BuildContext context, Map<String, dynamic>? scoresTrend) {
    final theme = Theme.of(context);

    if (scoresTrend == null || scoresTrend.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Evolución de Puntuaciones',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (scoresTrend['overall'] != null)
              _buildTrendItem(
                context,
                'Puntuación General',
                scoresTrend['overall']['trend'],
                scoresTrend['overall']['change'],
                Icons.analytics_rounded,
                'Tu progreso general de bienestar y estilo',
              ),
            const SizedBox(height: 12),
            if (scoresTrend['style'] != null)
              _buildTrendItem(
                context,
                'Estilo Personal',
                scoresTrend['style']['trend'],
                scoresTrend['style']['change'],
                Icons.palette_rounded,
                'Tu desarrollo en estilo y moda personal',
              ),
            const SizedBox(height: 12),
            if (scoresTrend['health'] != null)
              _buildTrendItem(
                context,
                'Bienestar',
                scoresTrend['health']['trend'],
                scoresTrend['health']['change'],
                Icons.favorite_rounded,
                'Tu salud y bienestar general',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
      BuildContext context,
      String label,
      String trend,
      double change,
      IconData icon,
      String description,
      ) {
    final theme = Theme.of(context);

    Color trendColor;
    IconData trendIcon;
    String trendText;

    switch (trend) {
      case 'improving':
        trendColor = const Color(0xFF10B981);
        trendIcon = Icons.trending_up_rounded;
        trendText = 'Mejorando';
        break;
      case 'declining':
        trendColor = const Color(0xFFEF4444);
        trendIcon = Icons.trending_down_rounded;
        trendText = 'En declive';
        break;
      default:
        trendColor = const Color(0xFF6B7280);
        trendIcon = Icons.trending_flat_rounded;
        trendText = 'Estable';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trendColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: trendColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, color: trendColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    trendText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${change > 0 ? '+' : ''}${(change * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationChanges(BuildContext context, Map<String, dynamic>? changes) {
    final theme = Theme.of(context);

    if (changes == null || changes.isEmpty) {
      return const SizedBox.shrink();
    }

    final changedCategories = changes['changedCategories'] ?? 0;
    final totalCategories = changes['totalCategories'] ?? 1;
    final changePercentage = changes['changePercentage'] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cambios en Recomendaciones',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categorías Actualizadas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$changedCategories de $totalCategories categorías',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(changePercentage * 100).toInt()}%',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cambio',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getChangeMessage(changePercentage),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChangeMessage(double changePercentage) {
    if (changePercentage >= 0.7) {
      return 'Tus recomendaciones han evolucionado significativamente, reflejando tu progreso personal.';
    } else if (changePercentage >= 0.5) {
      return 'Se han actualizado varias categorías de recomendaciones basadas en tu desarrollo.';
    } else if (changePercentage >= 0.3) {
      return 'Algunos aspectos de tus recomendaciones han cambiado para adaptarse mejor a ti.';
    } else {
      return 'Tus recomendaciones se mantienen consistentes, indicando estabilidad en tu perfil.';
    }
  }

  Widget _buildWellnessProgress(BuildContext context, Map<String, dynamic> progress) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Progreso de Bienestar',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (progress['fatigueImprovement'] == true)
              _buildProgressItem(
                context,
                'Reducción de Fatiga',
                'Has mejorado significativamente en niveles de energía',
                Icons.bedtime_rounded,
                const Color(0xFF10B981),
              ),
            if (progress['skinImprovement'] == true)
              _buildProgressItem(
                context,
                'Mejora en la Piel',
                'Tu condición de piel ha mostrado mejoras notables',
                Icons.spa_rounded,
                const Color(0xFF10B981),
              ),
            if (progress['hydrationImprovement'] == true)
              _buildProgressItem(
                context,
                'Mejor Hidratación',
                'Tus niveles de hidratación se han normalizado',
                Icons.water_drop_rounded,
                const Color(0xFF3B82F6),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Basado en ${progress['dataPoints']} análisis de bienestar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(BuildContext context, Map<String, dynamic> trends) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Insights Personalizados',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._generateInsights(trends).map((insight) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights(Map<String, dynamic> trends) {
    final insights = <String>[];
    final scoresTrend = trends['trends']?['scoresTrend'];
    final dataPoints = trends['dataPoints'] ?? 0;

    if (scoresTrend != null) {
      if (scoresTrend['overall']?['trend'] == 'improving') {
        insights.add('¡Excelente progreso! Tu puntuación general está mejorando consistentemente.');
      } else if (scoresTrend['overall']?['trend'] == 'declining') {
        insights.add('Hay oportunidades de mejora. Considera seguir más recomendaciones activamente.');
      } else {
        insights.add('Mantienes un progreso estable. La consistencia es clave para el éxito a largo plazo.');
      }

      if (scoresTrend['style']?['trend'] == 'improving') {
        insights.add('Tu estilo personal está evolucionando positivamente.');
      }

      if (scoresTrend['health']?['trend'] == 'improving') {
        insights.add('Tus hábitos de bienestar están mostrando resultados positivos.');
      }
    }

    if (dataPoints >= 5) {
      insights.add('Tienes suficientes datos para ver tendencias confiables en tu desarrollo personal.');
    } else if (dataPoints >= 3) {
      insights.add('Continúa generando recomendaciones para obtener insights más precisos.');
    }

    if (insights.isEmpty) {
      insights.add('Continúa usando la app para obtener insights más detallados sobre tu progreso.');
    }

    return insights;
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/personalized-recommendations'),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Nuevas Recomendaciones'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/recommendations/history'),
                icon: const Icon(Icons.history_rounded),
                label: const Text('Ver Historial'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _exportTrendsReport,
            icon: const Icon(Icons.file_download_rounded),
            label: const Text('Exportar Reporte de Tendencias'),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de las Tendencias'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Las tendencias personales te ayudan a entender tu evolución en el tiempo:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Text('📈 Evolución de Puntuaciones\nMuestra cómo han cambiado tus puntuaciones de bienestar, estilo y salud.'),
              SizedBox(height: 12),
              Text('📊 Estadísticas de Seguimiento\nIndica qué tan bien sigues las recomendaciones generadas.'),
              SizedBox(height: 12),
              Text('💡 Insights Personalizados\nProporciona recomendaciones basadas en tu progreso.'),
              SizedBox(height: 12),
              Text('🔄 Cambios en Recomendaciones\nMuestra cómo se adaptan las recomendaciones a tu evolución.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _exportTrendsReport() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final recommendationsProvider = context.read<RecommendationsProvider>();
      final userId = authProvider.user?.uid;

      if (userId == null) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final report = await recommendationsProvider.exportReport(userId);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (report != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte exportado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al exportar el reporte'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}