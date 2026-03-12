/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../providers/hostess_profile_provider.dart';

// Import de ton repository pour pouvoir le passer au fetchProfile
// import '../data/repositories/hostess_repository_impl.dart';

class HostessPersonalInfoScreen extends StatefulWidget {
  const HostessPersonalInfoScreen({super.key});
  @override
  State<HostessPersonalInfoScreen> createState() =>
      _HostessPersonalInfoScreenState();
}

class _HostessPersonalInfoScreenState extends State<HostessPersonalInfoScreen> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HostessProfileProvider>();
      if (provider.profileData == null) {

        // 🟢 ON FOURNIT TOUTES LES DÉPENDANCES REQUISES
        provider.fetchProfile(
          AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
            fcmService: FcmService(),       // 👈 Ajouté ici
            deviceService: DeviceService(), // 👈 Ajouté ici
          ),
        );

      }
    });
  }

  Widget _buildDisabledField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF607D8B),
          ),
        ),
        const Gap(8),
        TextFormField(
          key: Key(value), // Pour forcer la mise à jour quand la donnée arrive
          initialValue: value,
          enabled: false,
          style: const TextStyle(
            color: Color(0xFF263238),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFECEFF1)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // On écoute le provider
    final provider = context.watch<HostessProfileProvider>();
    final profile = provider.profileData;
    final isLoading = provider.isLoading;
    final pickedImage = provider.profileImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Informations Personnelles',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFF5F5F5),
                    // Si l'API renvoie une image réseau, on l'affiche ici idéalement
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage)
                        : (profile?.profilePicture != null && profile!.profilePicture!.isNotEmpty
                    // 🟢 ON CONCATÈNE L'URL DU SERVEUR AVEC LE CHEMIN DE L'IMAGE
                    // Remarque : ajoute 'storage/' si ton backend (ex: Laravel) expose les images via ce dossier.
                    // Si ça ne marche pas, essaie d'enlever 'storage/'.
                        ? NetworkImage('https://jingly-lindy-unminding.ngrok-free.dev/storage/${profile.profilePicture}')
                        : const AssetImage('assets/images/hostess_profile.png'))
                    as ImageProvider,
                  ),
                ),
              ),
              const Gap(40),

              if (profile != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDisabledField(
                      icon: Icons.badge_outlined,
                      label: 'ID Hôtesse',
                      value: profile.codeId, // 🟢 Dynamique
                    ),
                    const Gap(20),
                    _buildDisabledField(
                      icon: Icons.person_outline_rounded,
                      label: 'Nom',
                      value: profile.name, // 🟢 Dynamique
                    ),
                    const Gap(20),
                    _buildDisabledField(
                      icon: Icons.person_outline_rounded,
                      label: 'Prénom',
                      value: profile.prenom, // 🟢 Dynamique
                    ),
                    const Gap(20),
                    _buildDisabledField(
                      icon: Icons.business_rounded,
                      label: 'Compagnie',
                      value: profile.nomCompagnie ?? 'N/A', // 🟢 Utilise nomCompagnie
                    ),
                    const Gap(20),
                    _buildDisabledField(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profile.email, // 🟢 Dynamique
                    ),
                    const Gap(20),
                    _buildDisabledField(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: profile.contact, // 🟢 Dynamique
                    ),
                  ],
                ),
              ] else if (provider.errorMessage != null) ...[
                // Message d'erreur si l'API a échoué
                Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}*/



import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../providers/hostess_profile_provider.dart';

class HostessPersonalInfoScreen extends StatefulWidget {
  const HostessPersonalInfoScreen({super.key});
  @override
  State<HostessPersonalInfoScreen> createState() =>
      _HostessPersonalInfoScreenState();
}

