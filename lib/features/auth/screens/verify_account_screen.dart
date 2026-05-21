import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/brand_button.dart';

class VerifyAccountScreen extends StatefulWidget {
  final String email;
  final String role;
  const VerifyAccountScreen({super.key, required this.email, this.role = 'FREELANCER'});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  final _svc = AuthService();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length < 4) return;
    setState(() => _loading = true);
    try {
      await _svc.verifyAccount(widget.email, _codeCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte vérifié ! Connectez-vous.'),
          backgroundColor: AppColors.brand500,
        ),
      );
      context.go(widget.role == 'CLIENT' ? '/login/client' : '/login/freelancer');
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code invalide. Réessayez.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resend() async {
    try {
      await _svc.resendCode(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code renvoyé !')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(color: AppColors.brand100, shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.brand500, size: 28),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vérifiez votre email',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Un code a été envoyé à '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8,
                ),
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Code de vérification',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              BrandButton(label: 'Vérifier', loading: _loading, onTap: _verify),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resend,
                  child: const Text(
                    'Renvoyer le code',
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
