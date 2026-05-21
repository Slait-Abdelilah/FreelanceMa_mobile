import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/brand_button.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = UserService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _svc.getProfile();
      if (mounted) setState(() { _profile = p; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    final current = _profile?['available'] == true;
    try {
      await _svc.updateProfile({'available': !current});
      if (mounted) setState(() => _profile?['available'] = !current);
    } catch (_) {}
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        service: _svc,
        profile: _profile ?? {},
        onDone: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (_loading) return const SingleChildScrollView(child: SkeletonList());

    final isAvailable = _profile?['available'] == true;
    final skillsRaw = _profile?['skills'] as String?;
    final skills = (skillsRaw != null && skillsRaw.isNotEmpty)
        ? skillsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brand500,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + edit button
            Stack(
              alignment: Alignment.topRight,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0, right: 0),
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.brand100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user?.initials ?? '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showEditSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Availability toggle
            GestureDetector(
              onTap: _toggleAvailability,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isAvailable ? AppColors.brand100 : AppColors.sidebarActive,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAvailable ? AppColors.brand500.withValues(alpha: 0.3) : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.brand500 : AppColors.inkMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAvailable ? 'Disponible pour missions' : 'Non disponible',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? AppColors.brand700 : AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: isAvailable ? AppColors.brand500 : AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info card
            _InfoCard(
              title: 'Informations professionnelles',
              onEdit: _showEditSheet,
              items: [
                if (_profile?['title'] != null)
                  ('Titre', _profile!['title'].toString()),
                if (_profile?['experienceLevel'] != null)
                  ('Niveau', _levelLabel(_profile!['experienceLevel'])),
                if (_profile?['hourlyRate'] != null)
                  ('Tarif horaire', '${_profile!['hourlyRate']} DH/h'),
                if (_profile?['location'] != null)
                  ('Localisation', _profile!['location'].toString()),
              ],
            ),

            if (_profile?['bio'] != null) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'À propos',
                onEdit: _showEditSheet,
                child: Text(
                  _profile!['bio'].toString(),
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.5),
                ),
              ),
            ],

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Compétences',
                onEdit: _showEditSheet,
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sidebarActive,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  )).toList(),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showEditSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.brand500, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ajouter vos compétences',
                        style: TextStyle(color: AppColors.brand500, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _levelLabel(dynamic level) {
    const map = {
      'JUNIOR':       'Junior',
      'INTERMEDIATE': 'Intermédiaire',
      'SENIOR':       'Senior',
      'EXPERT':       'Expert',
    };
    return map[level?.toString()] ?? level?.toString() ?? '—';
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> items;
  final VoidCallback onEdit;

  const _InfoCard({required this.title, required this.items, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.$1, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onEdit;

  const _SectionCard({required this.title, required this.child, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserService service;
  final Map<String, dynamic> profile;
  final VoidCallback onDone;

  const _EditProfileSheet({
    required this.service,
    required this.profile,
    required this.onDone,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _locationCtrl;
  String _level = 'JUNIOR';
  bool _loading = false;

  static const _levels = [
    ('JUNIOR',        'Junior'),
    ('INTERMEDIATE',  'Intermédiaire'),
    ('SENIOR',        'Senior'),
    ('EXPERT',        'Expert'),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _titleCtrl = TextEditingController(text: p['title']?.toString() ?? '');
    _bioCtrl = TextEditingController(text: p['bio']?.toString() ?? '');
    final skills = p['skills'];
    _skillsCtrl = TextEditingController(
      text: skills is List ? skills.join(', ') : (skills?.toString() ?? ''),
    );
    _rateCtrl = TextEditingController(
      text: p['hourlyRate'] != null ? p['hourlyRate'].toString() : '',
    );
    _locationCtrl = TextEditingController(text: p['location']?.toString() ?? '');
    _level = ['JUNIOR', 'INTERMEDIATE', 'SENIOR', 'EXPERT'].contains(p['experienceLevel'])
        ? p['experienceLevel']
        : 'JUNIOR';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    _rateCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final skills = _skillsCtrl.text.trim().isEmpty
        ? null
        : _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    try {
      await widget.service.updateProfile({
        if (_titleCtrl.text.isNotEmpty) 'title': _titleCtrl.text.trim(),
        if (_bioCtrl.text.isNotEmpty) 'bio': _bioCtrl.text.trim(),
        if (skills != null) 'skills': skills.join(','),
        if (_rateCtrl.text.isNotEmpty) 'hourlyRate': double.tryParse(_rateCtrl.text),
        if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
        'experienceLevel': _level,
      });
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        widget.onDone();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: AppColors.brand500,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Modifier le profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre professionnel',
                hintText: 'Ex: Développeur Flutter Senior',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Présentez-vous en quelques lignes...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillsCtrl,
              decoration: const InputDecoration(
                labelText: 'Compétences',
                hintText: 'Flutter, Dart, Firebase',
                helperText: 'Séparez par des virgules',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Niveau d\'expérience'),
              items: _levels.map((l) => DropdownMenuItem(
                value: l.$1,
                child: Text(l.$2),
              )).toList(),
              onChanged: (v) => setState(() => _level = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tarif horaire (DH/h)',
                prefixText: 'DH ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Localisation',
                hintText: 'Ex: Casablanca, Maroc',
                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 24),
            BrandButton(label: 'Enregistrer', loading: _loading, onTap: _submit),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
