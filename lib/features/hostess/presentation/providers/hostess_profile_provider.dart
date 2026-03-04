import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HostessProfileProvider extends ChangeNotifier {
  File? _profileImage;
  File? get profileImage => _profileImage;

  HostessProfileProvider() {
    loadCachedImage();
  }

  Future<void> loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('hostess_profile_image');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
      notifyListeners();
    }
  }

  Future<void> updateImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hostess_profile_image', path);
    _profileImage = File(path);
    notifyListeners();
  }
}
