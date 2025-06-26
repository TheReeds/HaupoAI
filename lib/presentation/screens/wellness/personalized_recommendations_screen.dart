// lib/presentation/screens/wellness/personalized_recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/personalized_recommendations_repository.dart';
import '../../../data/repositories/preference_repository.dart';
import '../../../data/models/personalized_recommendations_model.dart';
import '../../../data/models/preference_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/wellness/recommendation_card.dart';
import '../../widgets/wellness/wellness_score_card.dart';
import '../../widgets/wellness/priority_alert_card.dart';

class PersonalizedRecommendationsScreen extends StatefulWidget {
  const PersonalizedRecommendationsScreen({super.key});

  @override
  State<PersonalizedRecommendationsScreen> createState() =>
      _PersonalizedRecommendationsScreenState();
}

class _PersonalizedRecommendationsScreenState
    extends State<PersonalizedRecommendationsScreen> with TickerProviderStateMixin {

  final PersonalizedRecommendationsRepository _recommendationsRepository =
  PersonalizedRecommendationsRepository();
  final PreferenceRepository _preferenceRepository = PreferenceRepository();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  bool _isGenerating = false;
  PersonalizedRecommendationsModel? _currentRecommendations;
  PreferenceModel? _userPreferences;
  File? _wellnessPhoto;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadExistingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        // Cargar recomendaciones existentes
        final recommendations = await _recommendationsRepository.getLatestRecommendations(userId);

        // Cargar preferencias del usuario
        final preferences = await _preferenceRepository.getPreferences(userId);

        if (mounted) {
          setState(() {
            _currentRecommendations = recommendations;
            _userPreferences = preferences;
          });
        }
      } catch (e) {
        print('Error cargando datos: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recomendaciones Personalizadas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Generar', icon: Icon(Icons.auto_awesome)),
            Tab(text: 'Mis Recomendaciones', icon: Icon(Icons.list_alt)),
            Tab(text: 'Progreso', icon: Icon(Icons.trending_up)),
            Tab(text: 'Análisis', icon: Icon(Icons.analytics_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(),
          _buildRecommendationsTab(),
          _buildProgressTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header explicativo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente Personal de Bienestar',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'IA + Análisis Personal',
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
                    'Genera recomendaciones ultra-personalizadas basadas en tus análisis de rostro, cabello, cuerpo y preferencias personales.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Verificar análisis completos
          _buildAnalysisStatusCheck(user),

          const SizedBox(height: 24),

          // Foto de bienestar opcional
          _buildWellnessPhotoSection(),

          const SizedBox(height: 24),

          // Botón de generación
          _buildGenerateButton(user),

          const SizedBox(height: 32),

          // Información sobre qué incluye
          _buildWhatIncludesSection(),
        ],
      ),
    );
  }

  Widget _buildAnalysisStatusCheck(user) {
    final hasCompleteAnalysis = user?.hasCompleteAnalysis ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasCompleteAnalysis ? Icons.check_circle : Icons.warning,
                  color: hasCompleteAnalysis ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Estado de tus análisis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildAnalysisItem(
              '👤 Análisis Facial',
              user?.hasFaceAnalysis ?? false,
                  () => context.go('/face-analysis'),
            ),
            _buildAnalysisItem(
              '✂️ Análisis de Cabello',
              user?.hasHairAnalysis ?? false,
                  () => context.go('/face-analysis'),
            ),
            _buildAnalysisItem(
              '🏃 Análisis Corporal',
              user?.hasBodyAnalysis ?? false,
                  () => context.go('/body-analysis'),
            ),

            if (!hasCompleteAnalysis) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Necesitas completar todos los análisis para obtener recomendaciones personalizadas',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String title, bool completed, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (!completed)
            TextButton(
              onPressed: onTap,
              child: const Text('Realizar'),
            ),
        ],
      ),
    );
  }

  Widget _buildWellnessPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Foto de Bienestar (Opcional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sube una foto de tu rostro para detectar signos de cansancio, estado de la piel y obtener recomendaciones de cuidado específicas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            if (_wellnessPhoto != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_wellnessPhoto!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _wellnessPhoto = null),
                      icon: const Icon(Icons.delete),
                      label: const Text('Quitar foto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickWellnessPhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cambiar'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickWellnessPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar foto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickWellnessPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(user) {
    final canGenerate = user?.hasCompleteAnalysis ?? false;

    return CustomButton(
      text: _isGenerating ? 'Generando recomendaciones...' : 'Generar Recomendaciones IA',
      icon: _isGenerating ? null : Icons.auto_awesome,
      onPressed: canGenerate && !_isGenerating ? _generateRecommendations : null,
      width: double.infinity,
      isLoading: _isGenerating,
    );
  }

  Widget _buildWhatIncludesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué incluyen las recomendaciones?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildIncludeItem('💇‍♀️', 'Estilos de cabello específicos'),
            _buildIncludeItem('👗', 'Recomendaciones de vestimenta'),
            _buildIncludeItem('🎨', 'Paleta de colores personalizada'),
            _buildIncludeItem('🧴', 'Rutinas de cuidado personal'),
            _buildIncludeItem('💪', 'Plan de ejercicios adaptado'),
            _buildIncludeItem('🥗', 'Consejos nutricionales'),
            _buildIncludeItem('🧘‍♀️', 'Recomendaciones de bienestar'),
            _buildIncludeItem('📊', 'Análisis de tu progreso'),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludeItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
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

  Widget _buildRecommendationsTab() {
    if (_currentRecommendations == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Sin recomendaciones aún',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Genera tus primeras recomendaciones\npersonalizadas para comenzar',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Generar Recomendaciones',
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
          // Puntuaciones de bienestar
          WellnessScoreCard(recommendations: _currentRecommendations!),

          const SizedBox(height: 16),

          // Alertas prioritarias
          ...(_currentRecommendations!.getHealthAlerts().map((alert) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PriorityAlertCard(alert: alert),
              ),
          )),

          // Recomendaciones por categoría
          _buildCategorySection('Estilo de Cabello',
              _currentRecommendations!.hairStyleRecommendations, Icons.content_cut),

          _buildCategorySection('Vestimenta',
              _currentRecommendations!.clothingRecommendations, Icons.checkroom),

          _buildCategorySection('Colores Personales',
              _currentRecommendations!.colorRecommendations, Icons.palette),

          _buildCategorySection('Cuidado de la Piel',
              _currentRecommendations!.skinCareRecommendations, Icons.spa),

          _buildCategorySection('Cuidado del Cabello',
              _currentRecommendations!.hairCareRecommendations, Icons.face_retouching_natural),

          _buildCategorySection('Ejercicio',
              _currentRecommendations!.exerciseRecommendations, Icons.fitness_center),

          _buildCategorySection('Nutrición',
              _currentRecommendations!.nutritionRecommendations, Icons.restaurant),

          _buildCategorySection('Estilo de Vida',
              _currentRecommendations!.lifestyleRecommendations, Icons.line_style),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareRecommendations,
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportReport,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Exportar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<String> recommendations, IconData icon) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RecommendationCard(
        title: title,
        icon: icon,
        recommendations: recommendations,
        onRecommendationTap: (index) => _markRecommendationAsFollowed(title, index),
      ),
    );
  }

  Widget _buildProgressTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            'Progreso y Tendencias',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Visualiza tu evolución y progreso\nen bienestar y estilo personal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 32),
          Text(
            '📈 Próximamente disponible',
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.purple),
          SizedBox(height: 24),
          Text(
            'Análisis Avanzado',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Análisis profundo de tus datos\ny patrones de bienestar personal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 32),
          Text(
            '🔬 En desarrollo',
            style: TextStyle(fontSize: 18, color: Colors.purple),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWellnessPhoto([ImageSource? source]) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source ?? ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _wellnessPhoto = File(image.path);
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

  Future<void> _generateRecommendations() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null || _userPreferences == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Datos de usuario no disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final recommendations = await _recommendationsRepository.generateAndSaveRecommendations(
        user: user,
        preferences: _userPreferences!,
        wellnessPhoto: _wellnessPhoto,
      );

      setState(() {
        _currentRecommendations = recommendations;
        _wellnessPhoto = null; // Limpiar foto después de usar
        _isGenerating = false;
      });

      // Cambiar a la pestaña de recomendaciones
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Recomendaciones generadas exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando recomendaciones: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _markRecommendationAsFollowed(String category, int index) {
    if (_currentRecommendations == null) return;

    _recommendationsRepository.markRecommendationAsFollowed(
      _currentRecommendations!.id,
      category,
      index,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Recomendación marcada como seguida!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareRecommendations() {
    if (_currentRecommendations == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente'),
      ),
    );
  }

  void _exportReport() async {
    if (_currentRecommendations == null) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.uid;

      if (userId == null) return;

      final report = await _recommendationsRepository.exportRecommendationsReport(userId);

      // Aquí podrías implementar la exportación real (PDF, email, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte exportado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exportando reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}