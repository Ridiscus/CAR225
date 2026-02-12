import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// ✅ Assure-toi que ces imports sont corrects selon ton projet
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/biometric/biometric_service.dart';
import '../../../../core/services/notifications/fcm_service.dart'; // Nécessaire pour le Repo
import '../../../auth/data/datasources/auth_remote_data_source.dart'; // Nécessaire pour le Repo
import '../../../auth/data/repositories/auth_repository_impl.dart'; // Nécessaire pour le Repo
import '../../../auth/presentation/screens/login_screen.dart';
import 'change_password_screen.dart';
import 'connect_device_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  String _deviceSubtitle = "Chargement...";

  // Variables Biométrie
  bool _isBiometricEnabled = false;
  bool _isBiometricSupported = false;
  final BiometricService _biometricService = BiometricService();

  // ✅ AJOUT IMPORTANT : Déclaration du Repository
  late AuthRepositoryImpl _repo;

  @override
  void initState() {
    super.initState();

    // ✅ AJOUT IMPORTANT : Initialisation du Repository
    _repo = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
      fcmService: FcmService(),
      deviceService: DeviceService(),
    );

    _loadDeviceName();
    _initBiometrics();
  }

  // --- LOGIQUE BIOMÉTRIQUE ---
  Future<void> _initBiometrics() async {
    bool supported = await _biometricService.isDeviceSupported();
    bool enabled = await _biometricService.getBiometricStatus();

    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
        _isBiometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      bool authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        setState(() => _isBiometricEnabled = true);
        if(mounted) _showSnack("Authentification biométrique activée");
      } else {
        setState(() => _isBiometricEnabled = false);
      }
    } else {
      await _biometricService.setBiometricEnabled(false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  // ✅ CORRECTION ICI : Ajout du paramètre nommé {bool isError}
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green, // Rouge si erreur, Vert sinon
      ),
    );
  }

  // ---------------------------

  Future<void> _loadDeviceName() async {
    final deviceService = DeviceService();
    final info = await deviceService.getDeviceInfo();
    if (mounted) {
      setState(() {
        _deviceSubtitle = info['model'] ?? "Appareil Inconnu";
      });
    }
  }

  // --- MODALE DE SUPPRESSION ---
  void _showDeleteConfirmDialog() {
    final passwordController = TextEditingController();

    // On utilise showDialog mais on ne déclare pas 'isLoading' ici
    // car il doit être géré DANS le builder pour rafraichir la modale.

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false; // Variable locale au StatefulBuilder

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text("Supprimer le compte ?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Cette action est irréversible (sauf reconnexion sous 30 jours). "
                        "Veuillez saisir votre mot de passe pour confirmer.",
                    style: TextStyle(fontSize: 13),
                  ),
                  const Gap(15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mot de passe actuel",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  if (isLoading) ...[
                    const Gap(20),
                    const Center(child: CircularProgressIndicator(color: Colors.red)),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isLoading ? null : () async {
                    if (passwordController.text.isEmpty) return;

                    setStateModal(() => isLoading = true); // Active le loader de la modale

                    try {
                      // Appel API via le Repo
                      await _repo.deactivateAccount(passwordController.text.trim());

                      if (!mounted) return;
                      Navigator.pop(context); // Ferme la modale

                      // Nettoyage Provider
                      context.read<UserProvider>().clearUser();

                      // Feedback et Redirection
                      _showSnack("Compte désactivé avec succès.");

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                      );

                    } catch (e) {
                      setStateModal(() => isLoading = false);
                      // On ferme la modale pour afficher le snackbar sur l'écran principal
                      Navigator.pop(context);
                      // ✅ Maintenant ça marche car on a modifié _showSnack
                      _showSnack("Erreur: ${e.toString().replaceAll('Exception:', '')}", isError: true);
                    }
                  },
                  child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text("Sécurité", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSecurityOption(
            context,
            icon: Icons.lock_outline,
            title: "Changer le mot de passe",
            subtitle: "Dernière modif. il y a 3 mois",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            },
          ),
          const Gap(10),

          if (_isBiometricSupported)
            _buildSecurityOption(
              context,
              icon: Icons.fingerprint,
              title: "Authentification Biométrique",
              subtitle: !_isBiometricSupported
                  ? "Non disponible sur cet appareil"
                  : (_isBiometricEnabled ? "Activé" : "Désactivé"),
              isSwitch: true,
              switchValue: _isBiometricSupported && _isBiometricEnabled,
              onSwitchChanged: _isBiometricSupported ? _toggleBiometric : null,
            ),

          if (_isBiometricSupported) const Gap(10),

          _buildSecurityOption(
            context,
            icon: Icons.devices,
            title: "Appareils connectés",
            subtitle: _deviceSubtitle,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectedDevicesScreen()));
            },
          ),

          const Gap(40),

          const Text("Zone Danger", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const Gap(10),
          Container(
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red.withOpacity(0.2))
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Supprimer mon compte", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: _showDeleteConfirmDialog,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSecurityOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        bool isSwitch = false,
        bool switchValue = false,
        ValueChanged<bool>? onSwitchChanged,
        VoidCallback? onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: ListTile(
        onTap: isSwitch ? () => onSwitchChanged?.call(!switchValue) : onTap,
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
        trailing: isSwitch
            ? Switch(
            value: switchValue,
            activeColor: Colors.green,
            trackColor: MaterialStateProperty.resolveWith((states) {
              if(states.contains(MaterialState.selected)) return Colors.green.withOpacity(0.4);
              return isDark ? Colors.grey[700] : Colors.grey[300];
            }),
            onChanged: onSwitchChanged
        )
            : Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey[600] : Colors.grey),
      ),
    );
  }
}