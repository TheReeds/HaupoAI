// lib/presentation/widgets/common/style_placeholder.dart
import 'package:flutter/material.dart';

class StylePlaceholder extends StatelessWidget {
  final String styleName;
  final IconData icon;
  final bool isSelected;

  const StylePlaceholder({
    super.key,
    required this.styleName,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStyleColor(styleName).withOpacity(0.8),
            _getStyleColor(styleName),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              styleName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStyleColor(String styleName) {
    switch (styleName.toLowerCase()) {
      case 'casual':
        return Colors.blue;
      case 'elegante':
        return Colors.purple;
      case 'deportivo':
        return Colors.green;
      case 'bohemio':
        return Colors.orange;
      case 'minimalista':
        return Colors.grey;
      case 'vintage':
        return Colors.brown;
      case 'urbano':
        return Colors.indigo;
      case 'romántico':
        return Colors.pink;
      case 'rockero':
        return Colors.black;
      case 'preppy':
        return Colors.teal;
      case 'boho chic':
        return Colors.deepOrange;
      case 'gótico':
        return Colors.black87;
      default:
        return Colors.blueGrey;
    }
  }
}