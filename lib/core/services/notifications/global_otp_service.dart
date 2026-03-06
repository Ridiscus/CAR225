import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

class GlobalOtpService {
  // Un canal de diffusion (broadcast) pour envoyer l'OTP à qui veut l'entendre
  static final StreamController<String> otpStream = StreamController<String>.broadcast();

  static void startListening() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 [GlobalOtpService] Notification reçue en arrière/premier plan !");

      String textToAnalyze = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? "";

      if (textToAnalyze.isNotEmpty) {
        RegExp regExp = RegExp(r'\b\d{6}\b');
        Match? match = regExp.firstMatch(textToAnalyze);

        if (match != null) {
          String extractedOtp = match.group(0)!;
          print("✅ [GlobalOtpService] Code OTP trouvé et diffusé : $extractedOtp");
          // On envoie le code dans notre flux
          otpStream.add(extractedOtp);
        }
      }
    });
  }
}