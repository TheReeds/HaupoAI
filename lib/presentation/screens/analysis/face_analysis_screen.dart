// lib/presentation/screens/analysis/face_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FaceAnalysisScreen extends StatelessWidget {
  const FaceAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Facial'),
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
                Icons.face,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Análisis Facial',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Esta funcionalidad estará disponible pronto.\nPodrás analizar tu rostro para obtener recomendaciones de cortes de pelo.',
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

// lib/presentation/screens/analysis/body_analysis_screen.dart
class BodyAnalysisScreen extends StatelessWidget {
  const BodyAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Corporal'),
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
                Icons.accessibility,
                size: 100,
                color: Colors.green,
              ),
              SizedBox(height: 24),
              Text(
                'Análisis Corporal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Esta funcionalidad estará disponible pronto.\nPodrás analizar tu cuerpo para obtener recomendaciones de ropa.',
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