// lib/presentation/screens/social/transformations_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/transformation_post_model.dart';
import '../../widgets/social/transformation_card.dart';

class TransformationsFeedScreen extends StatefulWidget {
  const TransformationsFeedScreen({super.key});

  @override
  State<TransformationsFeedScreen> createState() => _TransformationsFeedScreenState();
}

class _TransformationsFeedScreenState extends State<TransformationsFeedScreen>
    with SingleTickerProviderStateMixin {
  final ChatRepository _chatRepository = ChatRepository();
  late TabController _tabController;

  final List<String> _categories = ['Todos', 'Cabello', 'Outfit', 'Maquillaje', 'Físico', 'Estilo'];
  final Map<String, String> _categoryMapping = {
    'Todos': '',
    'Cabello': 'haircut',
    'Outfit': 'outfit',
    'Maquillaje': 'makeup',
    'Físico': 'weight',
    'Estilo': 'style',
  };

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
        title: const Text('Transformaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/create-transformation'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          final transformationType = _categoryMapping[category];
          return _buildTransformationsList(transformationType);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-transformation'),
        icon: const Icon(Icons.transform_rounded),
        label: const Text('Crear'),
      ),
    );
  }

  Widget _buildTransformationsList(String? transformationType) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return StreamBuilder(
          stream: _chatRepository.getTransformationsFeed(
            currentUserId: authProvider.user?.uid,
            transformationType: transformationType?.isEmpty == true ? null : transformationType,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final transformations = snapshot.data ?? [];

            if (transformations.isEmpty) {
              return _buildEmptyState(transformationType);
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {}); // Trigger rebuild
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transformations.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: TransformationCard(
                      transformation: transformations[index],
                      onTap: () => _showTransformationDetail(transformations[index]),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String? transformationType) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String title = 'No hay transformaciones aún';
    String subtitle = '¡Sé el primero en compartir tu increíble cambio!';

    if (transformationType != null && transformationType.isNotEmpty) {
      title = 'No hay transformaciones de este tipo';
      subtitle = '¡Sé el primero en compartir una transformación de ${_getCategoryName(transformationType)}!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.transform_rounded,
                size: 64,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/create-transformation'),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Crear transformación'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String transformationType) {
    switch (transformationType) {
      case 'haircut':
        return 'cabello';
      case 'outfit':
        return 'outfit';
      case 'makeup':
        return 'maquillaje';
      case 'weight':
        return 'transformación física';
      case 'style':
        return 'estilo';
      default:
        return 'esta categoría';
    }
  }

  void _showTransformationDetail(transformation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transformation card
                        TransformationCard(
                          transformation: transformation,
                          isCompact: false,
                        ),

                        const SizedBox(height: 24),

                        // Comentarios section placeholder
                        Text(
                          'Comentarios',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Los comentarios estarán disponibles pronto.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}