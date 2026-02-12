import 'package:car225/features/home/presentation/screens/ticket_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/widgets/ticket_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/data/models/ticket_model.dart';
import '../../../booking/domain/repositories/ticket_repository.dart';

class AllTicketsSearchScreen extends StatefulWidget {
  final List<TicketModel> allTickets;
  final TicketRepository repository;
  // On passe la méthode de téléchargement du parent pour éviter de dupliquer la logique complexe
  final Function(TicketModel) onDownload;
  final Set<String> downloadingIds;

  const AllTicketsSearchScreen({
    super.key,
    required this.allTickets,
    required this.repository,
    required this.onDownload,
    required this.downloadingIds,
  });

  @override
  State<AllTicketsSearchScreen> createState() => _AllTicketsSearchScreenState();
}

class _AllTicketsSearchScreenState extends State<AllTicketsSearchScreen> {
  String searchQuery = "";
  late List<TicketModel> filteredTickets;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredTickets = widget.allTickets;
  }

  void _filterTickets(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredTickets = widget.allTickets;
      } else {
        filteredTickets = widget.allTickets.where((ticket) {
          final q = query.toLowerCase();
          return ticket.companyName.toLowerCase().contains(q) ||
              ticket.route.toLowerCase().contains(q) ||
              ticket.ticketNumber.toLowerCase().contains(q) ||
              ticket.seatNumber.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Tous mes tickets", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- BARRE DE RECHERCHE DESIGN ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: backgroundColor,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterTickets,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Rechercher (Compagnie, Ville, Siège...)",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterTickets("");
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          const Gap(10),

          // --- LISTE DES RÉSULTATS ---
          Expanded(
            child: filteredTickets.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 50, color: Colors.grey[300]),
                  const Gap(10),
                  Text("Aucun ticket trouvé", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filteredTickets.length,
              separatorBuilder: (context, index) => const Gap(20),
              itemBuilder: (context, index) {
                final ticket = filteredTickets[index];
                return TicketCard(
                  ticket: ticket,
                  isDownloading: widget.downloadingIds.contains(ticket.id),
                  onDetailPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailScreen(initialTicket: ticket, repository: widget.repository)));
                  },
                  onDownloadPressed: () => widget.onDownload(ticket),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}