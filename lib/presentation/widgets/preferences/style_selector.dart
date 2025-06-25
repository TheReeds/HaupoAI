// lib/presentation/widgets/preferences/style_selector.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StyleSelector extends StatelessWidget {
  final Set<String> selectedStyles;
  final Function(String) onStyleToggle;

  const StyleSelector({
    super.key,
    required this.selectedStyles,
    required this.onStyleToggle,
  });

  static const Map<String, Map<String, dynamic>> styleOptions = {
    'Casual': {
      'icon': Icons.weekend,
      'description': 'Cómodo y relajado',
    },
    'Elegante': {
      'icon': Icons.star,
      'description': 'Sofisticado y refinado',
    },
    'Deportivo': {
      'icon': Icons.fitness_center,
      'description': 'Activo y funcional',
    },
    'Bohemio': {
      'icon': Icons.nature_people,
      'description': 'Libre y artístico',
    },
    'Minimalista': {
      'icon': Icons.minimize,
      'description': 'Simple y limpio',
    },
    'Vintage': {
      'icon': Icons.access_time,
      'description': 'Clásico y retro',
    },
    'Urbano': {
      'icon': Icons.location_city,
      'description': 'Moderno y audaz',
    },
    'Romántico': {
      'icon': Icons.favorite,
      'description': 'Dulce y femenino',
    },
    'Rockero': {
      'icon': Icons.music_note,
      'description': 'Rebelde y edgy',
    },
    'Preppy': {
      'icon': Icons.school,
      'description': 'Clásico y pulcro',
    },
    'Boho chic': {
      'icon': Icons.eco,
      'description': 'Étnico y moderno',
    },
    'Gótico': {
      'icon': Icons.dark_mode,
      'description': 'Oscuro y dramático',
    },
  };

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: styleOptions.length,
      itemBuilder: (context, index) {
        final styleName = styleOptions.keys.elementAt(index);
        final styleData = styleOptions.values.elementAt(index);
        final isSelected = selectedStyles.contains(styleName);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onStyleToggle(styleName),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      styleData['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          styleName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          styleData['description'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}