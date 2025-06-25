import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../../data/repositories/social_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final SocialRepository _socialRepository = SocialRepository();
  final ImagePicker _imagePicker = ImagePicker();

  List<File> _selectedImages = [];
  Set<String> _selectedTags = {};
  bool _isLoading = false;

  final List<String> _availableTags = [
    'casual', 'elegante', 'deportivo', 'bohemio', 'minimalista',
    'vintage', 'urbano', 'romántico', 'rockero', 'preppy',
    'verano', 'invierno', 'primavera', 'otoño', 'formal',
    'fiesta', 'trabajo', 'cita', 'weekend', 'viaje',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Publicación'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ElevatedButton(
              onPressed: _canPost() ? _createPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canPost()
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Publicar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usuario
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.user;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Descripción
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: '¿Qué tal tu look de hoy?',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 18),
              ),
              style: const TextStyle(fontSize: 18),
              maxLines: null,
              minLines: 3,
              maxLength: 1000,
            ),

            const SizedBox(height: 24),

            // Imágenes seleccionadas
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'Fotos (${_selectedImages.length}/10)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return _buildAddImageButton();
                    }
                    return _buildImagePreview(_selectedImages[index], index);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              _buildAddImageSection(),
              const SizedBox(height: 24),
            ],

            // Tags
            Text(
              'Etiquetas (${_selectedTags.length}/5)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text('#$tag'),
                  selected: isSelected,
                  onSelected: _selectedTags.length < 5 || isSelected
                      ? (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  }
                      : null,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Consejos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Consejos para tu publicación',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Usa buena iluminación natural\n'
                        '• Incluye detalles de tu outfit\n'
                        '• Agrega etiquetas relevantes\n'
                        '• Sé auténtico y creativo',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageSection() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Agregar fotos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para seleccionar hasta 10 imágenes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _selectedImages.length < 10 ? _pickImages : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedImages.length < 10
                  ? Theme.of(context).colorScheme.outline
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.add,
            color: _selectedImages.length < 10
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(File image, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              image,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        final remainingSlots = 10 - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(
            imagesToAdd.map((xFile) => File(xFile.path)),
          );
        });

        if (images.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solo se pueden agregar ${remainingSlots} imágenes más'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imágenes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  bool _canPost() {
    return _descriptionController.text.trim().isNotEmpty && !_isLoading;
  }

  Future<void> _createPost() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _socialRepository.createPost(
        userId: user.uid,
        userName: user.displayName ?? 'Usuario',
        userPhotoURL: user.photoURL,
        description: _descriptionController.text.trim(),
        images: _selectedImages,
        tags: _selectedTags.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear publicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showExitDialog() {
    if (_descriptionController.text.trim().isNotEmpty || _selectedImages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar publicación?'),
          content: const Text('Perderás todo el contenido de esta publicación.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/feed');
              },
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      context.go('/feed');
    }
  }
}