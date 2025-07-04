// lib/presentation/screens/auth/setup_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/preferences/color_selector.dart';
import '../../widgets/preferences/style_selector.dart';
import '../../widgets/preferences/gender_selector.dart';

class SetupPreferencesScreen extends StatefulWidget {
  const SetupPreferencesScreen({super.key});

  @override
  State<SetupPreferencesScreen> createState() => _SetupPreferencesScreenState();
}

class _SetupPreferencesScreenState extends State<SetupPreferencesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Preferencias seleccionadas
  final Set<String> _selectedColors = {};
  final Set<String> _selectedStyles = {};
  String? _selectedSkinTone;
  String? _selectedGender;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    final authProvider = context.read<AuthProvider>();

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await authProvider.completeOnboarding(
        gender: _selectedGender,
        skinTone: _selectedSkinTone,
        selectedColors: _selectedColors,
        selectedStyles: _selectedStyles,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        if (success) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Configuración completada exitosamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Pequeño delay para asegurar que el estado se actualice
          await Future.delayed(const Duration(milliseconds: 500));

          // Forzar navegación si el router no redirije automáticamente
          if (mounted && context.canPop()) {
            context.go('/home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Error al guardar preferencias',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _skipSetup() async {
    final authProvider = context.read<AuthProvider>();

    // Mostrar confirmación
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saltar configuración'),
        content: const Text(
          '¿Estás seguro de que quieres saltar la configuración? '
              'Puedes completarla más tarde desde tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Saltar'),
          ),
        ],
      ),
    );

    if (shouldSkip == true && mounted) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Completar onboarding sin preferencias
      final success = await authProvider.completeOnboarding();

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        if (success) {
          // Pequeño delay para asegurar que el estado se actualice
          await Future.delayed(const Duration(milliseconds: 500));

          // Forzar navegación si el router no redirije automáticamente
          if (mounted && context.canPop()) {
            context.go('/home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Error al completar configuración',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: // Género
        return _selectedGender != null;
      case 1: // Tono de piel
        return _selectedSkinTone != null;
      case 2: // Colores
        return _selectedColors.isNotEmpty;
      case 3: // Estilos
        return _selectedStyles.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con progreso
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back),
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          'Configurar preferencias',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: _skipSetup,
                        child: const Text('Saltar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 4,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildGenderPage(),
                  _buildSkinTonePage(),
                  _buildColorPreferencesPage(),
                  _buildStylePreferencesPage(),
                ],
              ),
            ),

            // Botón de continuar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return CustomButton(
                    text: _currentPage == 3 ? 'Finalizar' : 'Continuar',
                    onPressed: _canProceed() ? _nextPage : null,
                    width: double.infinity,
                    isLoading: authProvider.isLoading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GenderSelector(
        selectedGender: _selectedGender,
        onGenderSelected: (gender) {
          setState(() {
            _selectedGender = gender;
          });
        },
      ),
    );
  }

  Widget _buildSkinTonePage() {
    final skinTones = [
      {'name': 'Muy claro', 'color': const Color(0xFFFDBCB4)},
      {'name': 'Claro', 'color': const Color(0xFFEEA990)},
      {'name': 'Medio claro', 'color': const Color(0xFFE1955B)},
      {'name': 'Medio', 'color': const Color(0xFFCB8442)},
      {'name': 'Medio oscuro', 'color': const Color(0xFFAD7A47)},
      {'name': 'Oscuro', 'color': const Color(0xFF8B5A2B)},
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuál es tu tono de piel?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esto nos ayudará a recomendarte colores que resalten tu belleza natural',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: skinTones.length,
              itemBuilder: (context, index) {
                final skinTone = skinTones[index];
                final isSelected = _selectedSkinTone == skinTone['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSkinTone = skinTone['name'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: skinTone['color'] as Color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          skinTone['name'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : null,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué colores te gustan?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona los colores que más te gustan usar (mínimo 1)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ColorSelector(
              selectedColors: _selectedColors,
              onColorToggle: (color) {
                setState(() {
                  if (_selectedColors.contains(color)) {
                    _selectedColors.remove(color);
                  } else {
                    _selectedColors.add(color);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuál es tu estilo?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Desliza y selecciona los estilos que más te representan',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Indicador de páginas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe_left,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Desliza para ver más estilos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StyleSelector(
              selectedStyles: _selectedStyles,
              onStyleToggle: (style) {
                setState(() {
                  if (_selectedStyles.contains(style)) {
                    _selectedStyles.remove(style);
                  } else {
                    _selectedStyles.add(style);
                  }
                });
              },
            ),
          ),
          // Contador de selecciones
          if (_selectedStyles.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedStyles.length} estilo${_selectedStyles.length == 1 ? '' : 's'} seleccionado${_selectedStyles.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}