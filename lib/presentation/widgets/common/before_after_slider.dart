// lib/presentation/widgets/common/before_after_slider.dart
import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final double height;

  const BeforeAfterSlider({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.height = 300,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: widget.height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Imagen "Después" (fondo completo)
          Positioned.fill(
            child: Image.network(
              widget.afterImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),

          // Imagen "Antes" (clippeada)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * _sliderValue,
            child: ClipRect(
              child: Image.network(
                widget.beforeImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),

          // Línea divisoria
          Positioned(
            left: (MediaQuery.of(context).size.width * _sliderValue) - 1,
            top: 0,
            bottom: 0,
            width: 2,
            child: Container(
              color: Colors.white,
            ),
          ),

          // Slider
          Positioned.fill(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 0,
                thumbShape: CustomThumbShape(),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                value: _sliderValue,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
          ),

          // Labels
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'ANTES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'DESPUÉS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(30, 30);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;

    // Círculo exterior
    canvas.drawCircle(
      center,
      15,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Círculo interior
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Líneas indicadoras
    final linePaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(center.dx - 6, center.dy),
      Offset(center.dx + 6, center.dy),
      linePaint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - 6),
      Offset(center.dx, center.dy + 6),
      linePaint,
    );
  }
}