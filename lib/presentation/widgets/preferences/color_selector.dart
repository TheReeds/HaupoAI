// lib/presentation/widgets/preferences/color_selector.dart
import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final Set<String> selectedColors;
  final Function(String) onColorToggle;

  const ColorSelector({
    super.key,
    required this.selectedColors,
    required this.onColorToggle,
  });

  static final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Negro', 'color': Colors.black},
    {'name': 'Blanco', 'color': Colors.white},
    {'name': 'Gris', 'color': Colors.grey},
    {'name': 'Azul Marino', 'color': const Color(0xFF1A237E)},
    {'name': 'Azul', 'color': Colors.blue},
    {'name': 'Azul Claro', 'color': Colors.lightBlue},
    {'name': 'Verde', 'color': Colors.green},
    {'name': 'Verde Oliva', 'color': const Color(0xFF689F38)},
    {'name': 'Rojo', 'color': Colors.red},
    {'name': 'Burdeos', 'color': const Color(0xFF880E4F)},
    {'name': 'Rosa', 'color': Colors.pink},
    {'name': 'Púrpura', 'color': Colors.purple},
    {'name': 'Naranja', 'color': Colors.orange},
    {'name': 'Amarillo', 'color': Colors.yellow},
    {'name': 'Beige', 'color': const Color(0xFFF5F5DC)},
    {'name': 'Marrón', 'color': Colors.brown},
    {'name': 'Dorado', 'color': const Color(0xFFFFD700)},
    {'name': 'Plateado', 'color': const Color(0xFFC0C0C0)},
    {'name': 'Turquesa', 'color': Colors.teal},
    {'name': 'Coral', 'color': const Color(0xFFFF7043)},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _colorOptions.length,
      itemBuilder: (context, index) {
        final colorOption = _colorOptions[index];
        final colorName = colorOption['name'] as String;
        final colorValue = colorOption['color'] as Color;
        final isSelected = selectedColors.contains(colorName);

        return GestureDetector(
          onTap: () => onColorToggle(colorName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorValue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorValue == Colors.white
                          ? Colors.grey.shade400
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    color: _getContrastColor(colorValue),
                    size: 20,
                  )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  colorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getContrastColor(Color color) {
    // Calcular si el color es claro u oscuro para elegir el color del check
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}