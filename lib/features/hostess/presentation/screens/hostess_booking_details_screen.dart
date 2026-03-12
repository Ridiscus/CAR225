import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import 'package:car225/features/hostess/models/passenger_info.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import 'hostess_ticket_result_screen.dart';
import 'package:flutter/services.dart';

class HostessBookingDetailsScreen extends StatefulWidget {
  final String departure;
  final String arrival;
  final bool isRoundTrip;
  final int horaireId; // 🟢 Nouveau
  final int price;     // 🟢 Nouveau
  final String time;   // 🟢 Nouveau
  final String date;

  const HostessBookingDetailsScreen({
    super.key,
    required this.departure,
    required this.arrival,
    required this.isRoundTrip,
    required this.horaireId,
    required this.price,
    required this.time,
    required this.date,
  });

  @override
  State<HostessBookingDetailsScreen> createState() =>
      _HostessBookingDetailsScreenState();
}

class _PassengerFormData {
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController phoneController;
  final TextEditingController procheNumberController;
  final TextEditingController emailController;

  _PassengerFormData()
    : lastNameController = TextEditingController(),
      firstNameController = TextEditingController(),
      phoneController = TextEditingController(),
      procheNumberController = TextEditingController(),
      emailController = TextEditingController();

  void dispose() {
    lastNameController.dispose();
    firstNameController.dispose();
    phoneController.dispose();
    procheNumberController.dispose();
    emailController.dispose();
  }

  bool isValid() {
    return lastNameController.text.trim().isNotEmpty &&
        firstNameController.text.trim().isNotEmpty &&
        phoneController.text.trim().length == 10 &&
        procheNumberController.text.trim().length == 10;
  }

  PassengerInfo toPassengerInfo() {
    return PassengerInfo(
      lastName: lastNameController.text,
      firstName: firstNameController.text,
      phone: phoneController.text,
      procheNumber: procheNumberController.text,
      email: emailController.text.isEmpty ? null : emailController.text,
    );
  }
}

