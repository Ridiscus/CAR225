import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';

const _kNavy = Color(0xFF0f172a);

class DriverPersonalInfoScreen extends StatefulWidget {
  const DriverPersonalInfoScreen({super.key});

  @override
  State<DriverPersonalInfoScreen> createState() =>
      _DriverPersonalInfoScreenState();
}

class _DriverPersonalInfoScreenState extends State<DriverPersonalInfoScreen> {
  bool _editMode = false;
  bool _saving = false;

  // Editable controllers
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _urgenceCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<DriverProvider>().profile;
    _nomCtrl    = TextEditingController(text: profile?.name ?? '');
    _prenomCtrl = TextEditingController(text: profile?.prenom ?? '');
    _emailCtrl  = TextEditingController(text: profile?.email ?? '');
    _contactCtrl = TextEditingController(text: profile?.contact ?? '');
    _urgenceCtrl = TextEditingController(text: profile?.contactUrgence ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _urgenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<DriverProvider>().updateProfileFields({
        if (_nomCtrl.text.trim().isNotEmpty)    'name':  _nomCtrl.text.trim(),
        if (_prenomCtrl.text.trim().isNotEmpty) 'prenom': _prenomCtrl.text.trim(),
        'email':   _emailCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        if (_urgenceCtrl.text.trim().isNotEmpty)
          'contact_urgence': _urgenceCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _editMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _enterEdit() {
    final profile = context.read<DriverProvider>().profile;
    _nomCtrl.text    = profile?.name ?? '';
    _prenomCtrl.text = profile?.prenom ?? '';
    _emailCtrl.text  = profile?.email ?? '';
    _contactCtrl.text = profile?.contact ?? '';
    _urgenceCtrl.text = profile?.contactUrgence ?? '';
    setState(() => _editMode = true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final profile = provider.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Informations Personnelles',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          if (!_editMode)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppColors.primary, size: 18),
              ),
              onPressed: _enterEdit,
            )
          else ...[
            TextButton(
              onPressed: () => setState(() => _editMode = false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.check_rounded,
                        color: AppColors.primary),
                    onPressed: _save,
                  ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(child: _buildAvatar(provider, profile)),
              ),
            ),
            const Gap(8),
            if (profile != null) ...[
              Text(
                '${profile.prenom ?? ''} ${profile.name ?? ''}'.trim(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const Gap(4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.codeId ?? '—',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            if (_editMode) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        color: AppColors.primary, size: 16),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Mode édition actif — modifiez vos coordonnées ci-dessous.',
                        style: TextStyle(
                            color: AppColors.primary.withOpacity(0.8),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Gap(28),

            // ── Identité ──
            _buildSectionLabel('IDENTITÉ'),
            const Gap(8),
            _buildCard(children: [
              _editMode
                  ? _EditField(
                      icon: Icons.person_outline_rounded,
                      label: 'NOM',
                      controller: _nomCtrl,
                    )
                  : _Field(
                      icon: Icons.person_outline_rounded,
                      label: 'NOM',
                      value: profile?.name ?? '—',
                    ),
              _Divider(),
              _editMode
                  ? _EditField(
                      icon: Icons.person_outline_rounded,
                      label: 'PRÉNOM',
                      controller: _prenomCtrl,
                    )
                  : _Field(
                      icon: Icons.person_outline_rounded,
                      label: 'PRÉNOM',
                      value: profile?.prenom ?? '—',
                    ),
              _Divider(),
              _Field(
                icon: Icons.badge_outlined,
                label: 'CODE ID',
                value: profile?.codeId ?? '—',
              ),
              _Divider(),
              _Field(
                icon: Icons.work_outline_rounded,
                label: 'RÔLE',
                value: profile?.role ?? 'Chauffeur',
              ),
            ]),

            const Gap(16),

            // ── Coordonnées (modifiables) ──
            _buildSectionLabel('COORDONNÉES'),
            const Gap(8),
            _buildCard(children: [
              _editMode
                  ? _EditField(
                      icon: Icons.email_outlined,
                      label: 'EMAIL',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    )
                  : _Field(
                      icon: Icons.email_outlined,
                      label: 'EMAIL',
                      value: profile?.email ?? '—',
                    ),
              _Divider(),
              _editMode
                  ? _EditField(
                      icon: Icons.phone_outlined,
                      label: 'CONTACT',
                      controller: _contactCtrl,
                      keyboardType: TextInputType.phone,
                    )
                  : _Field(
                      icon: Icons.phone_outlined,
                      label: 'CONTACT',
                      value: profile?.contact ?? '—',
                    ),
              _Divider(),
              _editMode
                  ? _EditField(
                      icon: Icons.emergency_outlined,
                      label: 'CONTACT URGENCE',
                      controller: _urgenceCtrl,
                      keyboardType: TextInputType.phone,
                    )
                  : _Field(
                      icon: Icons.emergency_outlined,
                      label: 'CONTACT URGENCE',
                      value: profile?.contactUrgence ?? '—',
                    ),
            ]),

            const Gap(16),

            // ── Compagnie (lecture seule) ──
            _buildSectionLabel('COMPAGNIE'),
            const Gap(8),
            _buildCard(children: [
              _Field(
                icon: Icons.business_rounded,
                label: 'COMPAGNIE',
                value: profile?.compagnie?.name ?? '—',
              ),
              _Divider(),
              _Field(
                icon: Icons.location_city_rounded,
                label: 'GARE D\'ATTACHE',
                value: profile?.gare?.nomGare ?? '—',
              ),
              _Divider(),
              _Field(
                icon: Icons.location_on_outlined,
                label: 'COMMUNE',
                value: profile?.commune ?? '—',
              ),
              _Divider(),
              _Field(
                icon: Icons.verified_rounded,
                label: 'STATUT',
                value: profile?.statut ?? '—',
                valueColor: AppColors.secondary,
              ),
            ]),

            const Gap(20),

            // ── Bannière info ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Code ID, compagnie et gare sont gérés par l\'administration et ne peuvent pas être modifiés.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_editMode) ...[
              const Gap(20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded,
                          color: Colors.white, size: 20),
                  label: const Text('ENREGISTRER LES MODIFICATIONS',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            const Gap(30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildAvatar(DriverProvider provider, dynamic profile) {
    if (provider.profileImage != null) {
      return Image.file(provider.profileImage!, fit: BoxFit.cover);
    }
    if (profile?.fullProfilePictureUrl != null) {
      return Image.network(
        profile!.fullProfilePictureUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(profile),
      );
    }
    return Container(
      color: const Color(0xFF1e293b),
      child: _initials(profile),
    );
  }

  Widget _initials(dynamic profile) {
    final p = profile?.prenom?.isNotEmpty == true
        ? (profile.prenom as String)[0].toUpperCase()
        : '';
    final n = profile?.name?.isNotEmpty == true
        ? (profile.name as String)[0].toUpperCase()
        : '';
    return Center(
      child: Text('$p$n',
          style: const TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAMP LECTURE SEULE
// ─────────────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _Field({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    )),
                const Gap(2),
                Text(value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? const Color(0xFF1E293B),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAMP ÉDITABLE
// ─────────────────────────────────────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _EditField({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    )),
                const Gap(2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(4),
          Icon(Icons.edit_rounded,
              color: AppColors.primary.withOpacity(0.4), size: 14),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, indent: 52, endIndent: 0, color: Color(0xFFF1F5F9));
  }
}
