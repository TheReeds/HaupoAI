// lib/presentation/screens/profile/edit_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/preference_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/preferences/color_selector.dart';
import '../../widgets/preferences/style_selector.dart';
import '../../../data/repositories/preference_repository.dart';
import '../../../data/models/preference_model.dart';

class EditPreferencesScreen extends StatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PreferenceRepository _preferenceRepository = PreferenceRepository();

  // Estado de carga
  bool _isLoading = true;
  bool _isSaving = false;

  // Preferencias actuales
  PreferenceModel? _currentPreferences;

  // Preferencias temporales (para editar)
  String? _selectedGender;
  String? _selectedSkinTone;
  Set<String> _selectedColors = {};
  Set<String> _selectedStyles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPreferences() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final preferences = await _preferenceRepository.getPreferences(userId);

        if (preferences != null) {
          setState(() {
            _currentPreferences = preferences;
            _selectedGender = preferences.gender;
            _selectedSkinTone = preferences.skinTone;
            _selectedColors = preferences.favoriteColors.toSet();
            _selectedStyles = preferences.favoriteStyles.toSet();
            _isLoading = false;
          });
        } else {
          // No hay preferencias guardadas, usar valores por defecto
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar preferencias: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _savePreferences() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final preferences = _currentPreferences?.copyWith(
        gender: _selectedGender,
        skinTone: _selectedSkinTone,
        favoriteColors: _selectedColors.toList(),
        favoriteStyles: _selectedStyles.toList(),
        updatedAt: DateTime.now(),
      ) ?? PreferenceModel.fromSetup(
        userId: userId,
        gender: _selectedGender,
        skinTone: _selectedSkinTone,
        selectedColors: _selectedColors,
        selectedStyles: _selectedStyles,
      );

      if (_currentPreferences != null) {
        await _preferenceRepository.updatePreferences(preferences);
      } else {
        await _preferenceRepository.savePreferences(preferences);
      }

      setState(() {
        _currentPreferences = preferences;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencias guardadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar preferencias: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasChanges() {
    if (_currentPreferences == null) {
      return _selectedGender != null ||
          _selectedSkinTone != null ||
          _selectedColors.isNotEmpty ||
          _selectedStyles.isNotEmpty;
    }

    return _selectedGender != _currentPreferences!.gender ||
        _selectedSkinTone != _currentPreferences!.skinTone ||
        !_setEquals(_selectedColors, _currentPreferences!.favoriteColors.toSet()) ||
        !_setEquals(_selectedStyles, _currentPreferences!.favoriteStyles.toSet());
  }

  bool _setEquals<T>(Set<T> set1, Set<T> set2) {
    return set1.length == set2.length && set1.containsAll(set2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Preferencias'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        bottom: _isLoading ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Género'),
            Tab(text: 'Piel'),
            Tab(text: 'Colores'),
            Tab(text: 'Estilos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGenderTab(),
                _buildSkinToneTab(),
                _buildColorsTab(),
                _buildStylesTab(),
              ],
            ),
          ),

          // Botones de acción
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    onPressed: () => context.go('/profile'),
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Guardar',
                    onPressed: _hasChanges() ? _savePreferences : null,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Género',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona tu género para personalizar mejor las recomendaciones',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ...['Masculino', 'Femenino', 'No binario', 'Prefiero no decir'].map(
                (gender) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _selectedGender == gender
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    foregroundColor: _selectedGender == gender
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                    side: BorderSide(
                      color: _selectedGender == gender
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    gender,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinToneTab() {
    final skinTones = [
      {'name': 'Muy claro', 'color': const Color(0xFFFDBCB4)},
      {'name': 'Claro', 'color': const Color(0xFFEEA990)},
      {'name': 'Medio claro', 'color': const Color(0xFFE1955B)},
      {'name': 'Medio', 'color': const Color(0xFFCB8442)},
      {'name': 'Oscuro', 'color': const Color(0xFF8B5A2B)},
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tono de piel',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona tu tono de piel para recomendaciones de colores más precisas',
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 3 : 1,
                      ),
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

  Widget _buildColorsTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Colores favoritos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona los colores que más te gustan usar',
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

  Widget _buildStylesTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estilos favoritos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona los estilos que más te representan',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
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
        ],
      ),
    );
  }
}