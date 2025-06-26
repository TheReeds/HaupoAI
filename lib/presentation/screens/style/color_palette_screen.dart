// lib/presentation/screens/style/color_palette_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../../core/services/chatbot_service.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/preference_repository.dart';
import '../../../data/models/color_palette_model.dart';
import '../../../data/models/preference_model.dart';

class ColorPaletteScreen extends StatefulWidget {
  const ColorPaletteScreen({super.key});

  @override
  State<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends State<ColorPaletteScreen>
    with TickerProviderStateMixin {
  final ChatbotService _chatbotService = ChatbotService();
  final ChatRepository _chatRepository = ChatRepository();
  final PreferenceRepository _preferenceRepository = PreferenceRepository();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ColorPaletteModel? _currentPalette;
  PreferenceModel? _userPreferences;
  bool _isGenerating = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

  Future<void> _initializeScreen() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    try {
      // Cargar preferencias del usuario
      _userPreferences = await _preferenceRepository.getPreferences(user.uid);

      // Cargar paleta existente si la hay
      _currentPalette = await _chatRepository.getLatestUserColorPalette(user.uid);

      setState(() {
        _isInitialized = true;
      });

      // Si no hay paleta, generar una automáticamente
      if (_currentPalette == null) {
        _generateColorPalette();
      }
    } catch (e) {
      print('Error inicializando pantalla: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tu Paleta Personal'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analizando tu estilo personal...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Paleta Personal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isGenerating ? null : _generateColorPalette,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'save':
                  _savePalette();
                  break;
                case 'share':
                  _sharePalette();
                  break;
                case 'history':
                  _showPaletteHistory();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save_outlined),
                  title: Text('Guardar paleta'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Compartir'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history_rounded),
                  title: Text('Ver historial'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _currentPalette != null
              ? _buildPaletteContent(context)
              : _buildEmptyState(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generateColorPalette,
        icon: _isGenerating
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(_isGenerating ? 'Generando...' : 'Nueva Paleta'),
      ),
    );
  }

  Widget _buildPaletteContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header personalizado
          _buildPaletteHeader(context),
          const SizedBox(height: 32),

          // Colores que favorecen
          _buildColorSection(
            context,
            'Colores que te favorecen',
            _currentPalette!.idealColors,
            colorScheme.primary,
            Icons.favorite_rounded,
          ),
          const SizedBox(height: 32),

          // Colores a evitar
          _buildColorSection(
            context,
            'Colores a evitar',
            _currentPalette!.avoidColors,
            colorScheme.error,
            Icons.block_rounded,
          ),
          const SizedBox(height: 32),

          // Combinaciones recomendadas
          _buildCombinationsSection(context),
          const SizedBox(height: 32),

          // Explicación de la IA
          _buildAIExplanation(context),
          const SizedBox(height: 32),

          // Consejos de uso
          _buildUsageTips(context),

          const SizedBox(height: 100), // Espacio para FAB
        ],
      ),
    );
  }

  Widget _buildPaletteHeader(BuildContext context) {
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
            colorScheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentPalette!.paletteName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Creada especialmente para ti',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Esta paleta está basada en tu análisis personal y preferencias de estilo.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(
      BuildContext context,
      String title,
      List<String> colors,
      Color accentColor,
      IconData icon,
      ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid de colores
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final colorHex = colors[index];
            final color = _hexToColor(colorHex);

            return GestureDetector(
              onTap: () => _showColorDetail(colorHex, color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Color name en el centro
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getContrastColor(color),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getColorName(colorHex),
                          style: TextStyle(
                            color: _getTextColor(color),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCombinationsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.style_rounded,
                color: colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Combinaciones perfectas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...(_currentPalette!.combinations).map((combination) {
          final combinationColors = List<String>.from(combination['colors'] ?? []);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  combination['name'] ?? 'Combinación',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: combinationColors.map((colorHex) {
                    return Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _hexToColor(colorHex),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAIExplanation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Análisis de HuapoAI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentPalette!.reasoning,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSecondaryContainer.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tips = [
      '💡 Usa los colores ideales cerca de tu rostro para resaltar tu belleza natural',
      '✨ Combina máximo 3 colores de tu paleta en un solo outfit',
      '🎨 Los colores neutros de tu paleta son perfectos como base',
      '👗 Evita los colores marcados como "a evitar" en prendas principales',
      '💄 Estos colores también funcionan perfectamente para maquillaje',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tips_and_updates_rounded,
                color: colorScheme.onTertiaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Consejos de uso',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...tips.map((tip) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            tip,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 64,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Genera tu paleta personalizada',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Descubre los colores que mejor te quedan basados en tu análisis personal.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateColorPalette,
              icon: _isGenerating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_isGenerating ? 'Generando...' : 'Generar paleta'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateColorPalette() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Generar paleta usando el chatbot
      final paletteData = await _chatbotService.generateColorPalette(
        user,
        _userPreferences,
      );

      // Crear modelo de paleta
      final palette = ColorPaletteModel.fromAIResponse(
        userId: user.uid,
        aiResponse: paletteData['response'],
        analysisData: {
          'userAnalysis': {
            'faceShape': user.currentFaceShape,
            'bodyType': user.bodyType,
          },
          'preferences': _userPreferences?.toFirestore(),
          'generatedAt': DateTime.now().toIso8601String(),
        },
      );

      // Guardar en Firestore
      final paletteId = await _chatRepository.saveColorPalette(palette);

      // Actualizar paleta actual
      setState(() {
        _currentPalette = palette.copyWith(id: paletteId);
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('¡Nueva paleta generada exitosamente!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print('Error generando paleta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar paleta: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showColorDetail(String colorHex, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(_getColorName(colorHex)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: $colorHex'),
            const SizedBox(height: 8),
            Text('RGB: ${color.red}, ${color.green}, ${color.blue}'),
            const SizedBox(height: 16),
            Text(
              'Este color está especialmente seleccionado para complementar tu tono de piel y estilo personal.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              // Copiar al portapapeles
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Color $colorHex copiado'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copiar código'),
          ),
        ],
      ),
    );
  }

  void _savePalette() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paleta guardada en tus favoritos'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sharePalette() {
    // Implementar compartir paleta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir disponible pronto'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPaletteHistory() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Historial de paletas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: StreamBuilder<List<ColorPaletteModel>>(
                    stream: _chatRepository.getUserColorPalettes(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final palettes = snapshot.data ?? [];

                      if (palettes.isEmpty) {
                        return const Center(
                          child: Text('No hay paletas guardadas aún'),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: palettes.length,
                        itemBuilder: (context, index) {
                          final palette = palettes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: palette.idealColors.take(3).map((colorHex) {
                                  return Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: _hexToColor(colorHex),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              ),
                              title: Text(palette.paletteName),
                              subtitle: Text(
                                'Creada el ${_formatDate(palette.createdAt)}',
                              ),
                              trailing: palette.id == _currentPalette?.id
                                  ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _currentPalette = palette;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// Utility methods
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5
        ? Colors.black.withOpacity(0.7)
        : Colors.white.withOpacity(0.9);
  }

  Color _getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  String _getColorName(String colorHex) {
    // Simplified color naming - en una app real usarías una librería más completa
    final colorMap = {
      '#FF0000': 'Rojo',
      '#00FF00': 'Verde',
      '#0000FF': 'Azul',
      '#FFFF00': 'Amarillo',
      '#FF00FF': 'Magenta',
      '#00FFFF': 'Cian',
      '#000000': 'Negro',
      '#FFFFFF': 'Blanco',
    };

    return colorMap[colorHex.toUpperCase()] ?? colorHex;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}