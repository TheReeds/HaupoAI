// lib/presentation/widgets/analysis/body_type_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/roboflow_service.dart';
import '../../../data/models/body_analysis_model.dart';
import '../../../core/services/roboflow_service.dart';

class BodyTypeCard extends StatelessWidget {
  final BodyAnalysisModel analysis;
  final VoidCallback? onViewDetails;

  const BodyTypeCard({
    super.key,
    required this.analysis,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final bodyTypeInfo = RoboflowService.getBodyTypeInfo();
    final typeData = bodyTypeInfo[analysis.bodyType.toLowerCase()];
    final averageConfidence = analysis.averageConfidence * 100;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(analysis.getBodyTypeColor()).withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(analysis.getBodyTypeColor()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.accessibility_new,
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
                          'Tu análisis corporal',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          typeData?['name'] ?? analysis.bodyType,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(analysis.getBodyTypeColor()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Descripción del análisis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.getBodyAnalysisDescription(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (typeData?['description'] != null)
                      Text(
                        typeData!['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Imagen del análisis (si existe)
              if (analysis.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: analysis.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Estadísticas del análisis
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Confianza',
                      '${averageConfidence.toStringAsFixed(1)}%',
                      Icons.analytics,
                      _getConfidenceColor(averageConfidence),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Analizado',
                      _formatDate(analysis.analyzedAt),
                      Icons.schedule,
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Desglose de confianza
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(analysis.getBodyTypeColor()).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(analysis.getBodyTypeColor()).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desglose de confianza:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(analysis.getBodyTypeColor()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildConfidenceRow(
                      context,
                      'Tipo de cuerpo',
                      analysis.bodyTypeConfidence,
                      Icons.fitness_center,
                    ),
                    const SizedBox(height: 8),
                    _buildConfidenceRow(
                      context,
                      'Forma corporal',
                      analysis.bodyShapeConfidence,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 8),
                    _buildConfidenceRow(
                      context,
                      'Género',
                      analysis.genderConfidence,
                      Icons.person,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Características principales
              if (typeData?['characteristics'] != null) ...[
                Text(
                  'Características principales:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...typeData!['characteristics'].take(3).map<Widget>((char) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Color(analysis.getBodyTypeColor()),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              char,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ),
                const SizedBox(height: 16),
              ],

              // Indicador de confiabilidad
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: analysis.isReliable
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: analysis.isReliable
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      analysis.isReliable ? Icons.verified : Icons.warning,
                      color: analysis.isReliable ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analysis.isReliable
                            ? 'Análisis confiable y preciso'
                            : 'Considera tomar una foto con mejor calidad',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: analysis.isReliable ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botón de ver detalles
              if (onViewDetails != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Ver análisis completo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(analysis.getBodyTypeColor()),
                      side: BorderSide(
                        color: Color(analysis.getBodyTypeColor()),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceRow(
      BuildContext context, String label, double confidence, IconData icon) {
    final confidencePercent = confidence * 100;
    final confidenceColor = _getConfidenceColor(confidencePercent);

    return Row(
      children: [
        Icon(icon, size: 16, color: confidenceColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: confidenceColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${confidencePercent.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: confidenceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}