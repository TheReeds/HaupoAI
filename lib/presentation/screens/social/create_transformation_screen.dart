// lib/presentation/screens/social/create_transformation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/common/before_after_slider.dart';

class CreateTransformationScreen extends StatefulWidget {
  const CreateTransformationScreen({super.key});

  @override
  State<CreateTransformationScreen> createState() => _CreateTransformationScreenState();
}

class _CreateTransformationScreenState extends State<CreateTransformationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final ChatRepository _chatRepository = ChatRepository();
  final ImagePicker _imagePicker = ImagePicker();

  File? _beforeImage;
  File? _afterImage;
  String _selectedTransformationType = 'style';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, Map<String, dynamic>> _transformationTypes = {
    'haircut': {
      'name': 'Corte de Cabello',
      'icon': Icons.content_cut_rounded,
      'color': const Color(0xFF6366F1),
    },
    'outfit': {
      'name': 'Cambio de Look',
      'icon': Icons.checkroom_rounded,
      'color': const Color(0xFF10B981),
    },
    'makeup': {
      'name': 'Maquillaje',
      'icon': Icons.face_rounded,
      'color': const Color(0xFFEC4899),
    },
    'weight': {
      'name': 'Transformación Física',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFFF59E0B),
    },
    'style': {
      'name': 'Cambio de Estilo',
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF8B5CF6),
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Transformación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/transformations'),
        ),
        actions: [
          if (_beforeImage != null && _afterImage != null)
            TextButton(
              onPressed: _isLoading ? null : _publishTransformation,
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Publicar'),
            ),
        ],
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header inspiracional
                  _buildHeader(context),
                  const SizedBox(height: 32),

                  // Selección de tipo de transformación
                  _buildTransformationTypeSelector(context),
                  const SizedBox(height: 32),

                  // Selector de imágenes
                  _buildImageSelector(context),
                  const SizedBox(height: 32),

                  // Preview de transformación
                  if (_beforeImage != null && _afterImage != null)
                    _buildTransformationPreview(context),

                  // Formulario de detalles
                  if (_beforeImage != null && _afterImage != null) ...[
                    const SizedBox(height: 32),
                    _buildDetailsForm(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.transform_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Comparte tu transformación!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Inspira a otros con tu increíble cambio',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransformationTypeSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de transformación',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _transformationTypes.entries.map((entry) {
            final isSelected = _selectedTransformationType == entry.key;
            final typeData = entry.value;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTransformationType = entry.key;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? typeData['color'].withOpacity(0.2)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? typeData['color']
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      typeData['icon'],
                      color: isSelected
                          ? typeData['color']
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typeData['name'],
                      style: TextStyle(
                        color: isSelected
                            ? typeData['color']
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos de tu transformación',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Necesitas una foto del ANTES y otra del DESPUÉS',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Imagen ANTES
            Expanded(
              child: _buildImagePickerCard(
                'ANTES',
                _beforeImage,
                colorScheme.error,
                    () => _pickImage(true),
              ),
            ),
            const SizedBox(width: 16),
            // Imagen DESPUÉS
            Expanded(
              child: _buildImagePickerCard(
                'DESPUÉS',
                _afterImage,
                colorScheme.primary,
                    () => _pickImage(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePickerCard(
      String label,
      File? image,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
            style: image == null ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: image != null
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (label == 'ANTES') {
                      _beforeImage = null;
                    } else {
                      _afterImage = null;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca para agregar',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransformationPreview(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vista previa',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        BeforeAfterSlider(
          beforeImageUrl: _beforeImage!.path,
          afterImageUrl: _afterImage!.path,
          height: 300,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.swipe_left_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Desliza para comparar las imágenes. ¡Así es como otros verán tu transformación!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsForm(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles de la transformación',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Título
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Título de tu transformación',
            hintText: 'Ej: Mi increíble cambio de look',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El título es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Descripción
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Cuéntanos sobre tu transformación',
            hintText: 'Describe qué cambió, cómo te sientes, consejos para otros...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descripción es requerida';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Tags
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: 'Tags (opcional)',
            hintText: 'Separados por comas: cabello, corte, moderno',
            border: OutlineInputBorder(),
            helperText: 'Los tags ayudan a otros usuarios a encontrar tu transformación',
          ),
        ),
        const SizedBox(height: 32),

        // Botón de publicar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _publishTransformation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Publicando...'),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_transformationTypes[_selectedTransformationType]!['icon']),
                const SizedBox(width: 12),
                const Text(
                  'Publicar Transformación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(bool isBefore) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isBefore) {
            _beforeImage = File(image.path);
          } else {
            _afterImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _publishTransformation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_beforeImage == null || _afterImage == null) {
      _showErrorSnackBar('Debes seleccionar ambas imágenes');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Procesar tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Crear el post de transformación
      final postId = await _chatRepository.createTransformationPost(
        userId: user.uid,
        userName: user.displayName ?? 'Usuario',
        userPhotoURL: user.photoURL,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        beforeImage: _beforeImage!,
        afterImage: _afterImage!,
        transformationType: _selectedTransformationType,
        tags: tags,
        analyticsData: {
          'createdAt': DateTime.now().toIso8601String(),
          'platform': 'mobile',
        },
      );

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('¡Transformación publicada exitosamente!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navegar de vuelta con un pequeño delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/transformations');
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al publicar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}