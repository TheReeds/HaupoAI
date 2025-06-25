// lib/presentation/screens/health/health_tips_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../../data/repositories/social_repository.dart';
import '../../widgets/health/health_tip_card.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final SocialRepository _socialRepository = SocialRepository();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Todos', 'key': null, 'icon': Icons.all_inclusive},
    {'name': 'Dieta', 'key': 'diet', 'icon': Icons.restaurant},
    {'name': 'Ejercicio', 'key': 'exercise', 'icon': Icons.fitness_center},
    {'name': 'Estilo de vida', 'key': 'lifestyle', 'icon': Icons.line_style},
    {'name': 'Cuidado de piel', 'key': 'skincare', 'icon': Icons.face},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consejos de Salud'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category['icon'], size: 16),
                  const SizedBox(width: 8),
                  Text(category['name']),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              return _buildCategoryTab(category['key']);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab(String? category) {
    return FutureBuilder<List<HealthTipModel>>(
      future: _socialRepository.getHealthTips(
        category: category,
        bodyType: 'all', // TODO: Obtener del análisis corporal del usuario
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar consejos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta nuevamente más tarde',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final tips = snapshot.data ?? [];

        if (tips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay consejos disponibles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vuelve más tarde para ver nuevos consejos',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              return HealthTipCard(
                tip: tips[index],
                onTap: () => _showTipDetail(tips[index]),
              );
            },
          ),
        );
      },
    );
  }

  void _showTipDetail(HealthTipModel tip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthTipDetailScreen(tip: tip),
      ),
    );
  }
}

// lib/presentation/screens/health/health_tip_detail_screen.dart
class HealthTipDetailScreen extends StatelessWidget {
  final HealthTipModel tip;

  const HealthTipDetailScreen({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tip.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
              background: tip.imageUrl != null
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    tip.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(tip.category),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getCategoryName(tip.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (tip.isPersonalized) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Personalizado',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Descripción
                  Text(
                    tip.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tags
                  if (tip.tags.isNotEmpty) ...[
                    Text(
                      'Etiquetas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tip.tags.map((tag) {
                        return Chip(
                          label: Text('#$tag'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Información adicional
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información adicional',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            'Categoría',
                            _getCategoryName(tip.category),
                            Icons.category,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Tipo de cuerpo',
                            tip.targetBodyType == 'all' ? 'Todos' : tip.targetBodyType,
                            Icons.accessibility,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Fecha',
                            _formatDate(tip.createdAt),
                            Icons.date_range,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implementar guardar consejo
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Consejo guardado'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_border),
                          label: const Text('Guardar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implementar compartir
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función de compartir próximamente'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Compartir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'diet':
        return Colors.green;
      case 'exercise':
        return Colors.orange;
      case 'lifestyle':
        return Colors.blue;
      case 'skincare':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'diet':
        return 'Dieta';
      case 'exercise':
        return 'Ejercicio';
      case 'lifestyle':
        return 'Estilo de vida';
      case 'skincare':
        return 'Cuidado de piel';
      default:
        return 'General';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// lib/presentation/screens/health/health_progress_screen.dart
class HealthProgressScreen extends StatelessWidget {
  const HealthProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso de Salud'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 100,
                color: Colors.teal,
              ),
              SizedBox(height: 24),
              Text(
                'Seguimiento de Progreso',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Esta funcionalidad estará disponible pronto.\nPodrás hacer seguimiento de tu progreso de salud y bienestar.',
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