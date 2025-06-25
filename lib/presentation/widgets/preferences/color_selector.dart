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

  static const Map<String, Color> colorOptions = {
    'Negro': Colors.black,
    'Blanco': Colors.white,
    'Gris': Colors.grey,
    'Azul marino': Color(0xFF1E3A8A),
    'Azul': Colors.blue,
    'Azul claro': Colors.lightBlue,
    'Verde': Colors.green,
    'Verde oliva': Color(0xFF6B7C32),
    'Rojo': Colors.red,
    'Borgoña': Color(0xFF800020),
    'Rosa': Colors.pink,
    'Púrpura': Colors.purple,
    'Naranja': Colors.orange,
    'Amarillo': Colors.yellow,
    'Beige': Color(0xFFF5F5DC),
    'Marrón': Colors.brown,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: colorOptions.length,
      itemBuilder: (context, index) {
        final colorName = colorOptions.keys.elementAt(index);
        final colorValue = colorOptions.values.elementAt(index);
        final isSelected = selectedColors.contains(colorName);

        return GestureDetector(
          onTap: () => onColorToggle(colorName),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
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
                    color: colorValue == Colors.white ||
                        colorValue == Colors.yellow ||
                        colorValue == Color(0xFFF5F5DC)
                        ? Colors.black
                        : Colors.white,
                    size: 20,
                  )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  colorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
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
}