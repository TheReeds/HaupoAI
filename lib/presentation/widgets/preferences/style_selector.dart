// lib/presentation/widgets/preferences/style_selector.dart
import 'package:flutter/material.dart';
import '../common/style_placeholder.dart';

class StyleSelector extends StatelessWidget {
  final Set<String> selectedStyles;
  final Function(String) onStyleToggle;

  const StyleSelector({
    super.key,
    required this.selectedStyles,
    required this.onStyleToggle,
  });

  // Usando los mismos styleOptions del widget original para mantener compatibilidad
  static const Map<String, Map<String, dynamic>> styleOptions = {
    'Casual': {
      'icon': Icons.weekend,
      'description': 'Cómodo y relajado',
      'image': 'assets/images/styles/casual.jpg',
    },
    'Elegante': {
      'icon': Icons.star,
      'description': 'Sofisticado y refinado',
      'image': 'assets/images/styles/elegante.jpg',
    },
    'Deportivo': {
      'icon': Icons.fitness_center,
      'description': 'Activo y funcional',
      'image': 'assets/images/styles/deportivo.jpg',
    },
    'Bohemio': {
      'icon': Icons.nature_people,
      'description': 'Libre y artístico',
      'image': 'assets/images/styles/bohemio.jpg',
    },
    'Minimalista': {
      'icon': Icons.minimize,
      'description': 'Simple y limpio',
      'image': 'assets/images/styles/minimalista.jpg',
    },
    'Vintage': {
      'icon': Icons.access_time,
      'description': 'Clásico y retro',
      'image': 'assets/images/styles/vintage.jpg',
    },
    'Urbano': {
      'icon': Icons.location_city,
      'description': 'Moderno y audaz',
      'image': 'assets/images/styles/urbano.jpg',
    },
    'Romántico': {
      'icon': Icons.favorite,
      'description': 'Dulce y femenino',
      'image': 'assets/images/styles/romantico.jpg',
    },
    'Rockero': {
      'icon': Icons.music_note,
      'description': 'Rebelde y edgy',
      'image': 'assets/images/styles/rockero.jpg',
    },
    'Preppy': {
      'icon': Icons.school,
      'description': 'Clásico y pulcro',
      'image': 'assets/images/styles/preppy.jpg',
    },
    'Boho chic': {
      'icon': Icons.eco,
      'description': 'Étnico y moderno',
      'image': 'assets/images/styles/boho_chic.jpg',
    },
    'Gótico': {
      'icon': Icons.dark_mode,
      'description': 'Oscuro y dramático',
      'image': 'assets/images/styles/gotico.jpg',
    },
  };

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: _styleCategories.map((category) => _buildStyleCategory(context, category)).toList(),
    );
  }

  Widget _buildStyleCategory(BuildContext context, Map<String, dynamic> category) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category['title'],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category['subtitle'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: category['styles'].length,
              itemBuilder: (context, index) {
                final styleName = category['styles'][index];
                final styleData = styleOptions[styleName]!;
                return _buildStyleCard(context, styleName, styleData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(BuildContext context, String styleName, Map<String, dynamic> styleData) {
    final isSelected = selectedStyles.contains(styleName);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onStyleToggle(styleName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Imagen del estilo
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: theme.colorScheme.surfaceVariant,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        styleData['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Usar placeholder personalizado cuando no hay imagen
                          return StylePlaceholder(
                            styleName: styleName,
                            icon: styleData['icon'] as IconData,
                            isSelected: isSelected,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Información del estilo
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                          : theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          styleName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          styleData['description'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Indicador de selección
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Organizando los estilos en categorías
  static final List<Map<String, dynamic>> _styleCategories = [
    {
      'title': 'Estilos Casuales',
      'subtitle': 'Para el día a día',
      'styles': ['Casual', 'Urbano', 'Bohemio', 'Minimalista'],
    },
    {
      'title': 'Estilos Formales',
      'subtitle': 'Para ocasiones especiales',
      'styles': ['Elegante', 'Preppy', 'Romántico', 'Vintage'],
    },
    {
      'title': 'Estilos Alternativos',
      'subtitle': 'Únicos y expresivos',
      'styles': ['Rockero', 'Gótico', 'Boho chic', 'Deportivo'],
    },
  ];
}