import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';

class ConvoiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> convoi;

  const ConvoiDetailScreen({super.key, required this.convoi});

  @override
  State<ConvoiDetailScreen> createState() => _ConvoiDetailScreenState();
}

class _ConvoiDetailScreenState extends State<ConvoiDetailScreen> {
  bool _acceptTerms = false;
  bool _isGarant = false;

  final Color _brandColor = const Color(0xFFE34001);
  final Color _indigoColor = const Color(0xFF3F51B5);

  final TextEditingController _lieuRassemblementController = TextEditingController();
  List<Map<String, TextEditingController>> _passagersControllers = [];

  // 1. Contrôleurs fixes pour le mode Garant
  final Map<String, TextEditingController> _garantControllers = {
    'nom': TextEditingController(),
    'prenoms': TextEditingController(),
    'contact': TextEditingController(),
    'contact_urgence': TextEditingController(),
  };

  // 2. Contrôleurs pour la Modale (Ajout manuel)
  final TextEditingController _modaleNomCtrl = TextEditingController();
  final TextEditingController _modalePrenomsCtrl = TextEditingController();
  final TextEditingController _modaleContactCtrl = TextEditingController();
  final TextEditingController _modaleUrgenceCtrl = TextEditingController();

  // 3. Liste pour stocker les passagers validés depuis la modale
  List<Map<String, String>> _addedPassengers = [];

  // --- VARIABLES API ---
  Map<String, dynamic>? _fullConvoi;
  bool _isLoading = true;

  bool _isActionLoading = false;



  @override
  void initState() {
    super.initState();
    _fetchDetails();

    // Initialiser le champ lieu avec la donnée existante si présente
    if (widget.convoi["lieu_rassemblement"] != null) {
      _lieuRassemblementController.text = widget.convoi["lieu_rassemblement"];
    }
    //_initPassagersControllers();

  }


  @override
  void dispose() {
    _lieuRassemblementController.dispose();
    _modaleNomCtrl.dispose();
    _modalePrenomsCtrl.dispose();
    _modaleContactCtrl.dispose();
    _modaleUrgenceCtrl.dispose();
    for (var c in _garantControllers.values) { c.dispose(); }
    super.dispose();
  }


