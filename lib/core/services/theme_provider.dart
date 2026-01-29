import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Variables d'état
  bool _isDarkMode = false;
  double _textScaleFactor = 1.0; // 1.0 = Normal, 0.85 = Petit, 1.15 = Grand

  // Getters (pour lire les valeurs)
  bool get isDarkMode => _isDarkMode;
  double get textScaleFactor => _textScaleFactor;

  // Constructeur : charge les prefs au démarrage
  ThemeProvider() {
    _loadFromPrefs();
  }

  // --- ACTIONS ---

  // Basculer le thème
  void toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners(); // Dit à toute l'app de se redessiner

    // Sauvegarde
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Changer la taille du texte
  void setFontSize(String sizeName) async {
    switch (sizeName) {
      case "Petite":
        _textScaleFactor = 0.85;
        break;
      case "Grande":
        _textScaleFactor = 1.15;
        break;
      case "Moyenne":
      default:
        _textScaleFactor = 1.0;
        break;
    }
    notifyListeners();

    // Sauvegarde
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('fontSize', sizeName);
  }

  // Récupérer le nom actuel (pour l'UI)
  String get currentFontSizeName {
    if (_textScaleFactor == 0.85) return "Petite";
    if (_textScaleFactor == 1.15) return "Grande";
    return "Moyenne";
  }

  // --- CHARGEMENT ---
  void _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    String savedSize = prefs.getString('fontSize') ?? "Moyenne";
    setFontSize(savedSize); // Cela va aussi notifier les listeners
  }
}