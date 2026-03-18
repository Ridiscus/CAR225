/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/agent_profile_provider.dart';
import '../widgets/success_modal.dart';

class AgentPersonalInfoScreen extends StatefulWidget {
  const AgentPersonalInfoScreen({super.key});
  @override
  State<AgentPersonalInfoScreen> createState() =>
      _AgentPersonalInfoScreenState();
}

class _AgentPersonalInfoScreenState extends State<AgentPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isSaving = false; // Renommé pour ne pas confondre avec le chargement initial

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // 🟢 On déclenche la requête API dès l'ouverture de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProfileProvider>().fetchProfile().then((_) {
        // Une fois chargé, on remplit les contrôleurs avec les vraies données
        final data = context.read<AgentProfileProvider>().profileData;
        if (data != null) {
          _emailController.text = data['email'] ?? '';

          // 🟢 CORRECTION ICI : Ton backend utilise la clé 'contact'
          _phoneController.text = data['contact'] ?? '';
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // TODO: Ici tu pourras mettre l'appel API pour la modification plus tard
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSaving = false);
      SuccessModal.show(
        context: context,
        message: 'Vos informations personnelles ont été mises à jour avec succès.',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildInfoField({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    bool isEnabled = false,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      initialValue: controller?.text ?? value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 56, 57, 58),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(10),
            TextFormField(
              initialValue: controller == null ? value : null,
              controller: controller,
              enabled: isEnabled,
              onChanged: (v) {
                state.didChange(v);
                if (state.hasError) {
                  state.validate();
                }
              },
              style: TextStyle(
                color: isEnabled
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isEnabled ? Colors.white : const Color(0xFFF1F5F9),
                prefixIcon: Icon(
                  icon,
                  color: isEnabled
                      ? AppColors.primary
                      : const Color(0xFF94A3B8),
                  size: 22,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        state.errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
  @override
  Widget build(BuildContext context) {
    // 🟢 On écoute le provider
    final provider = context.watch<AgentProfileProvider>();
    final pickedImage = provider.profileImage;
    final data = provider.profileData;
    final isLoading = provider.isLoadingProfile;

    // 🛠️ RÉPARATION DE L'URL DE L'IMAGE DU BACKEND
    String? rawImageUrl = data?['profile_picture_url']?.toString();
    String? finalImageUrl;

    if (rawImageUrl != null && rawImageUrl.trim().isNotEmpty) {
      if (rawImageUrl.startsWith('http')) {
        finalImageUrl = rawImageUrl;
      } else {
        // 🟢 CORRECTION ICI : On retire le "/api/" car l'image est à la racine du domaine
        final String baseUrl = 'https://jingly-lindy-unminding.ngrok-free.dev';

        finalImageUrl = rawImageUrl.startsWith('/')
            ? '$baseUrl$rawImageUrl'
            : '$baseUrl/$rawImageUrl';

        // 🐛 DEBUG : Ajoutons un print pour vérifier le lien exact dans la console
        print('👉 LIEN FINAL DE L\'IMAGE : $finalImageUrl');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Informations Personnelles',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: isLoading
      // 🟢 Écran de chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      // 🟢 Affichage des données
          : data == null
          ? Center(child: Text(provider.errorMessage ?? "Aucune donnée"))
          : Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 66,
                          backgroundColor: Colors.white,
                          backgroundImage: pickedImage != null
                          // 1. Image modifiée localement (si l'utilisateur vient d'en choisir une)
                              ? FileImage(pickedImage) as ImageProvider
                          // 2. Image réparée depuis le serveur
                              : (finalImageUrl != null
                              ? NetworkImage(finalImageUrl) as ImageProvider
                          // 3. Image par défaut (si pas de photo sur le serveur)
                              : const AssetImage('assets/images/agent_profile.png')),
                        ),
                      ),
                    ),
                    const Gap(45),

                    _buildInfoField(
                      icon: Icons.badge_outlined,
                      label: 'IDENTIFIANT UNIQUE',
                      // On vérifie code_id, et en plan B, on vérifie si l'API l'a appelé autrement (ex: matricule)
                      value: data['code_id']?.toString() ?? data['matricule']?.toString() ?? 'Non défini',
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.person_outline_rounded,
                      label: 'NOM COMPLET',
                      // 🟢 CORRECTION ICI : On utilise data['name'] et non data['nom']
                      value: '${data['name'] ?? ''} ${data['prenom'] ?? ''}',
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.business_rounded,
                      label: 'COMPAGNIE',
                      // 🟢 Ça c'était bon, compagnie.name est correct dans ton JSON
                      value: data['compagnie']?['name'] ?? 'Non défini',
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.email_outlined,
                      label: 'ADRESSE E-MAIL',
                      controller: _emailController,
                      isEnabled: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Obligatoire';
                        if (!value.contains('@')) return 'E-mail invalide';
                        return null;
                      },
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.phone_outlined,
                      label: 'NUMÉRO DE TÉLÉPHONE',
                      controller: _phoneController,
                      isEnabled: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Obligatoire';
                        return null;
                      },
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isLoading || data == null ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                height: 24, width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'ENREGISTRER LES MODIFICATIONS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
*/



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/agent_profile_provider.dart';
import '../widgets/success_modal.dart';

class AgentPersonalInfoScreen extends StatefulWidget {
  const AgentPersonalInfoScreen({super.key});
  @override
  State<AgentPersonalInfoScreen> createState() =>
      _AgentPersonalInfoScreenState();
}

class _AgentPersonalInfoScreenState extends State<AgentPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 🟢 On déclenche la requête API dès l'ouverture de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProfileProvider>().fetchProfile();
    });
  }

  void _handleUpdate() async {
    // Ce bouton ne sert plus à grand chose vu que tout est grisé,
    // mais je laisse la logique si besoin d'évolutions futures.
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSaving = false);
      SuccessModal.show(
        context: context,
        message: 'Vos informations personnelles ont été vérifiées.',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    bool isEnabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 56, 57, 58),
            letterSpacing: 0.5,
          ),
        ),
        const Gap(10),
        TextFormField(
          initialValue: value,
          enabled: isEnabled,
          style: TextStyle(
            color: isEnabled
                ? const Color(0xFF1E293B)
                : const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isEnabled ? Colors.white : const Color(0xFFF1F5F9),
            prefixIcon: Icon(
              icon,
              color: isEnabled
                  ? AppColors.primary
                  : const Color(0xFF94A3B8),
              size: 22,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
  @override
  Widget build(BuildContext context) {
    // 🟢 On écoute le provider
    final provider = context.watch<AgentProfileProvider>();
    final pickedImage = provider.profileImage;
    final data = provider.profileData;
    final isLoading = provider.isLoadingProfile;

    // 🛠️ RÉPARATION DE L'URL DE L'IMAGE DU BACKEND
    String? rawImageUrl = data?['profile_picture_url']?.toString();
    String? finalImageUrl;

    if (rawImageUrl != null && rawImageUrl.trim().isNotEmpty) {
      if (rawImageUrl.startsWith('http')) {
        finalImageUrl = rawImageUrl;
      } else {
        const String baseUrl = 'https://jingly-lindy-unminding.ngrok-free.dev';
        finalImageUrl = rawImageUrl.startsWith('/')
            ? '$baseUrl$rawImageUrl'
            : '$baseUrl/$rawImageUrl';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Informations Personnelles',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: isLoading
      // 🟢 Écran de chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      // 🟢 Affichage des données
          : data == null
          ? Center(child: Text(provider.errorMessage ?? "Aucune donnée"))
          : Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 66,
                          backgroundColor: Colors.white,
                          backgroundImage: pickedImage != null
                              ? FileImage(pickedImage) as ImageProvider
                              : (finalImageUrl != null
                              ? NetworkImage(finalImageUrl) as ImageProvider
                              : const AssetImage('assets/images/agent_profile.png')),
                        ),
                      ),
                    ),
                    const Gap(45),

                    _buildInfoField(
                      icon: Icons.badge_outlined,
                      label: 'IDENTIFIANT UNIQUE',
                      value: data['code_id']?.toString() ?? data['matricule']?.toString() ?? 'Non défini',
                      isEnabled: false, // Grisé
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.person_outline_rounded,
                      label: 'NOM COMPLET',
                      value: '${data['prenom'] ?? ''} ${data['name'] ?? ''}'.trim(),
                      isEnabled: false, // Grisé
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.business_rounded,
                      label: 'COMPAGNIE',
                      value: data['compagnie']?['name'] ?? 'Non défini',
                      isEnabled: false, // Grisé
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.location_city_rounded,
                      label: 'GARE', // 🟢 Nouveau champ Commune
                      value: data['commune'] ?? 'Non défini',
                      isEnabled: false, // Grisé
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.email_outlined,
                      label: 'ADRESSE E-MAIL',
                      value: data['email'] ?? 'Non défini',
                      isEnabled: false, // Grisé (fini les controllers !)
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.phone_outlined,
                      label: 'NUMÉRO DE TÉLÉPHONE',
                      value: data['contact'] ?? 'Non défini',
                      isEnabled: false, // Grisé
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Tu peux retirer tout ce bloc 'bottomNavigationBar' si tu ne veux plus voir le bouton.
      bottomNavigationBar: isLoading || data == null ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                height: 24, width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'ENREGISTRER LES MODIFICATIONS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}