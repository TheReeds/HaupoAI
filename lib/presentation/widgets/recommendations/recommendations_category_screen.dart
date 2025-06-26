import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/recommendations_provider.dart';
import '../../widgets/common/custom_button.dart';

class RecommendationsCategoryScreen extends StatefulWidget {
  final String category;

  const RecommendationsCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<RecommendationsCategoryScreen> createState() => _RecommendationsCategoryScreenState();
}

class _RecommendationsCategoryScreenState extends State<RecommendationsCategoryScreen> {
  List<String> _recommendations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategoryRecommendations();
  }

  Future<void> _loadCategoryRecommendations() async {
    final authProvider = context.read<AuthProvider>();
    final recommendationsProvider = context.read<RecommendationsProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final recommendations = await recommendationsProvider.getRecommendationsByCategory(
          userId,
          widget.category
      );

      setState(() {
        _recommendations = recommendations;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando recomendaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryDisplayName(widget.category)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendations.isEmpty
          ? _buildEmptyState()
          : _buildRecommendationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(widget.category),
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            'No hay recomendaciones',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Genera recomendaciones personalizadas\npara esta categoría',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Generar Recomendaciones',
            icon: Icons.auto_awesome,
            onPressed: () => context.go('/personalized-recommendations'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              IconButton(
                onPressed: () => _markAsFollowed(index),
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Marcar como seguida',
              ),
            ],
          ),
        );
      },
    );
  }

  void _markAsFollowed(int index) {
    final recommendationsProvider = context.read<RecommendationsProvider>();
    recommendationsProvider.markRecommendationAsFollowed(widget.category, index);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Recomendación marcada como seguida!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'hairstyle':
        return 'Estilo de Cabello';
      case 'clothing':
        return 'Vestimenta';
      case 'colors':
        return 'Colores';
      case 'skincare':
        return 'Cuidado de la Piel';
      case 'haircare':
        return 'Cuidado del Cabello';
      case 'bodywellness':
        return 'Bienestar Corporal';
      case 'exercise':
        return 'Ejercicio';
      case 'nutrition':
        return 'Nutrición';
      case 'lifestyle':
        return 'Estilo de Vida';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hairstyle':
        return Icons.content_cut;
      case 'clothing':
        return Icons.checkroom;
      case 'colors':
        return Icons.palette;
      case 'skincare':
        return Icons.spa;
      case 'haircare':
        return Icons.cut;
      case 'bodywellness':
        return Icons.self_improvement;
      case 'exercise':
        return Icons.fitness_center;
      case 'nutrition':
        return Icons.restaurant;
      case 'lifestyle':
        return Icons.line_style;
      default:
        return Icons.lightbulb;
    }
  }
}