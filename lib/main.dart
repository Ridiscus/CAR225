import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// --- IMPORTS EXISTANTS (Providers & UI) ---
import 'core/providers/company_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/services/notifications/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/theme_provider.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart'
    hide AuthRepositoryImpl;
import 'features/booking/data/repositories/notification_repository.dart';
import 'features/booking/domain/repositories/company_repository.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';

// --- 👇 NOUVEAUX IMPORTS (Nécessaires pour l'Auth) 👇 ---
// (Vérifie que les chemins correspondent bien à tes dossiers)
import 'core/services/device/device_service.dart';
import 'core/services/notifications/fcm_service.dart';

// Déclare cette clé en variable globale (hors des classes)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Initialisations Système
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // 2. Init Firebase
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Décommente si nécessaire
  );

  // 3. Init Notifications
  await PushNotificationService().init();

  // 4. ✅ CONFIGURATION DIO (Pour les requêtes HTTP)
  // Remplace 'http://10.0.2.2:8000/api' par ta vraie URL d'API (10.0.2.2 pour Émulateur Android)
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://car225.com/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // 5. Lancement de l'App avec les Providers
  /*runApp(
    MultiProvider(
      providers: [
        // --- A. Providers de base ---
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // --- B. Repositories (Logique métier sans UI) ---
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
            fcmService: FcmService(),
            deviceService: DeviceService(),
          ),
        ),

        // --- C. ✅ PROVIDER COMPANY (Connecté avec Dio) ---
        ChangeNotifierProvider(
          create: (_) => CompanyProvider(
            repository: CompanyRepository(dio: dio),
          ),
        ),
      ],
      child: const Car225App(), // Ton point d'entrée principal
    ),
  );*/

  runApp(
    MultiProvider(
      providers: [
        // --- A. Providers de base (ceux qui n'ont pas de dépendances) ---
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // --- B. Repositories (Logique métier sans UI) ---
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
            fcmService: FcmService(),
            deviceService: DeviceService(),
          ),
        ),

        // --- C. Providers avec Dépendances (Repositories) ---

        // ✅ CORRECTION ICI : On injecte le repository
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            repository: NotificationRepository(dio: dio),
          ),
        ),

        // ✅ PROVIDER COMPANY
        ChangeNotifierProvider(
          create: (_) =>
              CompanyProvider(repository: CompanyRepository(dio: dio)),
        ),
      ],
      child: const Car225App(),
    ),
  );
}

class Car225App extends StatelessWidget {
  const Car225App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CAR225',
      navigatorKey: navigatorKey, // 👈 AJOUTE CECI ICI
      debugShowCheckedModeBanner: false,

      // Gestion des langues
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
        Locale('en', 'US'), // Anglais
      ],
      locale: const Locale('fr', 'FR'),

      // Gestion du thème
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeProvider.textScaleFactor),
          ),
          child: child!,
        );
      },

      // Page d'accueil
      home: const SplashScreen(),
    );
  }
}
