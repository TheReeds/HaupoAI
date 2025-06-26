import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/preference_provider.dart';
import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const HuapoAIApp());
}

class HuapoAIApp extends StatefulWidget {
  const HuapoAIApp({super.key});

  @override
  State<HuapoAIApp> createState() => _HuapoAIAppState();
}

class _HuapoAIAppState extends State<HuapoAIApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRoutes.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PreferenceProvider()),
      ],
      child: MaterialApp.router(
        title: 'HuapoAI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A7AA7),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A7AA7),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}