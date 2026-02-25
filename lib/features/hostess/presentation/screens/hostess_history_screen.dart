import 'package:flutter/material.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';

class HostessHistoryScreen extends StatelessWidget {
  const HostessHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Historique des Réservations',
        showLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 5,
        itemBuilder: (context, index) => _buildHistoryItem(),
      ),
    );
  }

  Widget _buildHistoryItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abidjan → Bouaké',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF263238),
                  ),
                ),
                Text(
                  '09 Fév 2026 • 14:30',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const Text(
            '15,000 F',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }
}
