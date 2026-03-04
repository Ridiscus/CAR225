/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../booking/data/models/categorie_models.dart';
import '../../../booking/data/models/voyage_model.dart';
import '../../../booking/data/repositories/support_repository.dart';

class GenericClaimFormScreen extends StatefulWidget {
  final SupportCategory category; // On passe l'objet complet
  final String apiType;
  final String title;
  final String categoryName;
  final String hintObject;
  final String hintDetails;
  final String dropdownLabel;
  final bool showDropdown;

  const GenericClaimFormScreen({
    super.key,
    required this.category,
    required this.apiType,
    required this.title,
    required this.categoryName,
    required this.hintObject,
    required this.hintDetails,
    this.dropdownLabel = "VOYAGE CONCERNÉ *",
    this.showDropdown = true,
  });

  @override
  State<GenericClaimFormScreen> createState() => _GenericClaimFormScreenState();
}

class _GenericClaimFormScreenState extends State<GenericClaimFormScreen> {
  final SupportRepository _repository = SupportRepository();

  List<Voyage> _voyages = [];
  Voyage? _selectedVoyage;
  bool _isLoading = true;
  bool _isSending = false;

  final TextEditingController _objetController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // 1. Déclare la variable en haut de ta classe _GenericClaimFormScreenState
  OverlayEntry? _currentOverlayEntry;


  @override
  void initState() {
    super.initState();
    if (widget.showDropdown) {
      _loadVoyages();
    } else {
      _isLoading = false;
    }
  }

// 3. AJOUTE LE DISPOSE (C'est l'étape cruciale pour ton problème)
  @override
  void dispose() {
    // Si on quitte l'écran et qu'une notification est encore là, on la tue
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }
    _objetController.dispose();
    _descController.dispose();
    super.dispose();
  }




// 2. Modifie la méthode _showTopNotification
  void _showTopNotification(String message, {bool isError = true}) {
    // Si une notification est déjà affichée, on la retire immédiatement
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;

    final overlay = Overlay.of(context);
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            // ... (garde ton design actuel)
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFF222222) : const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Icon(isError ? Icons.info_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
                const Gap(12),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlayEntry!);

    // On retire après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentOverlayEntry != null && mounted) {
        _currentOverlayEntry?.remove();
        _currentOverlayEntry = null;
      }
    });
  }

  Future<void> _loadVoyages() async {
    try {
      final list = await _repository.fetchVoyages();
      setState(() {
        _voyages = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopNotification("Impossible de charger vos voyages.");
    }
  }

  Future<void> _submitForm() async {
    // Validation des champs
    if (widget.showDropdown && _selectedVoyage == null) {
      _showTopNotification("Veuillez sélectionner le voyage concerné.");
      return;
    }
    if (_objetController.text.trim().isEmpty) {
      _showTopNotification("L'objet du message est requis.");
      return;
    }
    if (_descController.text.trim().length < 10) {
      _showTopNotification("Veuillez donner plus de détails sur votre problème.");
      return;
    }

    setState(() => _isSending = true);

    final success = await _repository.sendClaim(
      type: widget.apiType,
      reservationId: _selectedVoyage?.id,
      objet: _objetController.text,
      description: _descController.text,
    );

    setState(() => _isSending = false);

    if (success) {
      _showTopNotification("Demande envoyée ! Nous reviendrons vers vous.", isError: false);
      Future.delayed(const Duration(milliseconds: 500), () => Navigator.pop(context));
    } else {
      _showTopNotification("Échec de l'envoi. Veuillez réessayer plus tard.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Veuillez remplir le formulaire ci-dessous pour que nos équipes puissent vous aider.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Gap(20),
            if (widget.showDropdown && _voyages.isEmpty) ...[
              _buildAlertBanner(context),
              const Gap(30),
            ] else if (widget.showDropdown) ...[
              _label(widget.dropdownLabel),
              _buildDropdown(),
              const Gap(5),
              _buildHelperText(),
              const Gap(25),
            ],
            _label("OBJET DU MESSAGE *"),
            _textField(controller: _objetController, hint: widget.hintObject),
            const Gap(25),
            _label("DÉTAILS DE VOTRE PROBLÈME *"),
            _textField(
                controller: _descController,
                hint: widget.hintDetails,
                maxLines: 5),
            const Gap(40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _submitForm,
                icon: _isSending
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send, size: 18),
                label: _isSending
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text("ENVOYER MA DEMANDE",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS UI ---
  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
  );

  Widget _textField(
      {required TextEditingController controller,
        required String hint,
        int maxLines = 1}) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding: const EdgeInsets.all(15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );

  Widget _buildDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<Voyage>(
        isExpanded: true,
        value: _selectedVoyage,
        hint: const Text("-- Sélectionner --", style: TextStyle(fontSize: 13)),
        items: _voyages
            .map((v) => DropdownMenuItem(
          value: v,
          child: Text(v.displayName,
              style: const TextStyle(fontSize: 13)),
        ))
            .toList(),
        onChanged: (v) => setState(() => _selectedVoyage = v),
      ),
    ),
  );

  Widget _buildAlertBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange[800], size: 22),
              const Gap(10),
              Text("Aucune réservation disponible",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange[900])),
            ],
          ),
          const Gap(8),
          Text(
            widget.title.contains("Remboursement")
                ? "Vous n'avez aucune réservation annulée. Vous ne pouvez demander un remboursement que pour une réservation déjà annulée."
                : "Vous n'avez aucun voyage terminé. Vous pourrez déclarer un ${widget.categoryName.toLowerCase()} une fois votre voyage effectué.",
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const Gap(10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text("← Choisir une autre catégorie",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                    fontSize: 13)),
          )
        ],
      ),
    );
  }

  Widget _buildHelperText() {
    String text = widget.title.contains("Remboursement")
        ? "Sélectionnez la réservation annulée pour laquelle vous demandez un remboursement."
        : widget.title.contains("Qualité")
        ? "Sélectionnez le voyage concerné par votre signalement."
        : "Sélectionnez le voyage durant lequel votre ${widget.categoryName.toLowerCase()} a été perdu.";
    return Text("  $text",
        style: const TextStyle(color: Colors.grey, fontSize: 11));
  }
}*/



