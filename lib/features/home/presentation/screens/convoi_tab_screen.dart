import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/NotificationIconBtn.dart';
import '../../../../common/widgets/local_badge.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import 'all_convoi_screen.dart';
import 'convoi_detail_screen.dart';
import 'profil_screen.dart';



class ConvoiTabScreen extends StatefulWidget {
  const ConvoiTabScreen({super.key});

  @override
  State<ConvoiTabScreen> createState() => _ConvoiTabScreenState();
}

class _ConvoiTabScreenState extends State<ConvoiTabScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- VARIABLES D'ONGLETS ---
  int _currentTabIndex = 0; // 0 = Nouveau Convoi, 1 = Mes Convois

  List<dynamic> _myConvois = [];
  bool _isHistoryLoading = false;
  String? _selectedStatutFilter; // Pour le filtrage par la suite

  bool _isLoading = false; // <-- NOUVEAU : Pour gérer le chargement


  // --- VARIABLES DYNAMIQUES API ---
  List<dynamic> _compagnies = [];
  List<dynamic> _gares = [];
  List<dynamic> _itineraires = [];

  // On stocke les IDs (Entiers) maintenant !
  int? _selectedCompanyId;
  int? _selectedGareId;
  int? _selectedItineraireId;

  final TextEditingController _departLocCtrl = TextEditingController();
  final TextEditingController _arriveeLocCtrl = TextEditingController();
  final TextEditingController _personnesCtrl = TextEditingController(text: "10");

  DateTime? _departDate;
  TimeOfDay? _departTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;

  final Color _brandColor = const Color(0xFFE34001);


  @override
  void initState() {
    super.initState();
    _fetchCompagnies(); // Charge les compagnies au démarrage
    _fetchMyConvois();
  }


  @override
  void dispose() {
    _departLocCtrl.dispose();
    _arriveeLocCtrl.dispose();
    _personnesCtrl.dispose();
    super.dispose();
  }

  // 🟢 1. Charger les compagnies
  Future<void> _fetchCompagnies() async {
    try {
      // 1. Instanciation des services requis
      final dataSource = AuthRemoteDataSourceImpl();
      final fcmService = FcmService();       // <-- AJOUT
      final deviceService = DeviceService(); // <-- AJOUT

      // 2. Instanciation du Repository avec tous ses paramètres
      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        fcmService: fcmService,           // <-- AJOUT
        deviceService: deviceService,     // <-- AJOUT
      );

      final data = await repository.getConvoiCompagnies();

      setState(() {
        _compagnies = data;
      });
    } catch (e) {
      print("Erreur UI : $e");
    }
  }

  Future<void> _fetchMyConvois() async {
    setState(() => _isHistoryLoading = true);
    try {
      final dataSource = AuthRemoteDataSourceImpl();
      final fcmService = FcmService();
      final deviceService = DeviceService();

      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        fcmService: fcmService,
        deviceService: deviceService,
      );

      final response = await repository.getMyConvois(statut: _selectedStatutFilter);

      setState(() {
        _myConvois = response['data'] ?? [];
        _isHistoryLoading = false;
      });
    } catch (e) {
      setState(() => _isHistoryLoading = false);
      _showTopNotification("Impossible de charger l'historique", isError: true);
    }
  }



  Future<void> _fetchGaresAndItineraires(int compagnieId) async {
    setState(() {
      _selectedGareId = null;
      _selectedItineraireId = null;
      _gares = [];
      _itineraires = [];
      _departLocCtrl.clear();
      _arriveeLocCtrl.clear();
    });

    try {
      final dataSource = AuthRemoteDataSourceImpl();
      final fcmService = FcmService();
      final deviceService = DeviceService();

      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        fcmService: fcmService,
        deviceService: deviceService,
      );

      final fetchedGares = await repository.getConvoiGares(compagnieId);
      final fetchedItineraires = await repository.getConvoiItineraires(compagnieId);

      setState(() {
        _gares = fetchedGares;
        _itineraires = fetchedItineraires;
      });
    } catch (e) {
      print("Erreur chargement gares/itinéraires : $e");
    }
  }



  // --- FONCTIONS DE SELECTION DATE/HEURE ---
  Future<void> _selectDate(BuildContext context, bool isReturn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _brandColor)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isReturn) _returnDate = picked;
        else _departDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isReturn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _brandColor)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isReturn) _returnTime = picked;
        else _departTime = picked;
      });
    }
  }


  // --- FONCTION DE NOTIFICATION (À placer dans ta classe _ConvoiTabScreenState) ---
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
    Future.delayed(const Duration(seconds: 3), () {
      if(mounted) overlayEntry.remove();
    });
  }

