// lib/core/services/image_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';

class ImageSearchService {
  // Usando Unsplash API para búsqueda de imágenes de alta calidad
  static const String _unsplashBaseUrl = 'https://api.unsplash.com';
  static const String _unsplashAccessKey = 'JwVvI7LYhAipw46rRM3Z2BdtC0iEHwAItg_EBorOtRA'; // Necesitas registrarte en Unsplash

  // Alternativa: Usar Pixabay API (más fácil de configurar)
  static const String _pixabayBaseUrl = 'https://pixabay.com/api/';
  static const String _pixabayApiKey = '51066928-331a8186ba99a1d4c9a809051'; // API key pública de ejemplo

  // Buscar imágenes de peinados usando Pixabay
  Future<List<Map<String, dynamic>>> searchHairstyleImages(
      String hairstyleName, {
        int limit = 3,
      }) async {
    try {
      final searchQuery = _createOptimizedSearchQuery(hairstyleName);

      final url = Uri.parse('$_unsplashBaseUrl/search/photos').replace(queryParameters: {
        'query': searchQuery,
        'per_page': limit.toString(),
      });

      print('🔎 Buscando (Unsplash): $searchQuery');
      print('🌐 URL: $url');

      final response = await http.get(url, headers: {
        'Authorization': 'Client-ID $_unsplashAccessKey',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((item) => {
          'id': item['id'],
          'url': item['urls']['regular'],
          'preview': item['urls']['thumb'],
          'tags': item['alt_description'] ?? hairstyleName,
          'user': item['user']['name'],
          'description': _generateImageDescription(hairstyleName),
        }).toList();
      } else {
        throw AppException('Error en búsqueda de imágenes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error buscando imágenes (Unsplash): $e');
      return _getFallbackImages(hairstyleName);
    }
  }



  // Crear query optimizado para diferentes tipos de cortes
  String _createOptimizedSearchQuery(String hairstyleName) {
    final normalizedName = hairstyleName.toLowerCase();

    // Mapear nombres técnicos a términos de búsqueda más efectivos
    final searchMappings = {
      'fade': 'men fade haircut barbershop',
      'low fade': 'low fade haircut men',
      'mid fade': 'mid fade haircut men',
      'high fade': 'high fade haircut men',
      'skin fade': 'skin fade haircut men',
      'drop fade': 'drop fade haircut men',
      'buzz cut': 'buzz cut men short hair',
      'crew cut': 'crew cut men haircut',
      'pompadour': 'pompadour hairstyle men',
      'undercut': 'undercut hairstyle men',
      'quiff': 'quiff hairstyle men',
      'slick back': 'slicked back hair men',
      'textured crop': 'textured crop haircut men',
      'caesar cut': 'caesar haircut men',
      'ivy league': 'ivy league haircut men',
      'side part': 'side part hairstyle men',
      'messy': 'messy hairstyle men',
      'spiky': 'spiky hair men',
      'man bun': 'man bun hairstyle',
      'top knot': 'top knot men hairstyle',
    };

    // Buscar coincidencias en el mapeo
    for (final mapping in searchMappings.entries) {
      if (normalizedName.contains(mapping.key)) {
        return mapping.value;
      }
    }

    // Si no encuentra mapeo específico, usar el nombre original + términos genéricos
    return '$hairstyleName men haircut hairstyle';
  }

  // Generar descripción contextual para la imagen
  String _generateImageDescription(String hairstyleName) {
    final descriptions = {
      'fade': 'Corte degradado que va de largo a corto gradualmente',
      'low fade': 'Degradado bajo que comienza cerca de las orejas',
      'mid fade': 'Degradado medio que comienza a media altura',
      'high fade': 'Degradado alto que comienza cerca de la coronilla',
      'buzz cut': 'Corte muy corto y uniforme en toda la cabeza',
      'crew cut': 'Corte militar clásico, corto pero no rapado',
      'pompadour': 'Cabello peinado hacia atrás con volumen en la frente',
      'undercut': 'Laterales muy cortos con la parte superior larga',
      'quiff': 'Estilo con volumen y textura en la parte frontal',
      'slick back': 'Cabello completamente peinado hacia atrás',
    };

    for (final desc in descriptions.entries) {
      if (hairstyleName.toLowerCase().contains(desc.key)) {
        return desc.value;
      }
    }

    return 'Estilo de corte moderno y actual';
  }

  // Imágenes de respaldo en caso de que falle la búsqueda
  List<Map<String, dynamic>> _getFallbackImages(String hairstyleName) {
    return [
      {
        'id': 'fallback_1',
        'url': 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=400',
        'preview': 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=200',
        'tags': 'men haircut hairstyle',
        'user': 'Unsplash',
        'description': 'Corte de cabello moderno',
      },
      {
        'id': 'fallback_2',
        'url': 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
        'preview': 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=200',
        'tags': 'men haircut fade',
        'user': 'Unsplash',
        'description': 'Estilo fade moderno',
      },
      {
        'id': 'fallback_3',
        'url': 'https://images.unsplash.com/photo-1588516903720-8ceb67f9ef84?w=400',
        'preview': 'https://images.unsplash.com/photo-1588516903720-8ceb67f9ef84?w=200',
        'tags': 'men hairstyle barbershop',
        'user': 'Unsplash',
        'description': 'Corte de barbería clásico',
      },
    ];
  }

  // Buscar múltiples estilos de una vez
  Future<Map<String, List<Map<String, dynamic>>>> searchMultipleHairstyles(
      List<String> hairstyleNames,
      ) async {
    final results = <String, List<Map<String, dynamic>>>{};

    for (final styleName in hairstyleNames) {
      try {
        final images = await searchHairstyleImages(styleName, limit: 3);
        results[styleName] = images;

        // Pequeño delay para evitar rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error buscando imágenes para $styleName: $e');
        results[styleName] = _getFallbackImages(styleName).take(2).toList();
      }
    }

    return results;
  }

  // Validar si el servicio está disponible
  Future<bool> isServiceAvailable() async {
    try {
      final url = Uri.parse(_pixabayBaseUrl).replace(queryParameters: {
        'key': _pixabayApiKey,
        'q': 'test',
        'per_page': '1',
      });

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}