/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../booking/data/models/claim_model.dart';
import '../../../booking/data/models/categorie_models.dart';
import '../../../booking/data/repositories/support_repository.dart';

class ClaimsHistoryScreen extends StatefulWidget {
  final String? initialType; // Optionnel : pour ouvrir sur un type précis
  const ClaimsHistoryScreen({super.key, this.initialType});

  @override
  State<ClaimsHistoryScreen> createState() => _ClaimsHistoryScreenState();
}


class _ClaimsHistoryScreenState extends State<ClaimsHistoryScreen> {
  final SupportRepository _repository = SupportRepository();
  List<SupportCategory> _categories = [];
  List<Claim> _claims = [];
  String? _selectedTypeId;
  bool _isLoading = true;

  // ✅ AJOUTE CETTE LIGNE ICI :
  bool _isSendingReply = false;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.initialType;
    _initData();
  }

  Future<void> _initData() async {
    try {
      final cats = await _repository.fetchCategories();
      setState(() {
        _categories = cats;
      });
      _loadHistory(_selectedTypeId);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistory(String? typeId) async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.fetchClaimsHistory(typeId);
      setState(() {
        _claims = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReply(int claimId, String message) async {
    if (message.trim().isEmpty) return;

    // Optionnel: Afficher un loader
    try {
      final success = await _repository.sendSupportReply(claimId, message);
      if (success) {
        Navigator.pop(context); // Ferme le bottom sheet
        _loadHistory(_selectedTypeId); // Recharge la liste
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Réponse envoyée avec succès"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'envoi"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Mes Réclamations", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : RefreshIndicator(
              onRefresh: () => _loadHistory(_selectedTypeId),
              child: _claims.isEmpty ? _buildEmptyState() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        children: [
          _filterChip(null, "Tout", Colors.black),
          ..._categories.map((cat) => _filterChip(cat.id, cat.title, Color(int.parse(cat.color.replaceFirst('#', '0xff'))))),
        ],
      ),
    );
  }

  Widget _filterChip(String? id, String label, Color color) {
    final isSelected = _selectedTypeId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedTypeId = id);
          _loadHistory(id);
        },
        selectedColor: color,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _claims.length,
      separatorBuilder: (_, __) => const Gap(15),
      itemBuilder: (context, index) {
        final claim = _claims[index];
        final bool isClosed = claim.statut.toLowerCase() == "ferme" || claim.statut.toLowerCase() == "terminee";

        return InkWell(
          onTap: () => _showClaimDetails(context, claim),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(claim.objet, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(claim.typeLabel, style: TextStyle(color: Colors.orange[800], fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
                if (claim.reservation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _rowInfo(Icons.directions_bus, "${claim.reservation!['gare_depart']} → ${claim.reservation!['gare_arrivee']}"),
                  ),
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(claim.createdAt.split(' ')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      _statusBadge(claim.statut, isClosed),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DÉTAILS ET RÉPONSE (BOTTOM SHEET) ---
  void _showClaimDetails(BuildContext context, Claim claim) {
    final TextEditingController replyController = TextEditingController();
    final bool isClosed = claim.statut.toLowerCase() == "ferme" || claim.statut.toLowerCase() == "terminee";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( // Pour gérer le loader interne au bouton
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(claim.objet, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    _statusBadge(claim.statut, isClosed),
                  ],
                ),
                const Gap(15),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(10),
                        _sectionTitle("DESCRIPTION"),
                        Text(claim.description, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),

                        if (claim.reservation != null) ...[
                          const Gap(25),
                          _sectionTitle("DÉTAILS DU TRAJET"),
                          _detailTile(Icons.tag, "Référence", claim.reservation!['reference']),
                          _detailTile(Icons.map_outlined, "Itinéraire", "${claim.reservation!['gare_depart']} → ${claim.reservation!['gare_arrivee']}"),
                          _detailTile(Icons.calendar_month, "Date du voyage", claim.reservation!['date']),
                        ],

                        const Gap(25),
                        _sectionTitle("DISCUSSION / RÉPONSE DU SUPPORT"),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: claim.reponse != null ? Colors.green[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: claim.reponse != null ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3))
                          ),
                          child: Text(
                            claim.reponse ?? "Nous analysons votre demande. Une réponse vous sera apportée ici sous peu.",
                            style: TextStyle(color: claim.reponse != null ? Colors.green[900] : Colors.blue[900], height: 1.4),
                          ),
                        ),

                        if (!isClosed) ...[
                          const Gap(20),
                          _sectionTitle("VOTRE RÉPONSE"),
                          TextField(
                            controller: replyController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Écrivez votre message ici...",
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap(15),
                // Actions
                Row(
                  children: [
                    if (!isClosed)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSendingReply ? null : () async {
                            setModalState(() => _isSendingReply = true);
                            await _handleReply(claim.id, replyController.text);
                            setModalState(() => _isSendingReply = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSendingReply
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Répondre au support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("Fermer", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _rowInfo(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const Gap(8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis))
      ]
  );

  // --- PETITS WIDGETS DE STYLE ---
  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)));

  Widget _detailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligne en haut si le texte passe sur 2 lignes
        children: [
          Icon(icon, size: 16, color: Colors.orange[800]),
          const Gap(10),
          // On enveloppe le tout dans un Expanded pour que la Row respecte les limites de l'écran
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$label : ",
                    style: const TextStyle(fontSize: 13, color: Colors.grey)
                ),
                const Gap(5),
                // On met le 'value' dans un Flexible pour qu'il puisse revenir à la ligne
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right, // Aligné à droite pour un look propre
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.visible, // Ou TextOverflow.ellipsis si tu préfères couper
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, bool isClosed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isClosed ? Colors.grey[200] : Colors.green[100], borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(), style: TextStyle(color: isClosed ? Colors.grey[700] : Colors.green[800], fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }


  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.history, size: 60, color: Colors.grey), const Gap(15), const Text("Aucun historique trouvé", style: TextStyle(color: Colors.grey))]));
}*/




import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../booking/data/models/claim_model.dart';
import '../../../booking/data/models/categorie_models.dart';
import '../../../booking/data/repositories/support_repository.dart';

class ClaimsHistoryScreen extends StatefulWidget {
  final String? initialType;
  const ClaimsHistoryScreen({super.key, this.initialType});

  @override
  State<ClaimsHistoryScreen> createState() => _ClaimsHistoryScreenState();
}

class _ClaimsHistoryScreenState extends State<ClaimsHistoryScreen> {
  final SupportRepository _repository = SupportRepository();
  List<SupportCategory> _categories = [];
  List<Claim> _claims = [];
  String? _selectedTypeId;
  bool _isLoading = true;
  bool _isSendingReply = false;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.initialType;
    _initData();
  }

  // --- NOTIFICATION PERSONNALISÉE ---
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
              color: isError ? const Color(0xFF222222) : Colors.green.shade700,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.info_outline : Icons.check_circle, color: Colors.white, size: 20),
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

  Future<void> _initData() async {
    try {
      final cats = await _repository.fetchCategories();
      setState(() => _categories = cats);
      _loadHistory(_selectedTypeId);
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopNotification("Erreur de chargement des catégories");
    }
  }

  Future<void> _loadHistory(String? typeId) async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.fetchClaimsHistory(typeId);
      setState(() {
        _claims = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopNotification("Impossible de récupérer l'historique");
    }
  }

  Future<void> _handleReply(int claimId, String message) async {
    if (message.trim().isEmpty) {
      _showTopNotification("Le message ne peut pas être vide");
      return;
    }

    try {
      final success = await _repository.sendSupportReply(claimId, message);
      if (success) {
        if (mounted) Navigator.pop(context);
        _loadHistory(_selectedTypeId);
        _showTopNotification("Réponse envoyée avec succès", isError: false);
      }
    } catch (e) {
      _showTopNotification("Échec de l'envoi de la réponse");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Mes Réclamations", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : RefreshIndicator(
              onRefresh: () => _loadHistory(_selectedTypeId),
              child: _claims.isEmpty ? _buildEmptyState() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        children: [
          _filterChip(null, "Tout", Colors.black),
          ..._categories.map((cat) => _filterChip(cat.id, cat.title, Color(int.parse(cat.color.replaceFirst('#', '0xff'))))),
        ],
      ),
    );
  }

  Widget _filterChip(String? id, String label, Color color) {
    final isSelected = _selectedTypeId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedTypeId = id);
          _loadHistory(id);
        },
        selectedColor: color,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _claims.length,
      separatorBuilder: (_, __) => const Gap(15),
      itemBuilder: (context, index) {
        final claim = _claims[index];
        final bool isClosed = claim.statut.toLowerCase() == "ferme" || claim.statut.toLowerCase() == "terminee";

        return InkWell(
          onTap: () => _showClaimDetails(context, claim),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(claim.objet, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(claim.typeLabel, style: TextStyle(color: Colors.orange[800], fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
                if (claim.reservation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _rowInfo(Icons.directions_bus, "${claim.reservation!['gare_depart']} → ${claim.reservation!['gare_arrivee']}"),
                  ),
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(claim.createdAt.split(' ')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      _statusBadge(claim.statut, isClosed),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClaimDetails(BuildContext context, Claim claim) {
    final TextEditingController replyController = TextEditingController();
    final bool isClosed = claim.statut.toLowerCase() == "ferme" || claim.statut.toLowerCase() == "terminee";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(claim.objet, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    _statusBadge(claim.statut, isClosed),
                  ],
                ),
                const Gap(15),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(10),
                        _sectionTitle("DESCRIPTION"),
                        Text(claim.description, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),

                        if (claim.reservation != null) ...[
                          const Gap(25),
                          _sectionTitle("DÉTAILS DU TRAJET"),
                          _detailTile(Icons.tag, "Référence", claim.reservation!['reference']),
                          _detailTile(Icons.map_outlined, "Itinéraire", "${claim.reservation!['gare_depart']} → ${claim.reservation!['gare_arrivee']}"),
                          _detailTile(Icons.calendar_month, "Date du voyage", claim.reservation!['date']),
                        ],

                        const Gap(25),
                        _sectionTitle("DISCUSSION / RÉPONSE DU SUPPORT"),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: claim.reponse != null ? Colors.green[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: claim.reponse != null ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3))
                          ),
                          child: Text(
                            claim.reponse ?? "Nous analysons votre demande. Une réponse vous sera apportée ici sous peu.",
                            style: TextStyle(color: claim.reponse != null ? Colors.green[900] : Colors.blue[900], height: 1.4),
                          ),
                        ),

                        if (!isClosed) ...[
                          const Gap(20),
                          _sectionTitle("VOTRE RÉPONSE"),
                          TextField(
                            controller: replyController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Écrivez votre message ici...",
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap(15),
                Row(
                  children: [
                    if (!isClosed)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSendingReply ? null : () async {
                            setModalState(() => _isSendingReply = true);
                            await _handleReply(claim.id, replyController.text);
                            setModalState(() => _isSendingReply = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSendingReply
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Répondre au support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("Fermer", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const Gap(8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis))
      ]
  );

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)));

  Widget _detailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.orange[800]),
          const Gap(10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$label : ", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const Gap(5),
                Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, bool isClosed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isClosed ? Colors.grey[200] : Colors.green[100], borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(), style: TextStyle(color: isClosed ? Colors.grey[700] : Colors.green[800], fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.history, size: 60, color: Colors.grey), const Gap(15), const Text("Aucun historique trouvé", style: TextStyle(color: Colors.grey))]));
}