import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../booking/data/models/categorie_models.dart';
import '../../../booking/data/models/voyage_model.dart';
import '../../../booking/data/repositories/support_repository.dart';

class GenericClaimFormScreen extends StatefulWidget {
  final SupportCategory category;

  const GenericClaimFormScreen({
    super.key,
    required this.category,
  });

  @override
  State<GenericClaimFormScreen> createState() => _GenericClaimFormScreenState();
}

class _GenericClaimFormScreenState extends State<GenericClaimFormScreen> {
  final SupportRepository _repository = SupportRepository();

  List<Voyage> _voyages = [];
  Voyage? _selectedVoyage;
  bool _isLoading = true;
  bool _isSending = false;

  final TextEditingController _objetController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  OverlayEntry? _currentOverlayEntry;

  @override
  void initState() {
    super.initState();
    // Utilisation du flag dynamique de l'API
    if (widget.category.needsReservation) {
      _loadVoyages();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }
    _objetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showTopNotification(String message, {bool isError = true}) {
    _currentOverlayEntry?.remove();

    final overlay = Overlay.of(context);
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFF222222) : const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Icon(isError ? Icons.info_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
                const Gap(12),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlayEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentOverlayEntry != null) {
        _currentOverlayEntry?.remove();
        _currentOverlayEntry = null;
      }
    });
  }

  Future<void> _loadVoyages() async {
    try {
      final list = await _repository.fetchVoyages();
      setState(() {
        _voyages = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopNotification("Impossible de charger vos voyages.");
    }
  }

  Future<void> _submitForm() async {
    if (widget.category.needsReservation && _selectedVoyage == null) {
      _showTopNotification("Veuillez sélectionner le voyage concerné.");
      return;
    }
    if (_objetController.text.trim().isEmpty) {
      _showTopNotification("L'objet du message est requis.");
      return;
    }
    if (_descController.text.trim().length < 10) {
      _showTopNotification("Veuillez donner plus de détails (min. 10 caractères).");
      return;
    }

    setState(() => _isSending = true);

    final success = await _repository.sendClaim(
      type: widget.category.id, // ID dynamique : bagage_perdu, etc.
      reservationId: _selectedVoyage?.id,
      objet: _objetController.text,
      description: _descController.text,
    );

    setState(() => _isSending = false);

    if (success) {
      _showTopNotification("Demande envoyée avec succès !", isError: false);
      Future.delayed(const Duration(milliseconds: 1500), () => Navigator.pop(context));
    } else {
      _showTopNotification("Échec de l'envoi. Veuillez réessayer.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.category.title, // Titre dynamique
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.description, // Description dynamique
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Gap(20),

            // Section Dropdown dynamique
            if (widget.category.needsReservation) ...[
              if (_voyages.isEmpty)
                _buildAlertBanner()
              else ...[
                _label(widget.category.reservationLabel ?? "VOYAGE CONCERNÉ *"),
                _buildDropdown(),
                const Gap(25),
              ],
            ],

            _label("OBJET DU MESSAGE *"),
            _textField(
                controller: _objetController,
                hint: widget.category.placeholderObject // Hint dynamique
            ),
            const Gap(25),

            _label("DÉTAILS DE VOTRE PROBLÈME *"),
            _textField(
                controller: _descController,
                hint: widget.category.placeholderDescription, // Hint dynamique
                maxLines: 5
            ),
            const Gap(40),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS COMPOSANTS ---

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _submitForm,
        icon: _isSending ? const SizedBox.shrink() : const Icon(Icons.send, size: 18),
        label: _isSending
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("ENVOYER MA DEMANDE", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
  );

  Widget _textField({required TextEditingController controller, required String hint, int maxLines = 1}) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );

  Widget _buildDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<Voyage>(
        isExpanded: true,
        value: _selectedVoyage,
        hint: const Text("-- Sélectionner --", style: TextStyle(fontSize: 13)),
        items: _voyages.map((v) => DropdownMenuItem(
          value: v,
          child: Text(v.displayName, style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: (v) => setState(() => _selectedVoyage = v),
      ),
    ),
  );

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 22),
              const Gap(10),
              const Text("Aucune donnée disponible", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A5100))),
            ],
          ),
          const Gap(8),
          Text(widget.category.emptyMessage ?? "Aucun voyage trouvé.", style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}