class _HostessBookingDetailsScreenState
    extends State<HostessBookingDetailsScreen> {
  // Type de voyage
  String _tripType = 'Aller Simple';


  // 🟢 UTILISE DES GETTERS DYNAMIQUES À LA PLACE :
  int get _oneWayPrice => widget.price * _passengerCount;
  int get _roundTripPrice => (widget.price * 2) * _passengerCount;

  // Nombre de passagers et formulaires
  int _passengerCount = 1;
  final List<_PassengerFormData> _passengerForms = [_PassengerFormData()];
  int _currentPassengerIndex = 0;

  // Validation visuelle
  bool _showErrors = false;
  bool _isLoading = false;



  @override
  void dispose() {
    for (var form in _passengerForms) {
      form.dispose();
    }
    super.dispose();
  }

  void _updatePassengerCount(int newCount) {
    setState(() {
      if (newCount > _passengerCount) {
        // Ajouter des formulaires
        for (int i = _passengerCount; i < newCount; i++) {
          _passengerForms.add(_PassengerFormData());
        }
      } else if (newCount < _passengerCount) {
        // Retirer des formulaires
        for (int i = _passengerCount - 1; i >= newCount; i--) {
          _passengerForms[i].dispose();
          _passengerForms.removeAt(i);
        }
        // Ajuster l'index actuel si nécessaire
        if (_currentPassengerIndex >= newCount) {
          _currentPassengerIndex = newCount - 1;
        }
      }
      _passengerCount = newCount;
    });
  }

  Future<void> _confirmBooking() async {
    setState(() => _showErrors = true);

    bool allValid = _passengerForms.every((form) => form.isValid());

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir correctement les informations de tous les passagers.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Calcul du total
      final int totalPrice = _tripType == 'Aller-Retour'
          ? _roundTripPrice * _passengerCount
          : _oneWayPrice * _passengerCount;
      // 2. 🟢 CONSTRUIRE LE JSON (PAYLOAD) CORRIGÉ 🟢
      final Map<String, dynamic> payload = {
        // Les clés corrigées selon les logs du backend :
        "programme_id": widget.horaireId,
        "date_voyage": widget.date, // ⚠️ REMPLACE CECI par la vraie variable contenant la date (ex: widget.date)
        "heure_depart": widget.time, // ⚠️ REMPLACE CECI par la vraie variable contenant l'heure
        "type_voyage": _tripType,
        "nombre_passagers": _passengerCount,
        "montant_total": totalPrice,

        // "passagers" devient "passenger_details"
        "passenger_details": _passengerForms.map((form) => {
          "nom": form.lastNameController.text.trim(),
          "prenom": form.firstNameController.text.trim(),
          "telephone": form.phoneController.text.trim(),
          "contact_urgence": form.procheNumberController.text.trim(),
          "email": form.emailController.text.trim(),
        }).toList(),
      };

      print("🚀 JSON PRÊT À ÊTRE ENVOYÉ : $payload");

      // 3. 🟢 LE VRAI APPEL API ICI 🟢
      final repo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),       // 🟢 Ajouté
        deviceService: DeviceService(), // 🟢 Ajouté
      );

      // On lance la requête !
      final response = await repo.bookTicket(payload);

      // 4. On vérifie le succès
      // ⚠️ Assure-toi que ton backend renvoie bien "success": true dans son JSON !
      if (response['success'] == true || response['status'] == 200 || response['status'] == 201) {
        if (mounted) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => HostessTicketResultScreen(
                isRoundTrip: _tripType == 'Aller-Retour',
                passengers: _passengerForms.map((form) => form.toPassengerInfo()).toList(),
                departure: widget.departure,
                arrival: widget.arrival,
                travelDate: widget.time, // Attention: on met le 'time' dans la 'date' ici
                //travelTime: widget.time, // On le remet ici pour éviter l'erreur (voir explication bas)
                totalPrice: totalPrice,
              ),
            ),
          );
        }
      } else {
        // Le backend a répondu, mais a refusé la vente (erreur métier)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Erreur lors de la réservation.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

    } catch (e) {
      // Erreur réseau, serveur éteint, ou erreur Dio interceptée
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur réseau. Impossible de contacter le serveur.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Fermer le clavier lorsqu'on tape en dehors des champs
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: const CustomAppBar(title: 'Détails du voyage'),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTripInfo(),
                const Gap(20),
                _buildTripTypeSection(),
                const Gap(20),
                //_buildTimeSection(),
                const Gap(20),
                _buildPassengerCountSection(),
                const Gap(20),
                _buildPassengerInfoSection(),
                const Gap(20),
                _buildConfirmButton(),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Point de départ ──
          Expanded(
            child: _buildCityInfo(
              widget.departure,
              'Départ',
              Icons.radio_button_checked_rounded,
              const Color(0xFF00C853),
            ),
          ),
          // ── Connecteur central ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DottedLine(),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Gap(4),
                const _DottedLine(),
              ],
            ),
          ),
          // ── Point d'arrivée ──
          Expanded(
            child: _buildCityInfo(
              widget.arrival,
              'Arrivée',
              Icons.location_on_rounded,
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityInfo(String city, String label, IconData icon, Color color) {
    final isDeparture = label == 'Départ';
    return Column(
      crossAxisAlignment: isDeparture
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        // Icône + label
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isDeparture
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (isDeparture)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            if (isDeparture) const Gap(6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            if (!isDeparture) const Gap(6),
            if (!isDeparture)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
          ],
        ),
        const Gap(6),
        // Nom de la ville
        Text(
          city,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF1A1A1A),
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: isDeparture ? TextAlign.left : TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildTripTypeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type de voyage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _buildTripTypeButton(
                  'Aller Simple',
                  '$_oneWayPrice FCFA',
                  Icons.arrow_forward_rounded,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildTripTypeButton(
                  'Aller-Retour',
                  '$_roundTripPrice FCFA',
                  Icons.sync_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeButton(String type, String price, IconData icon) {
    bool isSelected = _tripType == type;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(
            10,
          ), // Légèrement plus petit pour tenir dans la bordure
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _tripType = type);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 28,
                  ),
                  const Gap(8),
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(4),
                  Text(
                    price,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /*Widget _buildTimeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Heure de départ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((time) => _buildTimeChip(time)).toList(),
            ),
          ),
        ],
      ),
    );
  }*/

  /*Widget _buildTimeChip(String time) {
    bool isSelected = _selectedTime == time;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
        ),
      ),
      child: Material(
        color: isSelected ? AppColors.primary : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(9), // Pour tenir dans la bordure
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedTime = time);
          },
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }*/

  Widget _buildPassengerCountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nombre de passagers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _passengerCount > 1
                    ? () => _updatePassengerCount(_passengerCount - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                iconSize: 36,
                disabledColor: Colors.grey,
              ),
              const Gap(24),
              SizedBox(
                width: 100,
                height: 60,
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.1),
                    contentPadding: EdgeInsets.zero,
                  ),
                  controller: TextEditingController(text: '$_passengerCount')
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: '$_passengerCount'.length),
                    ),
                  onChanged: (value) {
                    final newCount = int.tryParse(value);
                    if (newCount != null && newCount >= 1 && newCount <= 10) {
                      _updatePassengerCount(newCount);
                    }
                  },
                  onSubmitted: (value) {
                    final newCount = int.tryParse(value);
                    if (newCount == null || newCount < 1) {
                      _updatePassengerCount(1);
                    } else if (newCount > 10) {
                      _updatePassengerCount(10);
                    }
                  },
                ),
              ),
              const Gap(24),
              IconButton(
                onPressed: _passengerCount < 10
                    ? () => _updatePassengerCount(_passengerCount + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                iconSize: 36,
                disabledColor: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerInfoSection() {
    final currentForm = _passengerForms[_currentPassengerIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Informations des passagers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (_passengerCount > 1)
                Text(
                  '${_currentPassengerIndex + 1}/$_passengerCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          if (_passengerCount > 1) ...[
            const Gap(16),
            // Navigation tabs pour les passagers
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _passengerCount,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentPassengerIndex;
                  final isCompleted = _passengerForms[index].isValid();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _currentPassengerIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isCompleted
                                    ? Colors.green.shade50
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isCompleted
                                      ? Colors.green
                                      : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isCompleted && !isSelected)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                            Text(
                              'Passager ${index + 1}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const Gap(16),
          _buildTextField(
            label: 'Nom',
            icon: Icons.person_outline,
            controller: currentForm.lastNameController,
          ),
          const Gap(12),
          _buildTextField(
            label: 'Prénom',
            icon: Icons.person_outline,
            controller: currentForm.firstNameController,
          ),
          const Gap(12),
          _buildTextField(
            label: 'Téléphone',
            icon: Icons.phone_outlined,
            controller: currentForm.phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const Gap(12),
          _buildTextField(
            label: 'Email (optionnel)',
            icon: Icons.email_outlined,
            controller: currentForm.emailController,
            keyboardType: TextInputType.emailAddress,
            isRequired: false,
          ),
          const Gap(12),
          _buildTextField(
            label: "Contact d'urgence",
            icon: Icons.phone_outlined,
            controller: currentForm.procheNumberController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          if (_passengerCount > 1 &&
              _currentPassengerIndex < _passengerCount - 1) ...[
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: currentForm.isValid()
                    ? () => setState(() => _currentPassengerIndex++)
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text(
                  'Passager suivant',
                  style: TextStyle(fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isRequired = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    // Champ invalide = requis + (vide OU longueur incorrecte si maxLength spécifié) + erreurs activées
    final String text = controller.text.trim();
    bool isInvalid = false;
    String? errorMessage;

    if (_showErrors && isRequired) {
      if (text.isEmpty) {
        isInvalid = true;
        errorMessage = 'Ce champ est obligatoire';
      } else if (maxLength != null && text.length < maxLength) {
        isInvalid = true;
        errorMessage = 'Numéro de téléphone invalide';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (isRequired) ...[
              const Gap(4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isInvalid ? Colors.red : const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ],
        ),
        const Gap(8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            counterText: "", // Cache le compteur de caractères par défaut
            hintText: "Entrez $label",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(
              icon,
              color: isInvalid ? Colors.red : AppColors.primary,
              size: 20,
            ),
            filled: true,
            fillColor: isInvalid ? const Color(0xFFFFF5F5) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isInvalid ? Colors.red : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isInvalid ? Colors.red : AppColors.primary,
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isInvalid ? Colors.red : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            // Message d'erreur masqué ici car géré par un widget personnalisé plus bas
            errorText: null,
          ),
        ),
        if (isInvalid && errorMessage != null) ...[
          const Gap(6),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 14,
              ),
              const Gap(4),
              Expanded(
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }


  Widget _buildConfirmButton() {
    // 💡 CORRECTION : On multiplie bien par le nombre de passagers !
    final int totalPrice = _tripType == 'Aller-Retour'
        ? _roundTripPrice * _passengerCount
        : _oneWayPrice * _passengerCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          // 🟢 MODIFICATION ICI : On appelle le dialogue !
          onPressed: _isLoading ? null : _showConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Confirmer la réservation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalPrice FCFA',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    // Validation de tous les formulaires de passagers
    final invalidPassengers = <int>[];
    for (int i = 0; i < _passengerForms.length; i++) {
      if (!_passengerForms[i].isValid()) {
        invalidPassengers.add(i + 1);
      }
    }

    if (invalidPassengers.isNotEmpty) {
      // Vibration pour signaler l'erreur
      HapticFeedback.heavyImpact();
      // Active l'affichage des erreurs visuelles
      setState(() {
        _showErrors = true;
        _currentPassengerIndex = invalidPassengers.first - 1;
      });
      return;
    }

    final totalPrice = _tripType == 'Aller Simple'
        ? _oneWayPrice * _passengerCount
        : _roundTripPrice * _passengerCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const Gap(12),
                    const Text(
                      'Confirmer la vente',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voulez-vous vraiment valider cette vente ?',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDialogRow(
                            'Passager(s)',
                            _passengerForms
                                .map((form) => form.toPassengerInfo().fullName)
                                .join(', '),
                          ),
                          const Gap(12),
                          _buildDialogRow('Type', _tripType),
                          const Gap(12),
                          _buildDialogRow(
                            'Nombre',
                            '$_passengerCount passager(s)',
                          ),
                          const Gap(12),
                          //_buildDialogRow('Heure', _selectedTime),
                          const Divider(height: 32, thickness: 1),
                          _buildDialogRow(
                            'Total',
                            '$totalPrice FCFA',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // On ferme le dialogue
                            // 🟢 MODIFICATION ICI : on appelle la vraie méthode d'API
                            _confirmBooking();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Valider la vente',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? AppColors.primary : Colors.grey[700],
          ),
        ),
        const Gap(16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isTotal ? AppColors.primary : const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmSale() {
    final totalPrice = _tripType == 'Aller Simple'
        ? _oneWayPrice * _passengerCount
        : _roundTripPrice * _passengerCount;

    final passengers = _passengerForms
        .map((form) => form.toPassengerInfo())
        .toList();

    // Vérification de sécurité
    if (passengers.isEmpty) {
      return;
    }

    _showSuccessDialog(totalPrice, passengers);
  }

  void _showSuccessDialog(int totalPrice, List<PassengerInfo> passengers) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curveValue = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curveValue,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône animée ou stylisée
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF2E7D32),
                        size: 40,
                      ),
                    ),
                    const Gap(24),
                    const Text(
                      'Vente Confirmée',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      '${passengers.length > 1 ? "Les billets" : "Le billet"} pour ${passengers.length > 1 ? "les" : "le"} ${passengers.length > 1 ? "${passengers.length} passager(s)" : "passager"} ${passengers.length > 1 ? "sont prêts" : "est prêt"} à être ${passengers.length > 1 ? "imprimés" : "imprimé"}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(32),
                    // Détails rapides
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 235, 237, 239),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Montant Total',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                          Text(
                            '$totalPrice FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => HostessTicketResultScreen(
                                isRoundTrip: _tripType == 'Aller-Retour',
                                passengers: passengers,
                                departure: widget.departure,
                                arrival: widget.arrival,
                                travelDate: '06/03/2026',
                                //travelTime: _selectedTime,
                                totalPrice: totalPrice,
                              ),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'VOIR LES BILLETS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Ligne pointillée horizontale ──────────────────────────────────────────
class _DottedLine extends StatelessWidget {
  const _DottedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
