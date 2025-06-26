// lib/core/config/api_config.dart
class ApiConfig {
  // Pixabay API para búsqueda de imágenes
  static const String pixabayApiKey = '51066928-331a8186ba99a1d4c9a809051';
  static const String pixabayBaseUrl = 'https://pixabay.com/api/';

  // Unsplash API (alternativa premium)
  static const String unsplashAccessKey = 'YOUR_UNSPLASH_ACCESS_KEY';
  static const String unsplashBaseUrl = 'https://api.unsplash.com';

  // Configuración de búsqueda de imágenes
  static const int defaultImageLimit = 3;
  static const int minImageWidth = 400;
  static const int minImageHeight = 600;

  // Términos de búsqueda optimizados para peinados
  static const Map<String, String> hairstyleSearchTerms = {
    'fade': 'men fade haircut barbershop professional',
    'low fade': 'low fade haircut men barbershop',
    'mid fade': 'mid fade haircut men professional',
    'high fade': 'high fade haircut men modern',
    'skin fade': 'skin fade haircut men barbershop',
    'drop fade': 'drop fade haircut men style',
    'buzz cut': 'buzz cut men short hair military',
    'crew cut': 'crew cut men haircut classic',
    'pompadour': 'pompadour hairstyle men vintage modern',
    'undercut': 'undercut hairstyle men fashion',
    'quiff': 'quiff hairstyle men textured',
    'slick back': 'slicked back hair men formal',
    'textured crop': 'textured crop haircut men modern',
    'caesar cut': 'caesar haircut men roman style',
    'ivy league': 'ivy league haircut men preppy',
    'side part': 'side part hairstyle men classic',
    'messy': 'messy hairstyle men textured casual',
    'spiky': 'spiky hair men gel styled',
    'man bun': 'man bun hairstyle long hair men',
    'top knot': 'top knot men hairstyle modern',
  };

  // Validar configuración
  static bool get isPixabayConfigured => pixabayApiKey.isNotEmpty;
  static bool get isUnsplashConfigured => unsplashAccessKey != 'YOUR_UNSPLASH_ACCESS_KEY';
}

// Instrucciones de configuración
/*
CONFIGURACIÓN DE APIs:

1. PIXABAY (GRATUITA - RECOMENDADA):
   - Registrarse en: https://pixabay.com/accounts/register/
   - Ir a: https://pixabay.com/api/docs/
   - Copiar tu API key y reemplazar en pixabayApiKey
   - Límite: 5000 requests/hora

2. UNSPLASH (PREMIUM - OPCIONAL):
   - Registrarse en: https://unsplash.com/developers
   - Crear aplicación
   - Copiar Access Key y reemplazar en unsplashAccessKey
   - Límite: 50 requests/hora (demo), 5000/hora (production)

3. CONFIGURACIÓN RECOMENDADA:
   - Usar Pixabay como principal
   - Unsplash como fallback para mejor calidad
   - Las imágenes de fallback están en el código por si ambas fallan

NOTA: La API key de Pixabay incluida es de ejemplo y funcional para pruebas,
pero se recomienda usar tu propia key para producción.
*/