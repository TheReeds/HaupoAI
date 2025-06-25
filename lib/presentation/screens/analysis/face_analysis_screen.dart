// lib/presentation/screens/analysis/face_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/face_analysis_repository.dart';
import '../../../data/models/face_analysis_model.dart';
import '../../../core/services/roboflow_service.dart';
import '../../widgets/analysis/face_shape_card.dart';
import '../../widgets/common/custom_button.dart';

class FaceAnalysisScreen extends StatefulWidget {
  const FaceAnalysisScreen({super.key});

  @override
  State<FaceAnalysisScreen> createState() => _FaceAnalysisScreenState();
}

class _FaceAnalysisScreenState extends State<FaceAnalysisScreen>
    with TickerProviderStateMixin {
  final FaceAnalysisRepository _faceAnalysisRepository = FaceAnalysisRepository();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  bool _isAnalyzing = false;
  FaceAnalysisModel? _currentAnalysis;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExistingAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAnalysis() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final latestAnalysis = await _faceAnalysisRepository.getLatestFaceAnalysis(userId);
        if (mounted) {
          setState(() {
            _currentAnalysis = latestAnalysis;
          });
        }
      } catch (e) {
        print('Error cargando análisis existente: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Facial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Analizar', icon: Icon(Icons.camera_alt)),
            Tab(text: 'Resultado', icon: Icon(Icons.analytics)),
            Tab(text: 'Consejos', icon: Icon(Icons.lightbulb)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalysisTab(),
          _buildResultsTab(),
          _buildTipsTab(),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información de la funcionalidad
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.face,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Análisis de Forma Facial',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nuestra IA analizará la forma de tu rostro para recomendarte los mejores cortes de cabello y estilos que realcen tu belleza natural.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Estado actual del análisis
          if (user?.hasFaceAnalysis == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ya tienes un análisis facial',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Forma: ${user?.currentFaceShape} '
                              '(${(user?.faceAnalysisConfidence ?? 0 * 100).toStringAsFixed(1)}% confianza)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Imagen seleccionada
          if (_selectedImage != null) ...[
            Text(
              'Imagen seleccionada:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Tomar Foto',
                  icon: Icons.camera_alt,
                  onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Desde Galería',
                  icon: Icons.photo_library,
                  onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                  isOutlined: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón para usar foto de perfil
          if (user?.photoURL != null)
            CustomButton(
              text: 'Analizar Foto de Perfil',
              icon: Icons.account_circle,
              onPressed: _isAnalyzing ? null : _analyzeProfilePhoto,
              width: double.infinity,
              isOutlined: true,
            ),

          const SizedBox(height: 24),

          // Botón de análisis
          CustomButton(
            text: _isAnalyzing ? 'Analizando...' : 'Analizar Rostro',
            icon: _isAnalyzing ? null : Icons.analytics,
            onPressed: (_selectedImage != null && !_isAnalyzing) ? _performAnalysis : null,
            width: double.infinity,
            isLoading: _isAnalyzing,
          ),

          const SizedBox(height: 32),

          // Consejos para mejores resultados
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Consejos para mejores resultados',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('📸', 'Usa buena iluminación natural'),
                  _buildTip('👤', 'Mira directamente a la cámara'),
                  _buildTip('✨', 'Rostro despejado (sin gafas de sol)'),
                  _buildTip('📐', 'Encuadra desde los hombros hacia arriba'),
                  _buildTip('😊', 'Expresión neutral o sonrisa ligera'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_currentAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Sin análisis aún',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Realiza tu primer análisis facial\npara ver los resultados aquí',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Ir a Análisis',
              icon: Icons.arrow_forward,
              onPressed: () => _tabController.animateTo(0),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resultado principal
          FaceShapeCard(
            analysis: _currentAnalysis!,
            onViewDetails: () => _showDetailedResults(),
          ),

          const SizedBox(height: 24),

          // Recomendaciones de corte de cabello
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.content_cut,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cortes Recomendados',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._currentAnalysis!.getHairStyleRecommendations().map(
                        (recommendation) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Nuevo Análisis',
                  icon: Icons.refresh,
                  onPressed: () => _tabController.animateTo(0),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Compartir',
                  icon: Icons.share,
                  onPressed: _shareResults,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    final faceShapeInfo = RoboflowService.getFaceShapeInfo();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guía de Formas de Rostro',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conoce las diferentes formas de rostro y sus características',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          ...faceShapeInfo.entries.map((entry) {
            final shapeKey = entry.key;
            final shapeData = entry.value;
            final isCurrentShape = _currentAnalysis?.faceShape.toLowerCase() == shapeKey;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isCurrentShape
                    ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
                    : null,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: shapeData['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            shapeData['name'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrentShape) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Tu forma',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        shapeData['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Características:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...shapeData['characteristics'].map<Widget>((char) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: shapeData['color'],
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
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeProfilePhoto() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user?.photoURL == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes foto de perfil para analizar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await _faceAnalysisRepository.analyzeFaceFromProfilePhoto(
        userId: user!.uid,
        photoURL: user.photoURL!,
      );

      setState(() {
        _currentAnalysis = analysis;
        _isAnalyzing = false;
      });

      // Cambiar a la pestaña de resultados
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Análisis completado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en el análisis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performAnalysis() async {
    if (_selectedImage == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await _faceAnalysisRepository.analyzeFace(
        userId: userId,
        imageFile: _selectedImage!,
      );

      setState(() {
        _currentAnalysis = analysis;
        _selectedImage = null;
        _isAnalyzing = false;
      });

      // Cambiar a la pestaña de resultados
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Análisis completado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en el análisis: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showDetailedResults() {
    if (_currentAnalysis == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Análisis Detallado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forma del rostro: ${_currentAnalysis!.faceShape}'),
            const SizedBox(height: 8),
            Text('Confianza: ${(_currentAnalysis!.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatDate(_currentAnalysis!.analyzedAt)}'),
            const SizedBox(height: 16),
            Text(_currentAnalysis!.getShapeDescription()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _shareResults() {
    if (_currentAnalysis == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}