// --- FONCTION DE SOUMISSION À L'API ---
  Future<void> _soumettreDemandeConvoi() async {
    // 1. Validation du formulaire (champs obligatoires)
    if (!_formKey.currentState!.validate()) return;

    // 🟢 NOUVELLE VÉRIFICATION : Minimum 10 passagers
    int nbPersonnes = int.tryParse(_personnesCtrl.text.trim()) ?? 0;
    if (nbPersonnes < 10) {
      _showTopNotification("Le minimum est de 10 personnes pour un convoi.", isError: true);
      return; // On bloque l'envoi API
    }

    // 2. Vérification spécifique pour l'heure de retour
    if (_returnDate != null && _returnTime == null) {
      _showTopNotification("Veuillez indiquer l'heure de retour correspondante à votre date.", isError: true);
      return; // On stoppe la fonction ici
    }

    // 3. Activation du loader
    setState(() {
      _isLoading = true;
    });

    try {
      // 4. Préparation du payload
      Map<String, dynamic> payload = {
        "compagnie_id": _selectedCompanyId,
        "gare_id": _selectedGareId,
        "itineraire_id": _selectedItineraireId, // Sera null s'il écrit manuellement
        "lieu_depart": _departLocCtrl.text.trim(),
        "lieu_retour": _arriveeLocCtrl.text.trim(),
        "nombre_personnes": int.tryParse(_personnesCtrl.text) ?? 10,
        "date_depart": _departDate != null ? DateFormat('yyyy-MM-dd').format(_departDate!) : null,
        "heure_depart": _departTime != null ? "${_departTime!.hour.toString().padLeft(2, '0')}:${_departTime!.minute.toString().padLeft(2, '0')}" : null,
        "date_retour": _returnDate != null ? DateFormat('yyyy-MM-dd').format(_returnDate!) : null,
        "heure_retour": _returnTime != null ? "${_returnTime!.hour.toString().padLeft(2, '0')}:${_returnTime!.minute.toString().padLeft(2, '0')}" : null,
      };

      // 5. Appel de l'API via le service
      // Note : Pense à injecter tes dépendances correctement (fcmService, deviceService)
      // si tu passes par ton AuthRepositoryImpl comme nous l'avons fait pour fetchCompagnies.
      // Mais si tu appelles directement AuthRemoteDataSourceImpl() ça fonctionne aussi.
      final apiService = AuthRemoteDataSourceImpl();
      final response = await apiService.createConvoi(payload);

      // 6. Succès ! On nettoie le formulaire et on bascule d'onglet
      _formKey.currentState?.reset();
      setState(() {
        _selectedCompanyId = null;
        _selectedGareId = null;
        _selectedItineraireId = null;
        _departDate = null;
        _departTime = null;
        _returnDate = null;
        _returnTime = null;
        _departLocCtrl.clear();
        _arriveeLocCtrl.clear();
        _personnesCtrl.text = "10";

        _isLoading = false;
        _currentTabIndex = 1; // 🟢 Bascule sur l'onglet "Mes Convois"
      });

      // 7. Notification de succès
      if (mounted) {
        _showTopNotification(response['message'] ?? "Demande de convoi envoyée avec succès !", isError: false);
      }

    } catch (e) {
      // 8. Gestion de l'erreur
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Nettoie l'erreur brute générée par le "throw Exception()"
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        _showTopNotification(errorMessage, isError: true);
      }
    }
  }


  /*void _showDemandeConvoiModal(bool isDark, Color brandColor) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 🟢 NOUVEAU : StatefulBuilder permet à la modale de se rafraîchir en temps réel
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {

              // Variable dynamique calculée à chaque rafraîchissement de la modale
              final bool isCompanySelected = _selectedCompanyId != null;

              return Container(
                height: MediaQuery.of(context).size.height * 0.88,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // --- HEADER DE LA MODALE ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Nouvelle Demande", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // --- LE CORPS DU FORMULAIRE ---
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          top: 20, left: 20, right: 20,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Demande de Convoi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                              Text("Complétez les blocs ci-dessous pour votre demande.", style: TextStyle(color: secondaryTextColor, fontSize: 13)),
                              const Gap(20),

                              // ==========================================
                              // BLOC 1 : PARTENAIRE
                              // ==========================================
                              _buildFormCard(
                                title: "Partenaire de transport",
                                icon: Icons.business,
                                isDark: isDark,
                                child: Column(
                                  children: [
                                    _buildDropdownField(
                                      hint: "Compagnie de transport *",
                                      value: _selectedCompanyId,
                                      items: _compagnies.map((c) => DropdownMenuItem<int>(
                                          value: c['id'],
                                          child: Text(c['name'], style: const TextStyle(fontSize: 14))
                                      )).toList(),
                                      onChanged: (val) async {
                                        if (val != null) {
                                          // On utilise setModalState pour mettre à jour l'UI de la modale
                                          setModalState(() {
                                            _selectedCompanyId = val;
                                            _selectedGareId = null;
                                            _selectedItineraireId = null;
                                          });

                                          // On charge les gares
                                          await _fetchGaresAndItineraires(val);

                                          // On force le rafraîchissement de la modale pour afficher les gares
                                          setModalState(() {});
                                        }
                                      },
                                    ),
                                    const Gap(12),
                                    _buildDropdownField(
                                      hint: isCompanySelected ? "Gare la plus proche *" : "Choisir d'abord une compagnie",
                                      value: _selectedGareId,
                                      items: _gares.map((g) => DropdownMenuItem<int>(
                                          value: g['id'],
                                          child: Text(g['nom_gare'], style: const TextStyle(fontSize: 14))
                                      )).toList(),
                                      onChanged: (val) => setModalState(() => _selectedGareId = val),
                                      isEnabled: isCompanySelected && _gares.isNotEmpty,
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(20),

                              // ==========================================
                              // BLOC 2 : ITINÉRAIRE
                              // ==========================================
                              _buildFormCard(
                                title: "Trajet prévu",
                                icon: Icons.route,
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: isDark ? Colors.blueGrey.withOpacity(0.1) : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isDark ? Colors.blueGrey.withOpacity(0.3) : Colors.blue.shade100)
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                          const Gap(8),
                                          Expanded(
                                            child: Text(
                                              "Sélectionnez un itinéraire de la compagnie ou saisissez manuellement vos lieux.",
                                              style: TextStyle(fontSize: 11, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Gap(12),
                                    _buildDropdownField(
                                      hint: isCompanySelected ? "Itinéraire prédéfini (Optionnel)" : "Choisir d'abord une compagnie",
                                      value: _selectedItineraireId,
                                      items: _itineraires.map((i) => DropdownMenuItem<int>(
                                          value: i['id'],
                                          child: Text("${i['point_depart']} → ${i['point_arrive']}", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
                                      )).toList(),
                                      isEnabled: isCompanySelected && _itineraires.isNotEmpty,
                                      onChanged: (val) {
                                        setModalState(() {
                                          _selectedItineraireId = val;
                                          if (val != null) {
                                            final itineraire = _itineraires.firstWhere((element) => element['id'] == val);
                                            _departLocCtrl.text = itineraire['point_depart'];
                                            _arriveeLocCtrl.text = itineraire['point_arrive'];
                                          }
                                        });
                                      },
                                    ),
                                    const Gap(16), const Divider(), const Gap(16),
                                    _buildTextField(controller: _departLocCtrl, label: "Lieu de départ (Saisie manuelle) *", icon: Icons.trip_origin, iconColor: Colors.green),
                                    const Gap(12),
                                    _buildTextField(controller: _arriveeLocCtrl, label: "Lieu d'arrivée (Saisie manuelle) *", icon: Icons.location_on, iconColor: Colors.red),
                                  ],
                                ),
                              ),
                              const Gap(20),

                              // ==========================================
                              // BLOC 3 : PLANIFICATION & GROUPE
                              // ==========================================
                              _buildFormCard(
                                title: "Planification & Groupe",
                                icon: Icons.event_note,
                                isDark: isDark,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildDateTimePicker(label: "Départ", value: _departDate != null ? DateFormat('dd/MM/yyyy').format(_departDate!) : "Date", icon: Icons.calendar_today, onTap: () async { await _selectDate(context, false); setModalState((){}); })),
                                        const Gap(8),
                                        Expanded(child: _buildDateTimePicker(label: "Heure", value: _departTime?.format(context) ?? "--:--", icon: Icons.access_time, onTap: () async { await _selectTime(context, false); setModalState((){}); })),
                                      ],
                                    ),
                                    const Gap(12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildDateTimePicker(label: "Retour (Opt.)", value: _returnDate != null ? DateFormat('dd/MM/yyyy').format(_returnDate!) : "Date", icon: Icons.calendar_month, onTap: () async { await _selectDate(context, true); setModalState((){}); })),
                                        const Gap(8),
                                        Expanded(child: _buildDateTimePicker(label: "Heure (Opt.)", value: _returnTime?.format(context) ?? "--:--", icon: Icons.access_time, onTap: () async { await _selectTime(context, true); setModalState((){}); })),
                                      ],
                                    ),
                                    const Gap(12),
                                    _buildTextField(
                                      controller: _personnesCtrl,
                                      label: "Nombre de passagers (Minimum 10) *",
                                      icon: Icons.groups,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(30),

                              // ==========================================
                              // BOUTONS D'ACTION
                              // ==========================================
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _formKey.currentState?.reset();
                                        setModalState(() {
                                          _selectedCompanyId = null;
                                          _selectedGareId = null;
                                          _selectedItineraireId = null;
                                          _departDate = null;
                                          _departTime = null;
                                          _returnDate = null;
                                          _returnTime = null;
                                          _departLocCtrl.clear();
                                          _arriveeLocCtrl.clear();
                                          _personnesCtrl.text = "10";
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                      ),
                                      child: Text("Effacer", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const Gap(15),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : () async {
                                        if (_formKey.currentState!.validate()) {
                                          // On active le loader de la modale
                                          setModalState(() => _isLoading = true);

                                          // On lance la fonction métier principale
                                          await _soumettreDemandeConvoi();

                                          // On désactive le loader
                                          setModalState(() => _isLoading = false);

                                          // Si c'est un succès (tu peux rajouter une condition ici), on ferme la modale
                                          // Navigator.pop(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: brandColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text("Envoyer la demande", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }*/


  void _showDemandeConvoiModal(bool isDark, Color brandColor) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {

              final bool isCompanySelected = _selectedCompanyId != null;
              // 🟢 1. On capte la hauteur du clavier ici
              final bottomKeyboardInset = MediaQuery.of(context).viewInsets.bottom;

              // 🟢 2. On englobe le Container dans un Padding qui pousse la modale vers le haut quand le clavier s'ouvre
              return Padding(
                padding: EdgeInsets.only(bottom: bottomKeyboardInset),
                child: Container(
                  // 🟢 3. On remplace 'height' par 'constraints'
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // --- HEADER DE LA MODALE ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Nouvelle Demande", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // --- LE CORPS DU FORMULAIRE ---
                      Expanded(
                        child: SingleChildScrollView(
                          // 🟢 4. Plus besoin de calculer le clavier ici, on remet un padding bottom normal
                          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // ==========================================
                                // BLOC 1 : PARTENAIRE
                                // ==========================================
                                _buildFormCard(
                                  title: "Partenaire de transport",
                                  icon: Icons.business,
                                  isDark: isDark,
                                  child: Column(
                                    children: [
                                      _buildDropdownField(
                                        hint: "Compagnie de transport *",
                                        value: _selectedCompanyId,
                                        items: _compagnies.map((c) => DropdownMenuItem<int>(
                                            value: c['id'],
                                            child: Text(c['name'], style: const TextStyle(fontSize: 14))
                                        )).toList(),
                                        onChanged: (val) async {
                                          if (val != null) {
                                            // On utilise setModalState pour mettre à jour l'UI de la modale
                                            setModalState(() {
                                              _selectedCompanyId = val;
                                              _selectedGareId = null;
                                              _selectedItineraireId = null;
                                            });

                                            // On charge les gares
                                            await _fetchGaresAndItineraires(val);

                                            // On force le rafraîchissement de la modale pour afficher les gares
                                            setModalState(() {});
                                          }
                                        },
                                      ),
                                      const Gap(12),
                                      _buildDropdownField(
                                        hint: isCompanySelected ? "Gare la plus proche *" : "Choisir d'abord une compagnie",
                                        value: _selectedGareId,
                                        items: _gares.map((g) => DropdownMenuItem<int>(
                                            value: g['id'],
                                            child: Text(g['nom_gare'], style: const TextStyle(fontSize: 14))
                                        )).toList(),
                                        onChanged: (val) => setModalState(() => _selectedGareId = val),
                                        isEnabled: isCompanySelected && _gares.isNotEmpty,
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(20),

                                // ==========================================
                                // BLOC 2 : ITINÉRAIRE
                                // ==========================================
                                _buildFormCard(
                                  title: "Trajet prévu",
                                  icon: Icons.route,
                                  isDark: isDark,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: isDark ? Colors.blueGrey.withOpacity(0.1) : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: isDark ? Colors.blueGrey.withOpacity(0.3) : Colors.blue.shade100)
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                            const Gap(8),
                                            Expanded(
                                              child: Text(
                                                "Sélectionnez un itinéraire de la compagnie ou saisissez manuellement vos lieux.",
                                                style: TextStyle(fontSize: 11, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Gap(12),
                                      _buildDropdownField(
                                        hint: isCompanySelected ? "Itinéraire prédéfini (Optionnel)" : "Choisir d'abord une compagnie",
                                        value: _selectedItineraireId,
                                        items: _itineraires.map((i) => DropdownMenuItem<int>(
                                            value: i['id'],
                                            child: Text("${i['point_depart']} → ${i['point_arrive']}", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
                                        )).toList(),
                                        isEnabled: isCompanySelected && _itineraires.isNotEmpty,
                                        onChanged: (val) {
                                          setModalState(() {
                                            _selectedItineraireId = val;
                                            if (val != null) {
                                              final itineraire = _itineraires.firstWhere((element) => element['id'] == val);
                                              _departLocCtrl.text = itineraire['point_depart'];
                                              _arriveeLocCtrl.text = itineraire['point_arrive'];
                                            }
                                          });
                                        },
                                      ),
                                      const Gap(16), const Divider(), const Gap(16),
                                      _buildTextField(controller: _departLocCtrl, label: "Lieu de départ (Saisie manuelle) *", icon: Icons.trip_origin, iconColor: Colors.green),
                                      const Gap(12),
                                      _buildTextField(controller: _arriveeLocCtrl, label: "Lieu d'arrivée (Saisie manuelle) *", icon: Icons.location_on, iconColor: Colors.red),
                                    ],
                                  ),
                                ),
                                const Gap(20),

                                // ==========================================
                                // BLOC 3 : PLANIFICATION & GROUPE
                                // ==========================================
                                _buildFormCard(
                                  title: "Planification & Groupe",
                                  icon: Icons.event_note,
                                  isDark: isDark,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _buildDateTimePicker(label: "Départ", value: _departDate != null ? DateFormat('dd/MM/yyyy').format(_departDate!) : "Date", icon: Icons.calendar_today, onTap: () async { await _selectDate(context, false); setModalState((){}); })),
                                          const Gap(8),
                                          Expanded(child: _buildDateTimePicker(label: "Heure", value: _departTime?.format(context) ?? "--:--", icon: Icons.access_time, onTap: () async { await _selectTime(context, false); setModalState((){}); })),
                                        ],
                                      ),
                                      const Gap(12),
                                      Row(
                                        children: [
                                          Expanded(child: _buildDateTimePicker(label: "Retour (Opt.)", value: _returnDate != null ? DateFormat('dd/MM/yyyy').format(_returnDate!) : "Date", icon: Icons.calendar_month, onTap: () async { await _selectDate(context, true); setModalState((){}); })),
                                          const Gap(8),
                                          Expanded(child: _buildDateTimePicker(label: "Heure (Opt.)", value: _returnTime?.format(context) ?? "--:--", icon: Icons.access_time, onTap: () async { await _selectTime(context, true); setModalState((){}); })),
                                        ],
                                      ),
                                      const Gap(12),
                                      _buildTextField(
                                        controller: _personnesCtrl,
                                        label: "Nombre de passagers (Minimum 10) *",
                                        icon: Icons.groups,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),

                                // ... (Garde exactement tout ton contenu ici : BLOC 1, BLOC 2, BLOC 3) ...
                                // Je passe directement aux boutons pour te montrer la modif

                                const Gap(30),

                                // ==========================================
                                // BOUTONS D'ACTION
                                // ==========================================
                                Row(
                                  children: [
                                    // Bouton Effacer...
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _formKey.currentState?.reset();
                                          setModalState(() {
                                            _selectedCompanyId = null;
                                            _selectedGareId = null;
                                            _selectedItineraireId = null;
                                            _departDate = null;
                                            _departTime = null;
                                            _returnDate = null;
                                            _returnTime = null;
                                            _departLocCtrl.clear();
                                            _arriveeLocCtrl.clear();
                                            _personnesCtrl.text = "10";
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                        ),
                                        child: Text("Effacer", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const Gap(15),

                                    // Bouton Envoyer
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : () async {
                                          if (_formKey.currentState!.validate()) {
                                            setModalState(() => _isLoading = true);

                                            // Appel API
                                            await _soumettreDemandeConvoi();

                                            // 🟢 5. On ferme la modale si le contexte existe toujours (sécurité Flutter)
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }

                                            // On désactive le loader au cas où (si la modale n'a pas été fermée en cas d'erreur API par exemple)
                                            if (mounted) {
                                              setModalState(() => _isLoading = false);
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: brandColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text("Envoyer la demande", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      // 🟢 1. Le RefreshIndicator enveloppe maintenant toute la page
      body: RefreshIndicator(
        onRefresh: () async {
          // Ne rafraîchit que si on est sur l'onglet Historique
          if (_currentTabIndex == 1) {
            await _fetchMyConvois();
          }
        },
        // 🟢 2. Un seul SingleChildScrollView principal pour tout l'écran
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Important pour que le "Pull to refresh" marche tout le temps
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER ---
              _buildHeader(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 2. SÉLECTEUR D'ONGLETS ---
                    _buildTabSelector(isDark),
                    const Gap(25),

                    // --- 3. CONTENU DYNAMIQUE ---
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentTabIndex == 0
                          ? _buildNouveauConvoiTab(isDark)
                          : _buildMesConvoisTab(isDark),
                    ),

                    const Gap(100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS PRINCIPAUX (ONGLETS)
  // ===========================================================================

  Widget _buildTabSelector(bool isDark) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton("NOUVEAU CONVOI", 0, isDark)),
          Expanded(child: _buildTabButton("MES CONVOIS", 1, isDark)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, bool isDark) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [BoxShadow(color: _brandColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }



  /*Widget _buildNouveauConvoiTab(bool isDark) {
    final brandColor = const Color(0xFFE34001); // Ta couleur de marque

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Titre et sous-titre
            Text(
              "Demande de convoi",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87
              ),
            ),
            const Gap(5),
            Text(
              "Organisez votre voyage de groupe en toute simplicité. Remplissez le formulaire pour obtenir un devis rapide.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const Gap(20),

            // Le "Sticker" élégant (Ici un grand cercle avec une icône de bus, mais tu peux remplacer par un Image.asset si tu as un vrai sticker)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus_filled_rounded, size: 100, color: brandColor),
            ),
            const Gap(30),

            // Le bouton d'action
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showDemandeConvoiModal(isDark, brandColor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.edit_document, size: 22),
                label: const Text("Faire une demande", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  Widget _buildNouveauConvoiTab(bool isDark) {
    final brandColor = const Color(0xFFE34001); // Ta couleur de marque

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Gap(10), // Petit espace en haut pour respirer

        // Titre et sous-titre
        Text(
          "Demande de convoi",
          style: TextStyle(
              fontSize: 22, // Légèrement réduit (était 24)
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87
          ),
        ),
        const Gap(8),
        Text(
          "Organisez votre voyage de groupe en toute simplicité. Remplissez le formulaire pour obtenir un devis rapide.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13), // Légèrement réduit
        ),

        const Gap(30), // 🟢 Réduit (était 50)

        // Le "Sticker" élégant réduit
        Container(
          padding: const EdgeInsets.all(25), // 🟢 Réduit (était 40)
          decoration: BoxDecoration(
            color: brandColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.directions_bus_filled_rounded, size: 80, color: brandColor), // 🟢 Réduit (était 100)
        ),

        const Gap(35), // 🟢 Réduit (était 50)

        // Le bouton d'action
        SizedBox(
          width: double.infinity,
          height: 50, // 🟢 Légèrement réduit (était 55)
          child: ElevatedButton.icon(
            onPressed: () => _showDemandeConvoiModal(isDark, brandColor),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.edit_document, size: 20),
            label: const Text("Faire une demande", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  /*Widget _buildMesConvoisTab(bool isDark) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Mes Convois", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        Text("Retrouvez l'historique de vos demandes.", style: TextStyle(color: secondaryTextColor, fontSize: 13)),
        const Gap(20),

        if (_isHistoryLoading)
          const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
        else if (_myConvois.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Column(
                children: [
                  Icon(Icons.history_outlined, size: 50, color: secondaryTextColor?.withOpacity(0.5)),
                  const Gap(10),
                  Text("Aucune demande de convoi.", style: TextStyle(color: secondaryTextColor)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true, // Laisse la liste s'adapter à son contenu
            physics: const NeverScrollableScrollPhysics(), // Empêche la liste de scroller elle-même
            itemCount: _myConvois.length,
            separatorBuilder: (context, index) => const Gap(15),
            itemBuilder: (context, index) {
              final convoi = _myConvois[index];

              final Map<String, dynamic> mappedConvoi = {
                "id": convoi['id'], // 🟢 AJOUT DE L'ID ICI POUR LE DÉTAIL
                "ref": convoi['reference'],
                "company": convoi['compagnie']['name'],
                "itineraire": convoi['itineraire'] != null
                    ? "${convoi['itineraire']['point_depart']} → ${convoi['itineraire']['point_arrive']}"
                    : "${convoi['lieu_depart']} → ${convoi['lieu_retour']}",
                "personnes": convoi['nombre_personnes'],
                "statut": convoi['statut'].toString().toUpperCase(), // L'API renvoie 'paye', 'valide', etc.
                "date": "${convoi['date_depart']} ${convoi['heure_depart']}",
              };

              return _buildConvoiCard(mappedConvoi, isDark);
            },
          ),
      ],
    );
  }*/


  Widget _buildMesConvoisTab(bool isDark) {
    final brandColor = const Color(0xFFE34001); // Ta couleur de marque
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    // 1. ÉTAT DE CHARGEMENT
    if (_isHistoryLoading) {
      return const Center(
          child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())
      );
    }

    // 2. ÉTAT VIDE (Aucun convoi) -> On affiche le sticker élégant !
    if (_myConvois.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Gap(10),
          Text(
            "Historique vide",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87
            ),
          ),
          const Gap(8),
          Text(
            "Vous n'avez pas encore effectué de demande de convoi. Lancez-vous dès maintenant pour organiser votre voyage !",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const Gap(30),

          // Le même "Sticker" élégant
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_bus_filled_rounded, size: 80, color: brandColor),
          ),

          const Gap(35),

          // Le bouton d'action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showDemandeConvoiModal(isDark, brandColor), // Ouvre la même modale !
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text("Faire ma première demande", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      );
    }

    // 3. ÉTAT AVEC DONNÉES (On affiche max 3 éléments)
    final int displayCount = _myConvois.length > 3 ? 3 : _myConvois.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Mes Convois", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        Text("Retrouvez l'historique de vos demandes.", style: TextStyle(color: secondaryTextColor, fontSize: 13)),
        const Gap(0),

        ListView.separated(
          shrinkWrap: true, // Laisse la liste s'adapter à son contenu
          physics: const NeverScrollableScrollPhysics(), // Empêche la liste de scroller elle-même
          itemCount: displayCount, // 🟢 Limite l'affichage à 3 maximum
          separatorBuilder: (context, index) => const Gap(15),
          itemBuilder: (context, index) {
            final convoi = _myConvois[index];

            final Map<String, dynamic> mappedConvoi = {
              "id": convoi['id'],
              "ref": convoi['reference'],
              "company": convoi['compagnie']['name'],
              "itineraire": convoi['itineraire'] != null
                  ? "${convoi['itineraire']['point_depart']} → ${convoi['itineraire']['point_arrive']}"
                  : "${convoi['lieu_depart']} → ${convoi['lieu_retour']}",
              "personnes": convoi['nombre_personnes'],
              "statut": convoi['statut'].toString().toUpperCase(),
              "date": "${convoi['date_depart']} ${convoi['heure_depart']}",
            };

            return _buildConvoiCard(mappedConvoi, isDark);
          },
        ),

        // 🟢 LE BOUTON "VOIR TOUT" SI PLUS DE 3 CONVOIS
        if (_myConvois.length > 3) ...[
          const Gap(20),
          TextButton(
            onPressed: () {
              // Navigation vers la page contenant TOUS les convois
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AllConvoisScreen(allConvois: _myConvois, isDark: isDark)
                  )
              );
            },
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100, // Adapte la couleur au thème
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      "Voir tous les convois effectués (${_myConvois.length})",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                  ),
                  const Gap(8),
                  Icon(Icons.arrow_forward, size: 16, color: brandColor)
                ]
            ),
          ),
        ]
      ],
    );
  }


  // --- CARTE CONVOI OPTIMISÉE ---
  Widget _buildConvoiCard(Map<String, dynamic> convoi, bool isDark) {
    final String statut = convoi["statut"] ?? "EN ATTENTE";

    // Logique dynamique pour les couleurs des statuts
    Color statusColor;
    if (statut == "PAYE") {
      statusColor = const Color(0xFF1EAE53); // Vert
    } else if (statut == "CONFIRME" || statut == "VALIDE") {
      statusColor = Colors.blue;             // Bleu
    } else if (statut == "REJETE") {
      statusColor = Colors.redAccent;        // Rouge
    } else {
      statusColor = Colors.orange;           // Orange (En attente)
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1 : Référence & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(convoi["ref"], style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(convoi["date"], style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 24),

          // Ligne 2 : Compagnie & Badge Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  convoi["company"],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                    const Gap(6),
                    Text(statut, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              )
            ],
          ),
          const Gap(12),

          // Ligne 3 : Itinéraire, Passagers & Bouton d'action
          Row(
            children: [
              Icon(Icons.route, size: 16, color: Colors.grey.shade400),
              const Gap(6),
              Expanded(
                child: Text(
                  convoi["itineraire"],
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                    const Gap(4),
                    Text("${convoi["personnes"]}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ),
              ),
              const Gap(10),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConvoiDetailScreen(convoi: convoi)),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: isDark ? Colors.white : Colors.white),
                      const Gap(6),
                      Text("VOIR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.white)),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // ===========================================================================
  // COMPOSANTS UI OPTIMISÉS POUR LE FORMULAIRE
  // ===========================================================================

  // NOUVEAU : Wrapper de Carte pour grouper les champs
  Widget _buildFormCard({required String title, required IconData icon, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _brandColor),
              const Gap(8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }


  Widget _buildDropdownField({
    required String hint,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?)? onChanged,
    bool isEnabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true, // 🟢 LA SOLUTION AU RENDERFLEX EST ICI
      icon: Icon(Icons.keyboard_arrow_down, size: 20, color: isEnabled ? null : Colors.grey),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: !isEnabled ? (isDark ? Colors.grey.shade900 : Colors.grey.shade200) : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: !isEnabled ? Colors.grey : (isDark ? Colors.grey.shade400 : Colors.black54)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
      ),
      items: items,
      onChanged: isEnabled ? onChanged : null,
      validator: isEnabled && hint.contains("*") ? (val) => val == null ? 'Requis' : null : null,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, Color iconColor = Colors.grey, TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true, // Rend le champ plus compact en hauteur
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Requis';
        if (keyboardType == TextInputType.number && int.tryParse(val) != null && int.parse(val) < 10) {
          return 'Min 10';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimePicker({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const Gap(4),
            Row(
              children: [
                Icon(icon, size: 16, color: _brandColor),
                const Gap(6),
                Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET HEADER (Inchangé) ---
  Widget _buildHeader(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
            image: AssetImage("assets/images/busheader5.jpg"),
            fit: BoxFit.cover
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              stops: const [0.0, 0.6]
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding + 15, left: 20, right: 20, bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: user != null ? NetworkImage(user.fullPhotoUrl) : const AssetImage("assets/images/ci.jpg") as ImageProvider
                          ),
                        ),
                      ),
                      const Gap(12),
                      const LocationBadge(),
                    ],
                  ),
                  const NotificationIconBtn(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}