class _HostessPersonalInfoScreenState extends State<HostessPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Variables pour stocker les données du formulaire
  String? _name;
  String? _prenom;
  String? _email;
  String? _contact;
  String? _casUrgence;
  String? _commune;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HostessProfileProvider>();
      if (provider.profileData == null) {
        provider.fetchProfile(
          AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
            fcmService: FcmService(),
            deviceService: DeviceService(),
          ),
        );
      }
    });
  }

  // ── CHAMP DÉSACTIVÉ (ID, Compagnie) ──
  Widget _buildDisabledField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF607D8B),
          ),
        ),
        const Gap(8),
        TextFormField(
          key: Key(value),
          initialValue: value,
          enabled: false,
          style: const TextStyle(
            color: Color(0xFF90A4AE), // Couleur plus claire pour montrer que c'est grisé
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: Icon(icon, color: Colors.grey, size: 22),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFECEFF1)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  // ── CHAMP ÉDITABLE (Nom, Prénom, Contacts...) ──
  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required String? initialValue,
    required void Function(String?) onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263238),
          ),
        ),
        const Gap(8),
        TextFormField(
          key: Key(label + (initialValue ?? '')), // Force la maj si la data arrive du réseau
          initialValue: initialValue,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Color(0xFF263238),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
          onSaved: onSaved,
        ),
      ],
    );
  }

  // ── SOUMISSION DU FORMULAIRE ──
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isUpdating = true);

    try {
      final dataToUpdate = {
        "name": _name,
        "prenom": _prenom,
        "email": _email, // Optionnel, selon ton backend
        "contact": _contact,
        "cas_urgence": _casUrgence,
        "commune": _commune,
      };

      final provider = context.read<HostessProfileProvider>();
      final repo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      // 🟢 APPEL DE LA MÉTHODE DE MISE À JOUR (à créer dans le Provider)
      await provider.updateProfile(repo, dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HostessProfileProvider>();
    final profile = provider.profileData;
    final isLoading = provider.isLoading;
    final pickedImage = provider.profileImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Informations Personnelles',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFF5F5F5),
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage)
                        : (profile?.profilePicture != null && profile!.profilePicture!.isNotEmpty
                        ? NetworkImage('https://jingly-lindy-unminding.ngrok-free.dev/storage/${profile.profilePicture}')
                        : const AssetImage('assets/images/hostess_profile.png'))
                    as ImageProvider,
                  ),
                ),
              ),
              const Gap(40),

              if (profile != null) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── CHAMPS NON MODIFIABLES ──
                      _buildDisabledField(
                        icon: Icons.badge_outlined,
                        label: 'ID Hôtesse',
                        value: profile.codeId,
                      ),
                      const Gap(20),
                      _buildDisabledField(
                        icon: Icons.business_rounded,
                        label: 'Compagnie',
                        value: profile.nomCompagnie ?? 'N/A',
                      ),
                      const Gap(30),
                      const Divider(color: Color(0xFFECEFF1), thickness: 2),
                      const Gap(20),

                      // ── CHAMPS MODIFIABLES ──
                      _buildEditableField(
                        icon: Icons.person_outline_rounded,
                        label: 'Nom',
                        initialValue: profile.name,
                        onSaved: (val) => _name = val,
                      ),
                      const Gap(20),
                      _buildEditableField(
                        icon: Icons.person_outline_rounded,
                        label: 'Prénom',
                        initialValue: profile.prenom,
                        onSaved: (val) => _prenom = val,
                      ),
                      const Gap(20),
                      _buildEditableField(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        initialValue: profile.email,
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (val) => _email = val,
                      ),
                      const Gap(20),
                      _buildEditableField(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        initialValue: profile.contact,
                        keyboardType: TextInputType.phone,
                        onSaved: (val) => _contact = val,
                      ),
                      const Gap(20),
                      _buildEditableField(
                        icon: Icons.contact_phone_outlined,
                        label: 'Contact d\'urgence',
                        // Utilise le champ de ton modèle (ajoute-le s'il n'y est pas)
                        initialValue: profile.casUrgence ?? '',
                        keyboardType: TextInputType.phone,
                        onSaved: (val) => _casUrgence = val,
                      ),
                      const Gap(20),
                      _buildEditableField(
                        icon: Icons.location_city_outlined,
                        label: 'Commune',
                        initialValue: profile.commune ?? '',
                        onSaved: (val) => _commune = val,
                      ),

                      const Gap(40),
                      // ── BOUTON METTRE A JOUR ──
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isUpdating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Mettre à jour le profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const Gap(40),
                    ],
                  ),
                ),
              ] else if (provider.errorMessage != null) ...[
                Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}