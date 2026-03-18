import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';

// Tes imports UI
import '../widgets/custom_app_bar.dart';
import '../widgets/confirmation_modal.dart';
import '../widgets/success_modal.dart';

// Tes imports Data & Domain
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/models/ticket_reservation_model.dart';
import '../../data/repositories/agent_repository_impl.dart';

class ScanResultScreen extends StatefulWidget {
  final String ticketReference;
  final bool isManual;
// 🟢 1. ON AJOUTE LES DEUX NOUVELLES VARIABLES ICI
  final int vehiculeId;
  final int programmeId;

  const ScanResultScreen({
    super.key,
    required this.ticketReference,
    required this.isManual,

    // 🟢 2. ON EXIGE QU'ELLES SOIENT FOURNIES DANS LE CONSTRUCTEUR
    required this.vehiculeId,
    required this.programmeId,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  // --- ÉTATS ---
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _errorMessage;
  TicketReservationModel? _reservation;

  late final AgentRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    _repository = AgentRepositoryImpl(remoteDataSource: AgentRemoteDataSourceImpl());
    _fetchTicket();
  }

  // --- LOGIQUE API ---
  Future<void> _fetchTicket() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticket = widget.isManual
          ? await _repository.searchTicketByReference(widget.ticketReference)
          : await _repository.searchTicket(widget.ticketReference);

      setState(() {
        _reservation = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Billet introuvable ou erreur de connexion.";
        _isLoading = false;
      });
    }
  }


  Future<void> _confirmBoarding() async {
    if (_reservation == null) return;

    HapticFeedback.heavyImpact();
    setState(() => _isConfirming = true);

    try {
      // On récupère la vraie référence de la réservation
      String realReference = _reservation!.reference;

      final response = await _repository.confirmBoarding(
        reference: realReference,

        // 🟢 3. ON UTILISE LES VARIABLES ENVOYÉES PAR L'ÉCRAN PRÉCÉDENT !
        vehiculeId: widget.vehiculeId,
        programmeId: widget.programmeId,
      );

      setState(() => _isConfirming = false);

      if (mounted) {
        SuccessModal.show(
          context: context,
          message: response['message'] ?? 'Embarquement confirmé.',
          onPressed: () {
            // 1. Fermer UNIQUEMENT la modale de succès
            Navigator.of(context, rootNavigator: true).pop();

            // 2. Retourner au scanner sans fermer l'onglet
            // On utilise le Navigator le plus proche de l'écran de résultat
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        );
      }
    } catch (e) {
      setState(() => _isConfirming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll("Exception: ", "")),
              backgroundColor: Colors.redAccent
          ),
        );
      }
    }
  }


  // --- DANS LE MÉTHODE BUILD ---
  @override
  Widget build(BuildContext context) {
    final bool isUsed = _reservation?.status.toLowerCase() == 'terminee';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Détails Réservation',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
          ? _buildErrorView()
          : _buildMainContent(isUsed),

      // 🟢 MODIFICATION ICI : On ajoute la condition widget.programmeId != 0
      bottomNavigationBar: (!_isLoading && _errorMessage == null && !isUsed && widget.programmeId != 0)
          ? _buildActionButtons(context)
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const Gap(16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Gap(24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Retour au scanner"),
          )
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isUsed) {
    return SafeArea(
      top: false,
      bottom: true,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(30),
            _buildStatusBadge(isUsed),
            const Gap(30),
            _buildPassengerDetails(),
            const Gap(35),
            _buildTravelDetails(),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  // 🟢 BADGE ADAPTATIF

  Widget _buildStatusBadge(bool isUsed) {
    final color = isUsed ? Colors.red : AppColors.secondary;
    final icon = isUsed ? Icons.cancel : Icons.check_circle;
    final text = isUsed ? 'BILLET DÉJÀ UTILISÉ' : 'BILLET VALIDE';

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const Gap(8),
                Text(
                  text,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          // 🟢 PETIT TEXTE D'INFORMATION SI PROGRAMME ID == 0
          if (widget.programmeId == 0 && !isUsed)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "Consultation uniquement (choisir un trajet via le scanner pour embarquer)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  // 🟢 DONNÉES DU PASSAGER DYNAMIQUES
  Widget _buildPassengerDetails() {
    final ticket = _reservation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations Passager',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Color(0xFF263238),
          ),
        ),
        const Gap(20),
        _buildDetailRow(
          Icons.person_outline_rounded,
          'NOM COMPLET',
          ticket.passengerName,
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.qr_code_scanner_outlined,
          'RÉFÉRENCE',
          ticket.reference,
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.airline_seat_recline_normal_outlined,
          'SIÈGE',
          'Place #${ticket.seatNumber}',
        ),
      ],
    );
  }

  // 🟢 DONNÉES DU TRAJET DYNAMIQUES
  Widget _buildTravelDetails() {
    final ticket = _reservation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails du Trajet',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        const Gap(20),
        _buildDetailRow(
          Icons.location_on_outlined,
          'DÉPART',
          ticket.departureStation,
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.flag_outlined,
          'DESTINATION',
          ticket.arrivalStation,
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.calendar_today_outlined,
          'DATE & HEURE',
          '${ticket.travelDate} • ${ticket.departureTime}',
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const Gap(16),
          Expanded( // Expanded ajouté pour éviter l'overflow si le texte est trop long
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Divider(color: Colors.grey[200], height: 20),
    );
  }

  // 🟢 BOUTONS AVEC LA LOGIQUE INTÉGRÉE
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 15),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isConfirming ? null : () {
                      HapticFeedback.heavyImpact();

                      // On capture le navigateur de l'écran AVANT d'entrer dans la modale
                      final screenNavigator = Navigator.of(context);

                      ConfirmationModal.show(
                        context: context,
                        title: 'Refuser ?',
                        message: 'Êtes-vous vraiment sûr de vouloir refuser ce billet ?',
                        confirmText: 'OUI, REFUSER',
                        cancelText: 'ANNULER',
                        onConfirm: () {
                          // 1. Fermer la modale (le dialogue de confirmation)
                          Navigator.of(context, rootNavigator: true).pop();

                          // 2. Fermer l'écran de résultat (ScanResultScreen)
                          // pour revenir à l'onglet du scanner
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Refuser', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _confirmBoarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                        : const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}