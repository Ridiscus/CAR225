import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports Core
import 'package:intl/date_symbol_data_local.dart';
import 'core/providers/user_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/theme_provider.dart';
import 'core/network/dio_client.dart'; // Import pour navigatorKey

// Import des Providers
import 'features/agent/presentation/providers/profile_provider.dart';
import 'features/hostess/presentation/providers/hostess_profile_provider.dart';
import 'features/driver/presentation/providers/driver_provider.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';

void main() async {
  // Nécessaire pour initialiser les SharedPreferences avant le lancement de l'UI
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du format de date pour le français
  await initializeDateFormatting('fr_FR', null);

  // Initialisation de Firebase
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialisé avec succès");
  } catch (e) {
    print(
      "⚠️ Attention: Firebase n'a pas pu être initialisé. Vérifiez vos fichiers de configuration (GoogleService-Info.plist ou google-services.json). Erreur: $e",
    );
  }

  runApp(
    // ✅ Utilisation de MultiProvider pour combiner User et Theme
    MultiProvider(
      providers: [
        // 1. Le Provider pour l'Utilisateur
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // 2. Le Provider pour le Thème
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // 3. Le Provider pour l'Image de Profil Agent
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        // 4. Le Provider pour l'Image de Profil Hôtesse
        ChangeNotifierProvider(create: (_) => HostessProfileProvider()),
        // 5. Le Provider pour la feature Chauffeur (Driver)
        ChangeNotifierProvider(create: (_) => DriverProvider()),
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
      navigatorKey: navigatorKey, // ✅ Assignation de la key globale
      title: 'CAR225',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),

      // --- CONFIGURATION DU THÈME ---
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // --- GESTION DE LA TAILLE DE POLICE ---
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeProvider.textScaleFactor),
          ),
          child: child!,
        );
      },
    );
  }
}
