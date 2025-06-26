import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recommendations_provider.dart';
import '../../../data/models/personalized_recommendations_model.dart';

class RecommendationsHistoryScreen extends StatelessWidget {
  const RecommendationsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Recomendaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<RecommendationsProvider>(
        builder: (context, provider, child) {
          final history = provider.recommendationsHistory;

          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 24),
                  Text(
                    'Sin historial',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aún no tienes recomendaciones generadas',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final recommendations = history[index];
              return _buildHistoryItem(context, recommendations, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(
      BuildContext context,
      PersonalizedRecommendationsModel recommendations,
      int index
      ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Recomendaciones #${index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(recommendations.generatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Puntuación general: ${(recommendations.overallWellnessScore * 100).toInt()}%',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${_getTotalRecommendationsCount(recommendations)} recomendaciones totales',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewRecommendations(context, recommendations),
                      child: const Text('Ver detalles'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _deleteRecommendations(context, recommendations),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewRecommendations(BuildContext context, PersonalizedRecommendationsModel recommendations) {
    // Implementar navegación a detalles o mostrar dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Recomendaciones'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fecha: ${_formatDate(recommendations.generatedAt)}'),
              const SizedBox(height: 8),
              Text('Puntuación general: ${(recommendations.overallWellnessScore * 100).toInt()}%'),
              Text('Puntuación de estilo: ${(recommendations.styleCompatibilityScore * 100).toInt()}%'),
              Text('Puntuación de salud: ${(recommendations.healthScore * 100).toInt()}%'),
              const SizedBox(height: 16),
              Text('Total de recomendaciones: ${_getTotalRecommendationsCount(recommendations)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _deleteRecommendations(BuildContext context, PersonalizedRecommendationsModel recommendations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Recomendaciones'),
        content: const Text('¿Estás seguro de que quieres eliminar estas recomendaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<RecommendationsProvider>();
              final success = await provider.deleteRecommendations(recommendations.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Recomendaciones eliminadas'
                        : 'Error al eliminar recomendaciones'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _getTotalRecommendationsCount(PersonalizedRecommendationsModel recommendations) {
    return recommendations.hairStyleRecommendations.length +
        recommendations.clothingRecommendations.length +
        recommendations.colorRecommendations.length +
        recommendations.skinCareRecommendations.length +
        recommendations.hairCareRecommendations.length +
        recommendations.bodyWellnessRecommendations.length +
        recommendations.exerciseRecommendations.length +
        recommendations.nutritionRecommendations.length +
        recommendations.lifestyleRecommendations.length;
  }
}