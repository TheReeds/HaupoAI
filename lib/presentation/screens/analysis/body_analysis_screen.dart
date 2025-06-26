// lib/presentation/screens/analysis/body_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/services/roboflow_service.dart';
import '../../providers/auth_provider.dart';
import '../../../data/repositories/body_analysis_repository.dart';
import '../../../data/models/body_analysis_model.dart';
import '../../../core/services/roboflow_service.dart';
import '../../widgets/analysis/body_type_card.dart';
import '../../widgets/common/custom_button.dart';

class BodyAnalysisScreen extends StatefulWidget {
  const BodyAnalysisScreen({super.key});

  @override
  State<BodyAnalysisScreen> createState() => _BodyAnalysisScreenState();
}

class _BodyAnalysisScreenState extends State<BodyAnalysisScreen>
    with TickerProviderStateMixin {
  final BodyAnalysisRepository _bodyAnalysisRepository = BodyAnalysisRepository();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  bool _isAnalyzing = false;
  BodyAnalysisModel? _currentAnalysis;
  File? _selectedImage;
  String? _analysisImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        final latestAnalysis = await _bodyAnalysisRepository.getLatestBodyAnalysis(userId);
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
        title: const Text('Análisis Corporal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Analizar', icon: Icon(Icons.camera_alt)),
            Tab(text: 'Resultado', icon: Icon(Icons.analytics)),
            Tab(text: 'Tipos', icon: Icon(Icons.accessibility)),
            Tab(text: 'Formas', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalysisTab(),
          _buildResultsTab(),
          _buildBodyTypesTab(),
          _buildBodyShapesTab(),
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
                              Colors.green,
                              Colors.teal,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.accessibility_new,
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
                              'Análisis Corporal IA',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tipo + Forma + Género',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.green,
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
                    'Analiza tu tipo de cuerpo (ectomorfo, mesomorfo, endomorfo), tu forma corporal y obtén recomendaciones de vestimenta personalizadas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Estado actual del análisis
          if (user?.hasBodyAnalysis == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tienes análisis corporal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🏃 Tipo: ${user?.bodyType ?? 'No especificado'}',
                    style: Theme.of(context).textTheme.bodyMedium,
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
              height: 400,
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

          // Botón de análisis corporal
          CustomButton(
            text: _isAnalyzing ? 'Analizando...' : 'Análisis Corporal IA',
            icon: _isAnalyzing ? null : Icons.accessibility_new,
            onPressed: (_selectedImage != null && !_isAnalyzing) ? _performBodyAnalysis : null,
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
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Para mejores resultados',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('📸', 'Foto de cuerpo completo (cabeza a pies)'),
                  _buildTip('👤', 'Posición frontal y erguida'),
                  _buildTip('👕', 'Ropa ajustada que muestre tu silueta'),
                  _buildTip('💡', 'Buena iluminación uniforme'),
                  _buildTip('📐', 'Fondo simple y despejado'),
                  _buildTip('🚶', 'Brazos ligeramente separados del cuerpo'),
                ],
              ),
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
              Icons.accessibility_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Sin análisis corporal aún',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Realiza tu primer análisis corporal\npara obtener recomendaciones de vestimenta',
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
          // Tarjeta de resultados
          BodyTypeCard(
            analysis: _currentAnalysis!,
            onViewDetails: () => _showDetailedResults(),
          ),

          const SizedBox(height: 24),

          // Recomendaciones de vestimenta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checkroom,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recomendaciones de Vestimenta',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Basadas en tu análisis: ${_currentAnalysis!.getBodyAnalysisDescription()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._currentAnalysis!.getClothingRecommendations().map(
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
                              color: Color(_currentAnalysis!.getBodyTypeColor()),
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

          const SizedBox(height: 16),

          // Colores recomendados
          if (_currentAnalysis!.getColorRecommendations().isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Colores Recomendados',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._currentAnalysis!.getColorRecommendations().map(
                          (color) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.orange, size: 8),
                            const SizedBox(width: 12),
                            Text(color, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildBodyTypesTab() {
    final bodyTypeInfo = RoboflowService.getBodyTypeInfo();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipos de Cuerpo',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conoce los diferentes tipos de cuerpo y sus características',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          ...bodyTypeInfo.entries.map((entry) {
            final typeKey = entry.key;
            final typeData = entry.value;
            final isCurrentType = _currentAnalysis?.bodyType.toLowerCase() == typeKey;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isCurrentType
                    ? Border.all(
                  color: Colors.green,
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
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Tu tipo',
                                style: TextStyle(
                                  color: Colors.green,
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
                      _buildCharacteristicsList('Características:', typeData['characteristics'], typeData['color']),
                      const SizedBox(height: 16),
                      _buildCharacteristicsList('Consejos de vestimenta:', typeData['clothing_tips'], typeData['color']),
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

  Widget _buildBodyShapesTab() {
    final bodyShapeInfo = RoboflowService.getBodyShapeInfo();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formas de Cuerpo',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conoce las diferentes formas de cuerpo y sus estilos',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          ...bodyShapeInfo.entries.map((entry) {
            final shapeKey = entry.key;
            final shapeData = entry.value;
            final isCurrentShape = _currentAnalysis?.bodyShape.toLowerCase() == shapeKey;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isCurrentShape
                    ? Border.all(
                  color: Colors.teal,
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
                                color: Colors.teal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Tu forma',
                                style: TextStyle(
                                  color: Colors.teal,
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
                      _buildCharacteristicsList('Características:', shapeData['characteristics'], shapeData['color']),
                      const SizedBox(height: 16),
                      _buildCharacteristicsList('Consejos de vestimenta:', shapeData['clothing_tips'], shapeData['color']),
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

  Widget _buildCharacteristicsList(String title, List<dynamic> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map<Widget>((item) =>
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
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ),
      ],
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
      final analysis = await _bodyAnalysisRepository.analyzeBodyFromProfilePhoto(
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
          content: Text('¡Análisis corporal completado!'),
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

  Future<void> _performBodyAnalysis() async {
    if (_selectedImage == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await _bodyAnalysisRepository.analyzeBody(
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
          content: Text('¡Análisis corporal completado exitosamente!'),
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

    if (userId == null || _currentAnalysis == null) {
      return;
    }

    try {
      // Guardar en el perfil del usuario
      await _bodyAnalysisRepository.saveAnalysisToUserProfile(
        userId: userId,
        bodyAnalysis: _currentAnalysis!,
      );

      // Actualizar el usuario en el provider
      final updatedUser = authProvider.user!.copyWith(
        bodyType: _currentAnalysis!.bodyType,
        lastBodyAnalysis: _currentAnalysis!.analyzedAt,
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

  void _showDetailedResults() {
    if (_currentAnalysis == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análisis Corporal Detallado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo de cuerpo: ${_currentAnalysis!.bodyType}'),
              Text('Confianza: ${(_currentAnalysis!.bodyTypeConfidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Forma del cuerpo: ${_currentAnalysis!.bodyShape}'),
              Text('Confianza: ${(_currentAnalysis!.bodyShapeConfidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Género detectado: ${_currentAnalysis!.gender}'),
              Text('Confianza: ${(_currentAnalysis!.genderConfidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Fecha: ${_formatDate(_currentAnalysis!.analyzedAt)}'),
              const SizedBox(height: 16),
              Text(_currentAnalysis!.getBodyAnalysisDescription()),
            ],
          ),
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