/*import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/models/agent_dashboard_data.dart';
import '../../data/repositories/agent_repository_impl.dart';
import 'agent_profile_screen.dart';
import 'ticket_scanner_screen.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}



class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AgentDashboardData? _dashboardData;
  int _scannedToday = 0;
  int _totalScanned = 0;
  late final AgentRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    print("🟢 1. INIT STATE DU DASHBOARD DÉCLENCHÉ"); // <- AJOUTE CECI
    _repository = AgentRepositoryImpl(
      remoteDataSource: AgentRemoteDataSourceImpl(),
    );
    _fetchDashboard();
  }


  Future<void> _fetchDashboard() async {
    print("🟢 2. FETCH DASHBOARD LANCÉ"); // <- AJOUTE CECI
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF4500), Color(0xFFFF6B35)],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                ? _buildErrorState()
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        const Gap(20),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Gap(30),
                const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Gap(30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Scannés',
                          _dashboardData!.ticketsScanned.toString(),
                          Icons.check_circle_outline,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      const Gap(15),
                      Expanded(
                        child: _buildStatCard(
                          'À scanner',
                          _dashboardData!.ticketsToScan.toString(),
                          Icons.qr_code,
                          const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(40),
                _buildScanButton(),
                const Gap(30),
                // Liste des programmes du jour à la place de l'historique vide
                Expanded(child: _buildProgramsList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 60),
          const Gap(16),
          Text(
            _errorMessage ?? "Erreur",
            style: const TextStyle(color: Colors.white),
          ),
          const Gap(20),
          ElevatedButton(
            onPressed: _fetchDashboard,
            child: const Text("Réessayer"),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.person, color: Color(0xFFFF4500), size: 28),
          ),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dashboardData!.agentRole,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  _dashboardData!.agentName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AgentProfileScreen())),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsList() {
    if (_dashboardData!.programs.isEmpty) {
      return const Center(child: Text("Aucun programme pour aujourd'hui."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Programmes du jour (${_dashboardData!.totalPrograms})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
        ),
        const Gap(10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _dashboardData!.programs.length,
            itemBuilder: (context, index) {
              final program = _dashboardData!.programs[index];
              return Card(
                elevation: 0,
                color: Colors.grey[100],
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, color: Color(0xFFFF4500)),
                  title: Text("${program.departure} → ${program.destination}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${program.departureTime} - ${program.occupation}"),
                  trailing: Text(program.status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const Gap(10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              CupertinoPageRoute(
                builder: (context) => const TicketScannerScreen(),
              ),
            );
            // Si un ticket a été scanné avec succès
            if (result == true) {
              setState(() {
                _scannedToday++;
                _totalScanned++;
              });
            }
          },
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4500), Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4500).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const Gap(15),
                  const Text(
                    'Scanner un ticket',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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


}*/