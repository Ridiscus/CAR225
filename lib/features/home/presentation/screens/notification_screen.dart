import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dio/dio.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/core/services/networking/api_config.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/providers/user_provider.dart'; 
import 'package:car225/features/driver/presentation/providers/driver_provider.dart';
import 'package:car225/features/driver/data/models/driver_message_model.dart';
import '../../../booking/data/models/notification_model.dart';
import '../../../booking/data/repositories/notification_repository.dart';



class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin { // 👈 AJOUT DU MIXIN
  // --- ÉTAT ---
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  List<DriverMessageModel> _driverMessages = [];
  String? _errorMessage;

  // Pour gérer l'affichage des notifications Overlay
  OverlayEntry? _overlayEntry;

  late final NotificationRepository _repository;

  // 🟢 1. DÉCLARATION DU CONTROLLER
  late AnimationController _entranceController;




  @override
  void initState() {
    super.initState();

    // 🟢 2. INITIALISATION DU CONTROLLER
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Garde 800ms pour que ce soit dynamique
      vsync: this,
    );

    // Configuration Dio + Repo
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      validateStatus: (status) => status! < 500,
    ));
    _repository = NotificationRepository(dio: dio);

    _loadData();
  }

  @override
  void dispose() {
    _removeOverlay();
    // 🟢 3. NE PAS OUBLIER LE DISPOSE
    _entranceController.dispose();
    super.dispose();
  }



