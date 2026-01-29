/*import 'package:flutter/material.dart';
// Important : On importe le fichier du Splash Screen qu'on vient de créer
import 'features/onboarding/presentation/screens/splash_screen.dart';


void main() {
  runApp(const Car225App());
}

class Car225App extends StatelessWidget {
  const Car225App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAR225',
      debugShowCheckedModeBanner: false, // Enlève la petite bannière "Debug" en haut à droite
      theme: ThemeData(
        // On met la couleur Orange Car225 comme couleur principale
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4500)),
        useMaterial3: true,
      ),
      // C'est ICI qu'on dit à l'app de démarrer sur notre Splash Screen
      home: const SplashScreen(),
    );
  }
}*/




import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports Core
import 'core/providers/user_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/theme_provider.dart';

// Import de l'écran de démarrage (Splash)
import 'features/onboarding/presentation/screens/splash_screen.dart';

void main() async {
  // Nécessaire pour initialiser les SharedPreferences avant le lancement de l'UI
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase
  await Firebase.initializeApp();


  runApp(
    // ✅ Utilisation de MultiProvider pour combiner User et Theme
      MultiProvider(
        providers: [
          // 1. Le Provider pour l'Utilisateur
          ChangeNotifierProvider(create: (_) => UserProvider()),

          // 2. Le Provider pour le Thème
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        // L'enfant est ton application principale
        child: const Car225App(),
      ),
  );

}

class Car225App extends StatelessWidget {
  const Car225App({super.key});

  @override
  Widget build(BuildContext context) {
    // On récupère le provider pour lire l'état actuel (Dark mode, taille police)
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CAR225',
      debugShowCheckedModeBanner: false,

      // --- CONFIGURATION DU THÈME ---
      // On utilise nos thèmes définis dans app_theme.dart
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Le mode est déterminé par la valeur stockée dans le provider
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // --- GESTION DE LA TAILLE DE POLICE (ACCESSIBILITÉ) ---
      builder: (context, child) {
        // Applique le facteur d'échelle (0.85, 1.0, 1.15) à toute l'application
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeProvider.textScaleFactor),
          ),
          child: child!, // child est l'écran affiché (ici SplashScreen)
        );
      },

      // --- POINT DE DÉPART ---
      home: const SplashScreen(),
    );
  }
}