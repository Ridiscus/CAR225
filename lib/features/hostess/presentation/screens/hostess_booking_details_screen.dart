import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import 'package:car225/features/hostess/models/passenger_info.dart';
import 'hostess_ticket_result_screen.dart';

class HostessBookingDetailsScreen extends StatefulWidget {
  final String departure;
  final String arrival;
  final bool isRoundTrip;

  const HostessBookingDetailsScreen({
    super.key,
    required this.departure,
    required this.arrival,
    required this.isRoundTrip,
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
    return lastNameController.text.isNotEmpty &&
        firstNameController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        procheNumberController.text.isNotEmpty;
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
  final int _oneWayPrice = 100;
  final int _roundTripPrice = 200;

  // Heure de départ
  String _selectedTime = '08:00';
  final List<String> _timeSlots = [
    '08:00',
    '09:30',
    '11:00',
    '13:30',
    '15:00',
    '16:30',
    '18:00',
    '20:30',
  ];

  // Nombre de passagers et formulaires
  int _passengerCount = 1;
  final List<_PassengerFormData> _passengerForms = [_PassengerFormData()];
  int _currentPassengerIndex = 0;

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
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTripInfo(),
                const Gap(20),
                _buildTripTypeSection(),
                const Gap(20),
                _buildTimeSection(),
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
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildCityInfo(widget.departure, 'Départ')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          Expanded(child: _buildCityInfo(widget.arrival, 'Arrivée')),
        ],
      ),
    );
  }

  Widget _buildCityInfo(String city, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(4),
        Text(
          city,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
    return GestureDetector(
      onTap: () => setState(() => _tripType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
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
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
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
    );
  }

  Widget _buildTimeSection() {
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
  }

  Widget _buildTimeChip(String time) {
    bool isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

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
          ),
          const Gap(12),
          _buildTextField(
            label: 'Email (optionnel)',
            icon: Icons.email_outlined,
            controller: currentForm.emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const Gap(12),
          _buildTextField(
            label: "Contact d'urgence",
            icon: Icons.phone_outlined,
            controller: currentForm.procheNumberController,
            keyboardType: TextInputType.phone,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Gap(8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: "Entrez $label",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _showConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'CONFIRMER LA VENTE',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
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
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invalidPassengers.length == 1
                ? 'Veuillez remplir tous les champs obligatoires du passager ${invalidPassengers.first}'
                : 'Veuillez remplir tous les champs obligatoires des passagers: ${invalidPassengers.join(", ")}',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      // Naviguer vers le premier passager invalide
      if (invalidPassengers.isNotEmpty) {
        setState(() => _currentPassengerIndex = invalidPassengers.first - 1);
      }
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
                          _buildDialogRow('Heure', _selectedTime),
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
                            Navigator.pop(context);
                            _confirmSale();
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
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? AppColors.primary : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            color: isTotal ? AppColors.primary : const Color(0xFF1A1A1A),
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
      print('ERROR: passengers list is empty!');
      print('_passengerForms length: ${_passengerForms.length}');
      print('_passengerCount: $_passengerCount');
      return;
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => HostessTicketResultScreen(
          isRoundTrip: _tripType == 'Aller-Retour',
          passengers: passengers,
          departure: widget.departure,
          arrival: widget.arrival,
          travelDate: '11/02/2026',
          travelTime: _selectedTime,
          totalPrice: totalPrice,
        ),
      ),
    );
  }
}