  void _showAddPassengerModal(bool isDark) {
    // On vide les champs avant d'ouvrir
    _modaleNomCtrl.clear();
    _modalePrenomsCtrl.clear();
    _modaleContactCtrl.clear();
    _modaleUrgenceCtrl.clear();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Permet à la modale de monter avec le clavier
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Évite que le clavier cache les champs
              left: 20, right: 20, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Ajouter un passager", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(15),
                _buildMiniTextField("Nom de famille *", isDark, _modaleNomCtrl),
                const Gap(10),
                _buildMiniTextField("Prénoms *", isDark, _modalePrenomsCtrl),
                const Gap(10),
                _buildMiniTextField("Contact (10 chiffres) *", isDark, _modaleContactCtrl, isPhone: true),
                const Gap(10),
                _buildMiniTextField("Contact d'urgence (Optionnel)", isDark, _modaleUrgenceCtrl, isPhone: true),
                const Gap(25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () {
                      // Vérification basique
                      if (_modaleNomCtrl.text.isEmpty || _modalePrenomsCtrl.text.isEmpty || _modaleContactCtrl.text.isEmpty) {
                        _showTopNotification("Veuillez remplir les champs obligatoires.", isError: true);
                        return;
                      }

                      // Ajout à la liste
                      setState(() {
                        _addedPassengers.add({
                          "nom": _modaleNomCtrl.text.trim(),
                          "prenoms": _modalePrenomsCtrl.text.trim(),
                          "contact": _modaleContactCtrl.text.trim(),
                          "contact_urgence": _modaleUrgenceCtrl.text.trim(),
                        });
                      });

                      Navigator.pop(context); // Ferme la modale
                    },
                    child: const Text("VALIDER L'AJOUT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // --- APPEL API ENREGISTREMENT ---

  Future<void> _soumettrePassagers(int convoiId) async {
    if (_lieuRassemblementController.text.trim().isEmpty) {
      _showTopNotification("Veuillez indiquer un lieu de rassemblement.", isError: true);
      return;
    }

    List<Map<String, String>> passagersData = [];

    // On prépare les données selon le mode
    if (_isGarant) {
      if (_garantControllers['nom']!.text.isEmpty || _garantControllers['contact']!.text.isEmpty) {
        _showTopNotification("Garant : Veuillez remplir au moins le nom et le contact.", isError: true);
        return;
      }
      passagersData.add({
        "nom": _garantControllers['nom']!.text.trim(),
        "prenoms": _garantControllers['prenoms']!.text.trim(),
        "contact": _garantControllers['contact']!.text.trim(),
        "contact_urgence": _garantControllers['contact_urgence']!.text.trim(),
      });
    } else {
      if (_addedPassengers.isEmpty) {
        _showTopNotification("Veuillez ajouter au moins un passager.", isError: true);
        return;
      }
      passagersData = List.from(_addedPassengers);
    }

    setState(() => _isActionLoading = true);

    try {
      Map<String, dynamic> payload = {
        "lieu_rassemblement": _lieuRassemblementController.text.trim(),
        "lieu_rassemblement_retour": null,
        "is_garant": _isGarant,
        "passagers": passagersData,
      };

      final repository = AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSourceImpl(), fcmService: FcmService(), deviceService: DeviceService());
      final response = await repository.enregistrerPassagers(convoiId, payload);

      if (response['success'] == true) {
        setState(() { _fullConvoi = response['convoi']; });
        if (mounted) _showTopNotification(response['message'] ?? "Enregistrement réussi", isError: false);
      }
    } catch (e) {
      if (mounted) _showTopNotification(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _fetchDetails() async {
    try {
      final dataSource = AuthRemoteDataSourceImpl();
      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      // On utilise l'ID passé depuis la liste
      final data = await repository.getConvoiDetails(widget.convoi['id']);

      setState(() {
        _fullConvoi = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Gérer l'erreur (ex: Notification Top)
    }
  }

  // --- FONCTION DE FORMATAGE DU MONTANT ---
  String _formatMontant(dynamic montantRaw) {
    if (montantRaw == null) return "Non défini";
    try {
      // Convertit "10000.00" -> 10000.0 -> 10000
      int montantInt = double.parse(montantRaw.toString()).toInt();
      // Formate avec un espace pour les milliers (optionnel mais plus joli) : "10000" -> "10 000"
      String formatted = montantInt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
      return "$formatted FCFA";
    } catch (e) {
      return "$montantRaw FCFA";
    }
  }


  // --- APPELS API ACTIONS ---
  Future<void> _accepterMontant(int convoiId) async {
    setState(() => _isActionLoading = true);
    try {
      final repository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      final response = await repository.accepterMontantConvoi(convoiId);

      if (response['success'] == true) {
        setState(() {
          _fullConvoi = response['convoi'];
        });
        if (mounted) {
          // 🟢 SUCCÈS : Notification en haut (Verte)
          _showTopNotification(response['message'] ?? "Montant accepté avec succès.", isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        // 🔴 ERREUR : Notification en haut (Rouge)
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        _showTopNotification(errorMessage, isError: true);
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _refuserMontant(int convoiId) async {
    setState(() => _isActionLoading = true);
    try {
      final repository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      final response = await repository.refuserMontantConvoi(convoiId);

      if (response['success'] == true) {
        setState(() {
          _fullConvoi = response['convoi'];
        });
        if (mounted) {
          // 🟢 SUCCÈS : Notification en haut (Verte)
          // Le message de l'API dit "Montant refusé...", on l'affiche en mode "succès" de l'action
          _showTopNotification(response['message'] ?? "Le convoi a été annulé.", isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        // 🔴 ERREUR : Notification en haut (Rouge)
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        _showTopNotification(errorMessage, isError: true);
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }


  void _showTopNotification(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, left: 20.0, right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.redAccent : Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () { if(mounted) overlayEntry.remove(); });
  }







  /*@override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // Si ça charge, on affiche un loader
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si erreur ou vide
    if (_fullConvoi == null) {
      return Scaffold(
        backgroundColor: scaffoldColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("Erreur de chargement.")),
      );
    }

    // Variables dynamiques extraites de l'API
    final String statutRaw = _fullConvoi!["statut"] ?? "en_attente";
    final String statut = statutRaw.replaceAll('_', ' ').toUpperCase(); // ex: VALIDE, PAYE, CONFIRME
    final String ref = _fullConvoi!["reference"] ?? "N/A";
    final String dateDepart = _fullConvoi!["date_depart"] ?? "";
    final String heureDepart = _fullConvoi!["heure_depart"] ?? "";
    final int nbPersonnes = _fullConvoi!["nombre_personnes"] ?? 0;

    // Gestion de l'itinéraire (API)
    final String itineraireText = _fullConvoi!["itineraire"] != null
        ? "${_fullConvoi!["itineraire"]["point_depart"]} → ${_fullConvoi!["itineraire"]["point_arrive"]}"
        : "${_fullConvoi!["lieu_depart"]} → ${_fullConvoi!["lieu_retour"]}";

    // Logique de couleur
    Color statusColor;
    if (statut == "PAYE" || statut == "PAYÉ") statusColor = const Color(0xFF1EAE53);
    else if (statut == "CONFIRME" || statut == "CONFIRMÉ" || statut == "VALIDE" || statut == "VALIDÉ") statusColor = Colors.blue;
    else if (statut == "REJETE" || statut == "REJETÉ") statusColor = Colors.redAccent;
    else statusColor = Colors.orange;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Détail ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900)),
            Text("Convoi", style: TextStyle(color: _brandColor, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER RÉFÉRENCE ---
            Text(
              "Référence : $ref",
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
            ),
            const Gap(20),

            // --- BANNIÈRE DYNAMIQUE (Haut de page) ---
            if (statut == "EN ATTENTE")
              _buildTopBanner(text: "Votre demande de convoi a été envoyée à la gare. Celle-ci vous contactera rapidement pour confirmation.", color: Colors.orange, isDark: isDark)
            else if (statut == "CONFIRME" || statut == "CONFIRMÉ")
              _buildTopBanner(text: "Vous avez confirmé votre convoi. Présentez-vous à la gare pour effectuer le paiement avant votre départ.", color: Colors.blue, isDark: isDark)
            else if (statut == "PAYE" || statut == "PAYÉ")
                _buildTopBanner(text: "Paiement validé. Renseignez le lieu de rassemblement et vos passagers.", color: Colors.green, isDark: isDark),

            const Gap(20),

            // --- GRILLE D'INFORMATIONS ---
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = (constraints.maxWidth - 15) / 2;
                return Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    _buildInfoBox(width, "COMPAGNIE", _fullConvoi!["compagnie"]["name"], isDark),
                    _buildInfoBox(width, "PERSONNES", "$nbPersonnes", isDark),
                    _buildInfoBoxStatus(width, "STATUT", statut, statusColor, isDark),
                    _buildInfoBox(width, "DATE DÉPART", "$dateDepart $heureDepart", isDark),
                  ],
                );
              },
            ),
            const Gap(15),

            // --- ITINÉRAIRE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ITINÉRAIRE", style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Gap(8),
                  Text(
                    itineraireText,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
            const Gap(30),

            // --- ROUTAGE DYNAMIQUE VERS LA BONNE SECTION ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildDynamicSection(statut, isDark, _fullConvoi!),
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }


  void _showTopNotification(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, left: 20.0, right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.redAccent : Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () { if(mounted) overlayEntry.remove(); });
  }


  Widget _buildTopBanner({required String text, required Color color, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05), // Tu peux l'utiliser ici par exemple
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }


  Widget _buildInfoBox(double width, String title, String value, bool isDark) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
          const Gap(8),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
  

  Widget _buildInfoBoxStatus(double width, String title, String status, Color statusColor, bool isDark) {
    // On utilise directement la couleur passée en paramètre pour créer le fond transparent !
    final Color bgColor = statusColor.withOpacity(0.1);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
                status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRuleText(String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.4),
          children: [
            TextSpan(text: "$title ", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            TextSpan(text: desc),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500));
  }

  // ===========================================================================
  // SÉLECTEUR DE SECTION
  // ===========================================================================
  Widget _buildDynamicSection(String statut, bool isDark, Map<String, dynamic> convoiData) {
    if (statut == "VALIDE" || statut == "VALIDÉ") {
      return _buildValidatedSection(isDark, convoiData);
    } else if (statut == "CONFIRME" || statut == "CONFIRMÉ") {
      return _buildConfirmedSection(isDark, convoiData); // <-- Ajout de convoiData
    } else if (statut == "PAYE" || statut == "PAYÉ") {
      return _buildPaidSection(isDark, convoiData); // <-- Ajout de convoiData
    } else {
      return _buildPendingSection(isDark);
    }
  }


  // ===========================================================================
  // 1. SECTION : EN ATTENTE
  // ===========================================================================
  Widget _buildPendingSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        border: Border.all(color: const Color(0xFFFFE082)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE082).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hourglass_empty, color: Color(0xFFF57F17), size: 24),
          ),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DEMANDE ENVOYÉE À LA GARE",
                  style: TextStyle(color: Color(0xFFF57F17), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Gap(8),
                Text(
                  "Votre demande a bien été transmise à la gare. La gare examine votre demande et vous contactera rapidement pour vous communiquer le montant.",
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }


  Widget _buildValidatedSection(bool isDark, Map<String, dynamic> convoiData) {
    final textColor = isDark ? Colors.white : Colors.black87;

    // Formatage du montant sans décimal (ex: 20000 FCFA au lieu de 20000.00)
    final String montantDisplay = _formatMontant(convoiData["montant"]);
    final int convoiId = convoiData["id"];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.blue, size: 16),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CONVOI VALIDÉ — CONFIRMATION REQUISE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("La gare a validé votre demande et fixé le montant. Acceptez ou refusez la proposition.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFF0F6FF), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MONTANT PROPOSÉ PAR LA GARE", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                const Gap(8),
                Text(montantDisplay, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 28)),
              ],
            ),
          ),
          const Gap(20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade300, width: 4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RÈGLEMENT DES CONVOIS CAR225", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const Gap(10),
                  _buildRuleText("1. Réservation :", "Toute demande de convoi est soumise à la validation par la gare. Le montant fixé est définitif.", isDark),
                  _buildRuleText("2. Paiement :", "Le paiement doit être effectué en totalité à la gare avant la mise à disposition du véhicule et du chauffeur.", isDark),
                  _buildRuleText("3. Passagers :", "La liste des passagers doit être complète avant la date de départ.", isDark),
                  _buildRuleText("4. Annulation :", "Toute annulation doit être notifiée à la compagnie au moins 48h avant la date de départ.", isDark),
                ],
              ),
            ),
          ),
          const Gap(20),

          if (!_acceptTerms)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), border: Border.all(color: Colors.red.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
                child: const Text("Vous devez accepter le règlement des convois avant de confirmer.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          const Gap(10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.green,
              value: _acceptTerms,
              onChanged: (val) => setState(() => _acceptTerms = val ?? false),
              title: Text("J'ai lu et j'accepte le règlement des convois CAR225.", style: TextStyle(fontSize: 13, color: textColor)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: (_acceptTerms && !_isActionLoading)
                        ? () => _accepterMontant(convoiId) // <--- VRAI APPEL API ICI
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EAE53),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isActionLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle),
                    label: Text(_isActionLoading ? "TRAITEMENT..." : "ACCEPTER", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const Gap(15),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Text("En refusant, le convoi sera annulé.", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const Gap(4),
                      OutlinedButton.icon(
                        onPressed: _isActionLoading ? null : () => _refuserMontant(convoiId), // <--- VRAI APPEL API ICI
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                          backgroundColor: Colors.red.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text("REFUSER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }


  // ===========================================================================
// 3. SECTION : CONFIRMÉ (Paiement Requis)
// ===========================================================================
  Widget _buildConfirmedSection(bool isDark, Map<String, dynamic> convoiData) {
    final String montant = convoiData["montant"] != null ? "${convoiData["montant"]} FCFA" : "Non défini";
    final String gareNom = convoiData["gare"]?["nom_gare"] ?? "Gare assignée";
    final String gareAdresse = convoiData["gare"]?["adresse"] ?? "Adresse inconnue";
    final String gareContact = convoiData["gare"]?["contact"] ?? "Contact indisponible";
    final String dateDepart = convoiData["date_depart"] ?? "Date inconnue";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _indigoColor.withOpacity(0.1) : const Color(0xFFEEF2FF), // Fond bleuté clair
        border: Border.all(color: isDark ? _indigoColor.withOpacity(0.3) : const Color(0xFFC7D2FE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _indigoColor.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(Icons.access_time_filled, color: _indigoColor, size: 24),
              ),
              const Gap(15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CONVOI CONFIRMÉ — PAIEMENT EN GARE REQUIS",
                      style: TextStyle(color: _indigoColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Gap(8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.indigo.shade900, fontSize: 13, height: 1.4),
                        children: [
                          const TextSpan(text: "Vous avez accepté le montant de "),
                          TextSpan(text: "$montant. ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: "Présentez-vous à la gare "),
                          TextSpan(text: "$gareNom ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: "pour solder votre paiement "),
                          TextSpan(text: "avant votre départ du $dateDepart.", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Gap(12),
                    // Informations de localisation de la gare (DYNAMIQUE)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: _indigoColor),
                        const Gap(4),
                        Text(gareAdresse, style: TextStyle(color: _indigoColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Gap(10),
                        Text("•", style: TextStyle(color: _indigoColor)),
                        const Gap(10),
                        Icon(Icons.phone, size: 14, color: _indigoColor),
                        const Gap(4),
                        Text(gareContact, style: TextStyle(color: _indigoColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const Gap(20),

          // Bloc Prochaines Étapes
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: _indigoColor, size: 18),
                    const Gap(8),
                    Text("PROCHAINES ÉTAPES", style: TextStyle(color: _indigoColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const Gap(12),
                _buildStepItem("1. Rendez-vous à la gare et payez le montant en caisse", _indigoColor),
                const Gap(8),
                _buildStepItem("2. La gare confirme votre paiement", _indigoColor),
                const Gap(8),
                _buildStepItem("3. Renseignez votre lieu de rassemblement et vos passagers", _indigoColor),
                const Gap(8),
                _buildStepItem("4. Un chauffeur vous sera assigné", _indigoColor),
              ],
            ),
          )
        ],
      ),
    );
  }


  // ===========================================================================
  // SECTION : PAYÉ (Interface Finale)
  // ===========================================================================
  Widget _buildPaidSection(bool isDark, Map<String, dynamic> convoiData) {
    final int nbPersonnes = convoiData["nombre_personnes"] ?? 1;
    final int passagersRemplis = convoiData["passagers_count"] ?? 0;
    final String montant = convoiData["montant"] != null ? _formatMontant(convoiData["montant"]) : "Non défini";
    final String passengerUrl = convoiData["passenger_form_url"] ?? "Lien indisponible";
    final bool passagersSoumis = convoiData["passagers_soumis"] == true;
    final int convoiId = convoiData["id"];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. BANNIÈRE PAIEMENT CONFIRMÉ ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.green.withOpacity(0.1) : const Color(0xFFF0FDF4),
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Paiement confirmé par la gare", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("Montant réglé : $montant.", style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.print, size: 16),
                label: const Text("TICKET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
        ),
        const Gap(20),

        // --- 2. LIEN DE SAISIE PASSAGERS (MASQUÉ SI GARANT ACTIVÉ) ---
        if (!_isGarant && !passagersSoumis) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? _brandColor.withOpacity(0.05) : const Color(0xFFFFF7F3),
              border: Border.all(color: _brandColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _brandColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.share, color: _brandColor, size: 16),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Lien de saisie pour vos passagers", style: TextStyle(color: _brandColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("Partagez ce lien à vos passagers pour qu'ils renseignent eux-mêmes leurs informations.", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black54, fontSize: 11)),
                        ],
                      ),
                    )
                  ],
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: Colors.grey),
                      const Gap(8),
                      Expanded(
                        child: Text(passengerUrl, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // 1. On copie le lien dans le presse-papiers du téléphone
                          await Clipboard.setData(ClipboardData(text: passengerUrl));

                          // 2. On affiche une petite notification de succès
                          if (mounted) {
                            _showTopNotification("Lien copié avec succès !", isError: false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text("Copier", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const Gap(20),
        ],

        // --- 3. LIEU DE RASSEMBLEMENT & OPTIONS ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.push_pin, color: Colors.blue.shade700, size: 18),
                  const Gap(8),
                  Text("LIEU DE RASSEMBLEMENT & OPTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                ],
              ),
              Text("Indiquez où le car doit venir vous chercher.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const Gap(16),

              Text("LIEU DE RASSEMBLEMENT (ALLER) *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.red.shade800)),
              const Gap(6),
              TextFormField(
                controller: _lieuRassemblementController,
                readOnly: passagersSoumis,
                decoration: InputDecoration(
                  hintText: "Ex: Devant la pharmacie centrale, Carrefour Akwaba...",
                  hintStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                ),
              ),
              const Gap(6),
              Text("Obligatoire — le chauffeur quittera la gare pour venir vous chercher à ce lieu.", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              const Gap(20),

              // SWITCH GARANT (Désactivé si déjà soumis)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? _indigoColor.withOpacity(0.1) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Switch(
                      value: passagersSoumis ? (convoiData["is_garant"] == true) : _isGarant,
                      activeColor: _brandColor,
                      onChanged: passagersSoumis ? null : (val) {
                        setState(() {
                          _isGarant = val;
                          // Plus besoin de _initPassagersControllers() !
                          // L'interface va basculer automatiquement entre les champs du garant et le bouton "Ajouter un passager".
                        });
                      },
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Je me porte garant pour le groupe", style: TextStyle(fontWeight: FontWeight.bold, color: _indigoColor, fontSize: 13)),
                          Text("Activez cette option si vous êtes le seul responsable. Seules vos informations seront demandées.", style: TextStyle(color: _indigoColor.withOpacity(0.8), fontSize: 11)),
                        ],
                      ),
                    )
                  ],
                ),
              )

            ],
          ),
        ),
        const Gap(20),

        // --- 4. PASSAGERS ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: _brandColor, size: 18),
                      const Gap(8),
                      // Le compteur s'adapte dynamiquement
                      Text(
                          "PASSAGERS (${passagersSoumis ? passagersRemplis : (_isGarant ? 1 : _addedPassengers.length)} / $nbPersonnes)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)
                      ),
                    ],
                  ),
                  if (passagersSoumis)
                    const Chip(label: Text("Dossier complet", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFE8F5E9), side: BorderSide.none)
                ],
              ),
              const Gap(20),

              if (passagersSoumis)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20), Gap(10),
                      Expanded(child: Text("Les informations ont été enregistrées.", style: TextStyle(color: Colors.green))),
                    ],
                  ),
                )
              else ...[
                // --- MODE GARANT ---
                if (_isGarant) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? _indigoColor.withOpacity(0.1) : const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1, color: _indigoColor, size: 16),
                        const Gap(8),
                        Expanded(child: Text("Mode garant activé — renseignez uniquement vos informations personnelles.", style: TextStyle(color: _indigoColor, fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  const Gap(20),
                  _buildPassengerInputRow(isDark, _garantControllers),
                ]

                // --- MODE LISTE LIBRE ---
                else ...[
                  // 1. On liste les passagers déjà ajoutés via la modale
                  if (_addedPassengers.isNotEmpty)
                    for (int i = 0; i < _addedPassengers.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: isDark ? Colors.black : Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 16, backgroundColor: _brandColor.withOpacity(0.1), child: Text("${i+1}", style: TextStyle(color: _brandColor, fontSize: 12, fontWeight: FontWeight.bold))),
                                const Gap(12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${_addedPassengers[i]['nom']} ${_addedPassengers[i]['prenoms']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                    Text("${_addedPassengers[i]['contact']}", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() { _addedPassengers.removeAt(i); });
                              },
                            )
                          ],
                        ),
                      ),

                  // 2. Bouton pour ouvrir la modale (s'il reste de la place)
                  if (_addedPassengers.length < nbPersonnes)
                    OutlinedButton.icon(
                      onPressed: () => _showAddPassengerModal(isDark),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          // 🟢 CORRECTION ICI : Juste la couleur, par défaut le style est 'solid'
                          side: BorderSide(color: _brandColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      icon: Icon(Icons.add_circle_outline, color: _brandColor, size: 18),
                      label: Text("Ajouter un passager", style: TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text("Le nombre maximum de passagers a été atteint.", style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                ],

                const Gap(25),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isActionLoading ? null : () => _soumettrePassagers(convoiId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isActionLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 18),
                    label: Text(_isActionLoading ? "TRAITEMENT..." : "ENREGISTRER", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                )
              ]
            ],
          ),
        ),

      ],
    );
  }


  // WIDGET HELPER MIS À JOUR AVEC LES CONTROLLERS
  Widget _buildPassengerInputRow(bool isDark, Map<String, TextEditingController> controllers) {
    return Row(
      children: [
        Expanded(child: _buildMiniTextField("Nom", isDark, controllers['nom']!)),
        const Gap(10),
        Expanded(child: _buildMiniTextField("Prénoms", isDark, controllers['prenoms']!)),
        const Gap(10),
        Expanded(child: _buildMiniTextField("Contact", isDark, controllers['contact']!, isPhone: true)),
        const Gap(10),
        Expanded(child: _buildMiniTextField("Urgence", isDark, controllers['contact_urgence']!, isPhone: true)),
      ],
    );
  }


  Widget _buildMiniTextField(String hint, bool isDark, TextEditingController controller, {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
      ),
    );
  }

}*/


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Si ça charge, on affiche un loader
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: CircularProgressIndicator(color: _brandColor)),
      );
    }

    // Si erreur ou vide
    if (_fullConvoi == null) {
      return Scaffold(
        backgroundColor: scaffoldColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("Erreur de chargement.")),
      );
    }

    // Extraction du statut
    final String statutRaw = _fullConvoi!["statut"] ?? "en_attente";
    final String statut = statutRaw.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Détails du Convoi", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. En-tête Statut & Référence
            _buildStatusHeader(_fullConvoi!, statut, isDark),
            const Gap(16),

            // 2. Carte Trajet & Dates
            _buildRouteCard(_fullConvoi!, isDark),
            const Gap(16),

            // 3. Carte Compagnie & Tarification
            _buildPriceCard(_fullConvoi!, isDark),
            const Gap(24),

            // 4. Contenu Dynamique selon le Statut (La vraie logique métier !)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildDynamicContent(statut, _fullConvoi!, isDark),
            ),

            const Gap(40), // Espace final pour scroller confortablement
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. COMPOSANTS GLOBAUX DE L'INTERFACE
  // ===========================================================================

  Widget _buildStatusHeader(Map<String, dynamic> convoi, String statut, bool isDark) {
    Color statusColor;
    IconData statusIcon;
    if (statut == "PAYE" || statut == "PAYÉ") { statusColor = const Color(0xFF1EAE53); statusIcon = Icons.check_circle; }
    else if (statut == "CONFIRME" || statut == "CONFIRMÉ" || statut == "VALIDE" || statut == "VALIDÉ") { statusColor = Colors.blue; statusIcon = Icons.info; }
    else if (statut == "REJETE" || statut == "REJETÉ" || statut == "ANNULE") { statusColor = Colors.redAccent; statusIcon = Icons.cancel; }
    else { statusColor = Colors.orange; statusIcon = Icons.hourglass_empty; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Réf: ${convoi['reference'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                const Gap(4),
                Text(statut, style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> convoi, bool isDark) {
    String depart = convoi['itineraire'] != null ? convoi['itineraire']['point_depart'] : (convoi['lieu_depart'] ?? 'N/A');
    String arrivee = convoi['itineraire'] != null ? convoi['itineraire']['point_arrive'] : (convoi['lieu_retour'] ?? 'N/A');
    String date = "${convoi['date_depart'] ?? ''} ${convoi['heure_depart'] ?? ''}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.trip_origin, color: _brandColor, size: 16),
                  Container(height: 30, width: 2, color: Colors.grey.shade300),
                  Icon(Icons.location_on, color: _indigoColor, size: 16),
                ],
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(depart, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Gap(18),
                    Text(arrivee, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              )
            ],
          ),
          const Gap(20),
          const Divider(),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconInfo(Icons.calendar_today, date, isDark),
              _buildIconInfo(Icons.groups, "${convoi['nombre_personnes'] ?? 0} Passagers", isDark),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> convoi, bool isDark) {
    final prix = convoi['montant'] != null ? _formatMontant(convoi['montant']) : "En attente";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🟢 1. On englobe la colonne de gauche avec un Expanded
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Compagnie", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const Gap(4),
                Text(
                  convoi['compagnie']?['name'] ?? 'Inconnue',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, // 🟢 2. On limite à 1 ligne
                  overflow: TextOverflow.ellipsis, // 🟢 3. On ajoute les "..." si le texte est trop long
                ),
              ],
            ),
          ),

          const Gap(10), // Un petit espace de sécurité entre le texte et le prix

          // Le conteneur du prix reste inchangé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Montant Proposé", style: TextStyle(color: _brandColor, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(prix, style: TextStyle(color: _brandColor, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. LOGIQUE DES SECTIONS (ROUTAGE SELON STATUT)
  // ===========================================================================

  Widget _buildDynamicContent(String statut, Map<String, dynamic> convoi, bool isDark) {
    if (statut == "EN ATTENTE") return _buildPendingUI();
    if (statut == "VALIDE" || statut == "VALIDÉ") return _buildValideUI(convoi, isDark);
    if (statut == "CONFIRME" || statut == "CONFIRMÉ") return _buildConfirmeUI();
    if (statut == "PAYE" || statut == "PAYÉ") return _buildPayeUI(convoi, isDark);
    if (statut == "ANNULE" || statut == "REJETE") return _buildRejeteUI();
    return const SizedBox.shrink();
  }

  // --- STATUT : EN ATTENTE ---
  Widget _buildPendingUI() {
    return _buildInfoBanner(
        "Demande envoyée",
        "La gare examine votre demande. Vous serez notifié dès qu'un montant sera proposé.",
        Icons.hourglass_empty,
        Colors.orange
    );
  }

  // --- STATUT : ANNULÉ / REJETÉ ---
  Widget _buildRejeteUI() {
    return _buildInfoBanner(
        "Convoi annulé",
        "Cette demande a été annulée ou refusée.",
        Icons.cancel,
        Colors.redAccent
    );
  }

  // --- STATUT : VALIDE (Acceptation du Prix) ---
  Widget _buildValideUI(Map<String, dynamic> convoi, bool isDark) {
    final int convoiId = convoi["id"];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner("Action requise", "La gare a fixé un montant. Veuillez accepter les conditions pour confirmer le convoi.", Icons.touch_app, Colors.blue),
        const Gap(20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Règlement CAR225", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const Gap(10),
              _buildRuleText("1. Réservation :", "Le montant fixé par la gare est définitif.", isDark),
              _buildRuleText("2. Paiement :", "À effectuer à la gare avant la mise à disposition du car.", isDark),
              _buildRuleText("3. Passagers :", "Liste complète requise avant le départ.", isDark),
            ],
          ),
        ),
        const Gap(16),

        CheckboxListTile(
          value: _acceptTerms,
          onChanged: (val) => setState(() => _acceptTerms = val ?? false),
          title: Text("J'ai lu et j'accepte le règlement.", style: TextStyle(fontSize: 13, color: textColor)),
          activeColor: Colors.green,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const Gap(20),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (_acceptTerms && !_isActionLoading) ? () => _accepterMontant(convoiId) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1EAE53),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isActionLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle),
                label: Text(_isActionLoading ? "..." : "ACCEPTER", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(15),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _isActionLoading ? null : () => _refuserMontant(convoiId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("REFUSER", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
      ],
    );
  }

  // --- STATUT : CONFIRMÉ (Doit aller payer) ---
  Widget _buildConfirmeUI() {
    return _buildInfoBanner(
        "Convoi confirmé",
        "Présentez-vous à la gare pour effectuer le paiement avant la date de départ prévue.",
        Icons.verified,
        Colors.blue
    );
  }

  // --- STATUT : PAYÉ (Saisie des passagers) ---
  Widget _buildPayeUI(Map<String, dynamic> convoi, bool isDark) {
    final bool passagersSoumis = convoi["passagers_soumis"] == true;
    final int convoiId = convoi["id"];
    final int nbPersonnes = convoi["nombre_personnes"] ?? 1;
    final String passengerUrl = convoi["passenger_form_url"] ?? "";

    if (passagersSoumis) {
      return _buildInfoBanner("Dossier complet", "Vos informations et passagers ont bien été enregistrés.", Icons.check_circle, const Color(0xFF1EAE53));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner("Paiement validé", "Veuillez renseigner le lieu de rassemblement et vos passagers.", Icons.payment, const Color(0xFF1EAE53)),
        const Gap(24),

        // Lieu de rassemblement
        Row(children: [Icon(Icons.pin_drop, color: _brandColor, size: 18), const Gap(8), const Text("Lieu de rassemblement *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
        const Gap(10),
        TextFormField(
          controller: _lieuRassemblementController,
          decoration: InputDecoration(
            hintText: "Où le car doit-il vous chercher ?",
            filled: true, fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
        const Gap(24),

        // Lien de partage
        if (!_isGarant && passengerUrl.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _brandColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandColor.withOpacity(0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Lien de saisie pour vos amis", style: TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
                const Gap(8),
                Row(
                  children: [
                    Expanded(child: Text(passengerUrl, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: passengerUrl));
                        if (mounted) _showTopNotification("Lien copié !", isError: false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white, minimumSize: const Size(0, 32)),
                      icon: const Icon(Icons.copy, size: 14), label: const Text("Copier"),
                    )
                  ],
                )
              ],
            ),
          ),
          const Gap(24),
        ],

        // Mode Garant
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: _indigoColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _indigoColor.withOpacity(0.2))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("Je me porte garant (Remplir pour tout le groupe)", style: TextStyle(fontWeight: FontWeight.bold, color: _indigoColor))),
              Switch(value: _isGarant, activeColor: _indigoColor, onChanged: (val) => setState(() => _isGarant = val)),
            ],
          ),
        ),
        const Gap(20),

        // Saisie des passagers (Cartes Mobiles ou Bouton Ajouter)
        if (_isGarant) ...[
          _buildMobilePassengerCard(title: "Vos infos (Garant)", controllers: _garantControllers, isDark: isDark),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Passagers ajoutés (${_addedPassengers.length}/$nbPersonnes)", style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_addedPassengers.length < nbPersonnes)
                TextButton.icon(
                    onPressed: () => _showAddPassengerModal(isDark),
                    icon: Icon(Icons.add, color: _brandColor), label: Text("Ajouter", style: TextStyle(color: _brandColor))
                )
            ],
          ),
          const Gap(10),
          for (int i = 0; i < _addedPassengers.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isDark ? Colors.black : Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${_addedPassengers[i]['nom']} ${_addedPassengers[i]['prenoms']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${_addedPassengers[i]['contact']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _addedPassengers.removeAt(i)))
                ],
              ),
            ),
        ],
        const Gap(30),

        // Bouton de soumission
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _isActionLoading ? null : () => _soumettrePassagers(convoiId),
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: _isActionLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save),
            label: Text(_isActionLoading ? "TRAITEMENT..." : "ENREGISTRER LE DOSSIER", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. PETITS WIDGETS UTILES ET REUTILISABLES
  // ===========================================================================

  Widget _buildInfoBanner(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                const Gap(4),
                Text(desc, style: TextStyle(fontSize: 13, color: color.withOpacity(0.8), height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500), const Gap(6),
        Text(text, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRuleText(String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          children: [TextSpan(text: "$title ", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), TextSpan(text: desc)],
        ),
      ),
    );
  }

  Widget _buildMobilePassengerCard({required String title, required Map<String, TextEditingController> controllers, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: _indigoColor, fontSize: 14)),
          const Gap(12),
          _buildMiniTextField("Nom", isDark, controllers['nom']!), const Gap(10),
          _buildMiniTextField("Prénoms", isDark, controllers['prenoms']!), const Gap(10),
          _buildMiniTextField("Contact (10 chiffres)", isDark, controllers['contact']!, isPhone: true),
        ],
      ),
    );
  }

  Widget _buildMiniTextField(String hint, bool isDark, TextEditingController controller, {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: hint, labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true, fillColor: isDark ? Colors.black : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}