import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/brand_button.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  final _svc = UserService();
  Map<String, dynamic>? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _svc.getSettings();
      if (mounted) setState(() { _settings = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSheet(Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = [
      _settings?['firstName'] as String? ?? '',
      _settings?['lastName']  as String? ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête utilisateur
                  if (_settings != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (name.isNotEmpty)
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                Text(
                                  _settings?['email'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Compte
                  _Section(title: 'COMPTE', children: [
                    _Tile(
                      icon: Icons.lock_outline,
                      label: 'Changer le mot de passe',
                      onTap: () => _showSheet(_ChangePasswordSheet()),
                    ),
                    _Tile(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      subtitle: (_settings?['phone'] as String?)?.isNotEmpty == true
                          ? _settings!['phone'] as String
                          : 'Non renseigné',
                      onTap: () => _showSheet(
                        _EditAccountSheet(
                          phone: _settings?['phone'] as String? ?? '',
                          language: _settings?['language'] as String? ?? '',
                          currency: _settings?['currency'] as String? ?? '',
                          onSaved: _load,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  BrandButton(
                    label: 'Se déconnecter',
                    outline: true,
                    onTap: () async {
                      final auth = context.read<AuthProvider>();
                      await auth.logout();
                      if (context.mounted) context.go('/login/client');
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.inkMuted, letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children.expand((w) => [w, const Divider(height: 1)]).toList()
              ..removeLast(),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.inkSoft, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted, size: 18),
      onTap: onTap,
      dense: true,
    );
  }
}

// ── Changer mot de passe ──────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _authSvc = AuthService();
  final _currCtrl = TextEditingController();
  final _newCtrl  = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_currCtrl.text.isEmpty) {
      setState(() => _error = 'Saisissez votre mot de passe actuel');
      return;
    }
    if (_newCtrl.text.length < 8) {
      setState(() => _error = 'Le nouveau mot de passe doit contenir au moins 8 caractères');
      return;
    }
    setState(() => _loading = true);
    try {
      await _authSvc.changePassword(_currCtrl.text, _newCtrl.text);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès'),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Mot de passe actuel incorrect'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Changer le mot de passe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _currCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nouveau mot de passe (min. 8 caractères)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          BrandButton(label: 'Modifier', loading: _loading, onTap: _submit),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Modifier infos compte ─────────────────────────────────────────────────────

class _EditAccountSheet extends StatefulWidget {
  final String phone;
  final String language;
  final String currency;
  final VoidCallback onSaved;
  const _EditAccountSheet({
    required this.phone,
    required this.language,
    required this.currency,
    required this.onSaved,
  });

  @override
  State<_EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends State<_EditAccountSheet> {
  final _svc = UserService();
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _langCtrl;
  late final TextEditingController _currCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.phone);
    _langCtrl  = TextEditingController(text: widget.language);
    _currCtrl  = TextEditingController(text: widget.currency);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _langCtrl.dispose();
    _currCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _svc.updateAccount({
        'phone':    _phoneCtrl.text.trim(),
        'language': _langCtrl.text.trim(),
        'currency': _currCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Erreur lors de la mise à jour'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du compte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _langCtrl,
            decoration: const InputDecoration(
              labelText: 'Langue (ex: fr)',
              prefixIcon: Icon(Icons.language_outlined, color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currCtrl,
            decoration: const InputDecoration(
              labelText: 'Devise (ex: MAD)',
              prefixIcon: Icon(Icons.attach_money_outlined, color: AppColors.inkSoft),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          BrandButton(label: 'Enregistrer', loading: _loading, onTap: _submit),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