Future<void> _loadData() async {
  if (!mounted) return;
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final userProvider = context.read<UserProvider>();
    final driverProvider = context.read<DriverProvider>();
    final token = userProvider.token;

    // 1. Charger d'abord les messages chauffeur (ceux qui font le badge)
    // On le fait indépendamment du token des notifications générales
    await driverProvider.loadMessages().catchError((e) => print("Erreur messages chauffeur: $e"));

    // 2. Tenter de charger les notifications générales si le token existe
    if (token != null && token.isNotEmpty) {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ));
      final repository = NotificationRepository(dio: dio);
      
      try {
        final generalNotifs = await repository.getNotifications();
        _notifications = generalNotifs;
      } catch (e) {
        print("Erreur notifications générales (souvent normal pour un driver): $e");
      }
    }

    if (mounted) {
      setState(() {
        _driverMessages = driverProvider.messages; // On synchronise avec le provider
        _isLoading = false;
      });
      _entranceController.forward(from: 0.0);
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      print("Erreur globale chargement: $e");
    }
  }
}

  // --- GESTION TOP NOTIFICATION (OVERLAY) ---
  void _showTopNotification(String message, {bool isError = true}) {
    _removeOverlay(); // Enlever l'ancienne si elle existe encore

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Juste sous la barre de statut
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)), // Petit effet de descente
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C), // Rouge ou Vert
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
      ),
    );

    overlay.insert(_overlayEntry!);

    // Disparition auto après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // --- ACTIONS LOGIQUES ---

  Future<void> _handleMarkAsRead(NotificationModel notif, int index) async {
    if (notif.isRead) return; // Déjà lu

    // 1. Mise à jour VISUELLE immédiate (Optimistic UI)
    setState(() {
      // On suppose que tu as une méthode copyWith dans ton modèle
      // Sinon tu dois recréer l'objet manuellement
      // _notifications[index] = notif.copyWith(readAt: DateTime.now());

      // EXEMPLE SI PAS DE COPYWITH (Hack temporaire pour l'affichage) :
      // On modifie juste l'objet en mémoire si c'est possible, ou on le recharge.
      // Le mieux est d'avoir `copyWith` dans ton NotificationModel.
    });

    try {
      // 2. Appel API
      await _repository.markAsRead(notif.id);

      // 3. Recharger pour être sûr (optionnel si copyWith marche bien)
      _loadData();
    } catch (e) {
      _showTopNotification("Erreur lors de la mise à jour", isError: true);
    }
  }

  Future<void> _handleMarkAllRead() async {
    try {
      await _repository.markAllAsRead();
      _loadData();
      _showTopNotification("Tout est marqué comme lu !", isError: false);
    } catch (e) {
      _showTopNotification("Erreur réseau", isError: true);
    }
  }

  Future<void> _handleDelete(String id, int index) async {
    final deletedItem = _notifications[index];
    setState(() => _notifications.removeAt(index)); // Supprime visuellement tout de suite

    try {
      await _repository.deleteNotification(id);
      // Pas de message de succès pour une suppression swipe, c'est plus fluide
    } catch (e) {
      // Rollback si erreur
      setState(() => _notifications.insert(index, deletedItem));
      _showTopNotification("Impossible de supprimer", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Notifications", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          if (_notifications.any((n) => !n.isRead)) // Affiche le bouton seulement s'il y a des non-lues
            IconButton(
              tooltip: "Tout marquer comme lu",
              icon: Icon(Icons.done_all, color: Colors.blue[700]),
              onPressed: _handleMarkAllRead,
            ),
          const Gap(10),
        ],
      ),
     body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : _errorMessage != null
        ? _buildErrorState()
        // MODIFICATION ICI : On vérifie si les DEUX listes sont vides
        : (_notifications.isEmpty && _driverMessages.isEmpty)
            ? _buildEmptyState() 
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          itemCount: _notifications.length + _driverMessages.length,
          separatorBuilder: (context, index) => const Gap(15),
          itemBuilder: (context, index) {
            // Logique de fusion : on affiche d'abord les messages non lus du chauffeur
            // (Tu peux adapter l'ordre selon ce que tu préfères)
            
            if (index < _driverMessages.length) {
                final msg = _driverMessages[index];
                return _buildDriverMessageCard(context, msg, index);
            }
            
            final notif = _notifications[index - _driverMessages.length];

            // 🟢 5. CALCUL DE L'ANIMATION EN CASCADE
            final double startDelay = (index % 10) * 0.1;
            final double endDelay = (startDelay + 0.5).clamp(0.0, 1.0);

            final animation = CurvedAnimation(
              parent: _entranceController,
              curve: Interval(startDelay, endDelay, curve: Curves.easeOutCubic),
            );

            // 🟢 6. APPLICATION VISUELLE
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3), // Glisse vers le haut
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                  ),
                  onDismissed: (_) => _handleDelete(notif.id, index),
                  child: _buildNotificationCard(context, notif, index),
                ),
              ),
            );
          },

        ),
      ),
    );
  }

  // --- AFFICHAGE DE LA MODALE DE DÉTAILS ---
  void _showNotificationModal(BuildContext context, NotificationModel notif) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet à la modale de prendre la taille nécessaire
      backgroundColor: Colors.transparent, // Fond transparent pour voir les bords arrondis
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // S'adapte au contenu
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Petite barre grise en haut pour indiquer le "drag"
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Gap(25),

            // En-tête : Icône + Titre + Date
            Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: notif.bgColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(notif.icon, color: notif.color, size: 30),
                ),
                const Gap(15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Gap(4),
                      Text(
                        notif.timeAgo,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(25),

            // Contenu de la notification (Texte complet)
            Text(
              notif.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const Gap(35),

            // Bouton pour fermer
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: notif.color.withOpacity(0.1),
                  foregroundColor: notif.color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Fermer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Padding supplémentaire pour les téléphones sans bordures (iPhone, etc.)
            Gap(MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    ).then((_) {
      // Quand la modale se ferme, on recharge la liste pour être sûr de l'état "lu"
      _loadData();
    });
  }

  // --- VISUEL DE LA CARTE ---
  Widget _buildNotificationCard(BuildContext context, NotificationModel notif, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 💡 C'est ICI qu'on fait la différence visuelle
    final bool isRead = notif.isRead;

    return GestureDetector(
      /*onTap: () {
        _handleMarkAsRead(notif, index);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationDetailScreen(notif: notif)),
        ).then((_) => _loadData()); // Recharger au retour
      },*/
      onTap: () {
        // 1. On marque comme lu
        _handleMarkAsRead(notif, index);

        // 2. On affiche la modale au lieu de changer de page
        _showNotificationModal(context, notif);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          // 🎨 COULEUR DE FOND : Blanc/Gris si Lu, Bleu très clair si Non Lu
          color: isRead
              ? (isDark ? Colors.grey[900] : Colors.white)
              : (isDark ? Colors.grey[800] : Colors.blue.withOpacity(0.08)),

          borderRadius: BorderRadius.circular(15),

          // 🎨 OMBRE : Plus légère si lu, plus marquée si non lu
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isRead ? 0.02 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],

          // 🎨 BORDURE : Transparente si lu, Bleue fine si non lu
          border: Border.all(
            color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: notif.bgColor.withOpacity(0.2), // On force un peu l'opacité
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notif.icon, color: notif.color, size: 24),
            ),
            const Gap(15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            // ✍️ TEXTE : Gras si Non lu
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w800,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(5),
                      Text(
                        notif.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          // ✍️ DATE : Bleu si non lu
                          color: isRead ? Colors.grey[500] : Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(5),
                  Text(
                    notif.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // 🔴 POINT ROUGE : Indication ultime de non-lecture
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(left: 10, top: 5),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 4)
                    ]
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDriverMessageCard(BuildContext context, DriverMessageModel msg, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isRead = msg.isRead;

    return GestureDetector(
    onTap: () {
      final driverProvider = context.read<DriverProvider>();
      
      // 1. Marquer comme lu
      driverProvider.markMessageAsRead(msg);
      
      // 2. Préparer la redirection vers l'onglet message
      driverProvider.navigateToMessage(msg);
      
      // 3. Retourner à l'écran principal (le Wrapper changera d'onglet tout seul)
      Navigator.pop(context);
    },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? Colors.grey[900] : Colors.white)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isRead ? 0.02 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 24),
            ),
            const Gap(15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          msg.subject,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w800,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(5),
                      Text(
                        "${msg.createdAt.day}/${msg.createdAt.month} à ${msg.createdAt.hour}:${msg.createdAt.minute}",
                        style: TextStyle(
                          fontSize: 11,
                          color: isRead ? Colors.grey[500] : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(5),
                  Text(
                    msg.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(left: 10, top: 5),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Text(_errorMessage ?? "Erreur"));
  }

  Widget _buildEmptyState() {
    // ... (Même code que précédemment)
    return const Center(child: Text("Aucune notification"));
  }
}
