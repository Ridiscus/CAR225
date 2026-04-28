import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  // 🟢 ID DE TEST OFFICIELS GOOGLE (À remplacer par ton vrai ID de bloc d'annonce à la fin)
  final String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-4660168757014032/4969365656' // ID de test Android pour "App Open"
      : 'ca-app-pub-3940256099942544/5575463023'; // ID de test iOS pour "App Open"

  // 1. Charge l'annonce en mémoire
  void loadAd() {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd chargée avec succès.');
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Erreur de chargement AppOpenAd: $error');
        },
      ),
    );
  }

  // 2. Affiche l'annonce si elle est prête
  void showAdIfAvailable() {
    if (_appOpenAd == null) {
      debugPrint('L\'annonce n\'est pas encore prête. On lance le téléchargement.');
      loadAd();
      return;
    }
    if (_isShowingAd) {
      debugPrint('Une annonce est déjà en cours d\'affichage.');
      return;
    }

    // Callbacks pour savoir ce qui se passe avec l'annonce
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('L\'utilisateur a fermé l\'annonce.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // 🔄 On charge directement la prochaine annonce pour la prochaine fois !
      },
    );

    _appOpenAd!.show();
  }
}