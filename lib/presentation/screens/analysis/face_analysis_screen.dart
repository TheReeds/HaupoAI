// lib/presentation/screens/analysis/face_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/face_analysis_repository.dart';
import '../../../data/models/face_analysis_model.dart';
import '../../../data/models/hair_analysis_model.dart';
import '../../../core/services/roboflow_service.dart';
import '../../widgets/analysis/face_shape_card.dart';
import '../../widgets/analysis/hair_type_card.dart';
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
  FaceAnalysisModel? _currentFaceAnalysis;
  HairAnalysisModel? _currentHairAnalysis;
  File? _selectedImage;
  String? _analysisImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadExistingAnalyses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAnalyses() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final latestAnalyses = await _faceAnalysisRepository.getLatestCompleteAnalysis(userId);
        if (mounted) {
          setState(() {
            _currentFaceAnalysis = latestAnalyses['faceAnalysis'];
            _currentHairAnalysis = latestAnalyses['hairAnalysis'];
          });
        }
      } catch (e) {
        print('Error cargando análisis existentes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Completo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Analizar', icon: Icon(Icons.camera_alt)),
            Tab(text: 'Resultados', icon: Icon(Icons.analytics)),
            Tab(text: 'Rostro', icon: Icon(Icons.face)),
            Tab(text: 'Cabello', icon: Icon(Icons.content_cut)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalysisTab(),
          _buildResultsTab(),
          _buildFaceGuideTab(),
          _buildHairGuideTab(),
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Análisis Completo IA',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rostro + Cabello',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nuestra IA analizará tanto la forma de tu rostro como tu tipo de cabello para darte recomendaciones personalizadas completas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Estado actual del análisis
          if (user?.hasCompleteAnalysis == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tienes análisis completo',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '👤 Rostro: ${user?.currentFaceShape ?? 'No analizado'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '✂️ Cabello: ${user?.currentHairType ?? 'No analizado'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
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

          // Botón de análisis completo
          CustomButton(
            text: _isAnalyzing ? 'Analizando...' : 'Análisis Completo IA',
            icon: _isAnalyzing ? null : Icons.psychology,
            onPressed: (_selectedImage != null && !_isAnalyzing) ? _performCompleteAnalysis : null,
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
                  _buildTip('✨', 'Rostro y cabello despejados'),
                  _buildTip('📐', 'Encuadra desde los hombros hacia arriba'),
                  _buildTip('💇', 'Cabello visible y natural'),
                  _buildTip('😊', 'Expresión neutral o sonrisa ligera'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_currentFaceAnalysis == null && _currentHairAnalysis == null) {
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
              'Realiza tu primer análisis completo\npara ver los resultados aquí',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Comenzar Análisis',
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
          // Resultados del análisis facial
          if (_currentFaceAnalysis != null) ...[
            FaceShapeCard(
              analysis: _currentFaceAnalysis!,
              onViewDetails: () => _showDetailedResults('face'),
            ),
            const SizedBox(height: 16),
          ],

          // Resultados del análisis de cabello
          if (_currentHairAnalysis != null) ...[
            HairTypeCard(
              analysis: _currentHairAnalysis!,
              onViewDetails: () => _showDetailedResults('hair'),
            ),
            const SizedBox(height: 24),
          ],

          // Recomendaciones combinadas
          if (_currentFaceAnalysis != null && _currentHairAnalysis != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recomendaciones Personalizadas',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Basadas en tu rostro ${_currentFaceAnalysis!.faceShape} y cabello ${_currentHairAnalysis!.hairType}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._getCombinedRecommendations().map(
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
          ],

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
                  text: 'Guardar en Perfil',
                  icon: Icons.save,
                  onPressed: _saveToProfile,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón de compartir
          CustomButton(
            text: 'Compartir Resultados',
            icon: Icons.share,
            onPressed: _shareResults,
            width: double.infinity,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFaceGuideTab() {
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
            final isCurrentShape = _currentFaceAnalysis?.faceShape.toLowerCase() == shapeKey;

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

  Widget _buildHairGuideTab() {
    final hairTypeInfo = RoboflowService.getHairTypeInfo();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guía de Tipos de Cabello',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conoce los diferentes tipos de cabello y sus cuidados',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          ...hairTypeInfo.entries.map((entry) {
            final typeKey = entry.key;
            final typeData = entry.value;
            final isCurrentType = _currentHairAnalysis?.hairType.toLowerCase() == typeKey;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isCurrentType
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
                              color: typeData['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            typeData['name'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrentType) ...[
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
                                'Tu tipo',
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
                        typeData['description'],
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
                      ...typeData['characteristics'].map<Widget>((char) =>
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
                                    color: typeData['color'],
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
                      const SizedBox(height: 16),
                      Text(
                        'Consejos de cuidado:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...typeData['care_tips'].map<Widget>((tip) =>
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
                                    color: typeData['color'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip,
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
      final results = await _faceAnalysisRepository.analyzeCompleteProfileFromPhoto(
        userId: user!.uid,
        photoURL: user.photoURL!,
      );

      setState(() {
        _currentFaceAnalysis = results['faceAnalysis'];
        _currentHairAnalysis = results['hairAnalysis'];
        _analysisImageUrl = results['imageUrl'];
        _isAnalyzing = false;
      });

      // Cambiar a la pestaña de resultados
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Análisis completo exitoso!'),
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

  Future<void> _performCompleteAnalysis() async {
    if (_selectedImage == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final results = await _faceAnalysisRepository.analyzeCompleteProfile(
        userId: userId,
        imageFile: _selectedImage!,
      );

      setState(() {
        _currentFaceAnalysis = results['faceAnalysis'];
        _currentHairAnalysis = results['hairAnalysis'];
        _analysisImageUrl = results['imageUrl'];
        _selectedImage = null;
        _isAnalyzing = false;
      });

      // Cambiar a la pestaña de resultados
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Análisis completo exitoso!'),
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

  Future<void> _saveToProfile() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null || (_currentFaceAnalysis == null && _currentHairAnalysis == null)) {
      return;
    }

    try {
      // Guardar en el perfil del usuario
      await _faceAnalysisRepository.saveAnalysisToUserProfile(
        userId: userId,
        faceAnalysis: _currentFaceAnalysis,
        hairAnalysis: _currentHairAnalysis,
      );

      // Actualizar el usuario en el provider
      final updatedUser = authProvider.user!.copyWith(
        currentFaceShape: _currentFaceAnalysis?.faceShape,
        faceAnalysisConfidence: _currentFaceAnalysis?.confidence,
        lastFaceAnalysis: _currentFaceAnalysis?.analyzedAt,
        currentHairType: _currentHairAnalysis?.hairType,
        hairAnalysisConfidence: _currentHairAnalysis?.confidence,
        lastHairAnalysis: _currentHairAnalysis?.analyzedAt,
      );

      authProvider.updateUser(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Análisis guardado en tu perfil!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetailedResults(String type) {
    if (type == 'face' && _currentFaceAnalysis != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Análisis Facial Detallado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Forma del rostro: ${_currentFaceAnalysis!.faceShape}'),
              const SizedBox(height: 8),
              Text('Confianza: ${(_currentFaceAnalysis!.confidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Fecha: ${_formatDate(_currentFaceAnalysis!.analyzedAt)}'),
              const SizedBox(height: 16),
              Text(_currentFaceAnalysis!.getShapeDescription()),
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
    } else if (type == 'hair' && _currentHairAnalysis != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Análisis de Cabello Detallado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo de cabello: ${_currentHairAnalysis!.hairType}'),
              const SizedBox(height: 8),
              Text('Confianza: ${(_currentHairAnalysis!.confidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Fecha: ${_formatDate(_currentHairAnalysis!.analyzedAt)}'),
              const SizedBox(height: 16),
              Text(_currentHairAnalysis!.getHairTypeDescription()),
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
  }

  void _shareResults() {
    if (_currentFaceAnalysis == null && _currentHairAnalysis == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente'),
      ),
    );
  }

  List<String> _getCombinedRecommendations() {
    List<String> recommendations = [];

    if (_currentFaceAnalysis != null && _currentHairAnalysis != null) {
      final faceShape = _currentFaceAnalysis!.faceShape.toLowerCase();
      final hairType = _currentHairAnalysis!.hairType.toLowerCase();

      // Recomendaciones específicas basadas en la combinación
      if (faceShape == 'round' && hairType == 'straight') {
        recommendations.addAll([
          'Capas largas para alargar visualmente el rostro',
          'Volumen en la coronilla para equilibrar',
          'Evita cortes muy cortos que acentúen la redondez',
        ]);
      } else if (faceShape == 'oval' && hairType == 'curly') {
        recommendations.addAll([
          'Tienes la combinación perfecta - casi todo te queda bien',
          'Prueba diferentes largos según tu estilo personal',
          'Define tus rizos con productos específicos',
        ]);
      } else if (faceShape == 'square' && hairType == 'wavy') {
        recommendations.addAll([
          'Las ondas suavizan la mandíbula angular',
          'Capas alrededor del rostro para suavizar',
          'Evita cortes muy geométricos',
        ]);
      } else {
        // Recomendaciones generales
        recommendations.addAll([
          'Combina las recomendaciones específicas de tu rostro y cabello',
          'Consulta con un estilista para personalizar aún más',
          'Mantén tu cabello saludable con los cuidados apropiados',
        ]);
      }

      // Agregar algunas recomendaciones generales
      recommendations.addAll([
        'Usa productos adecuados para tu tipo de cabello',
        'Considera tu estilo de vida al elegir cortes',
        'Mantén citas regulares para mantener la forma',
      ]);
    }

    return recommendations;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}