import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/brand_button.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  bool get isFreelancer => widget.role == 'FREELANCER';
  String get registerRoute => isFreelancer ? '/register/freelancer' : '/register/client';
  String get dashboardRoute => isFreelancer ? '/freelancer/dashboard' : '/client/dashboard';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go(dashboardRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erreur de connexion'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: 32),

                const AppLogo(),
                const SizedBox(height: 24),

                Text(
                  isFreelancer ? 'Connexion Freelancer' : 'Connexion Client',
                  style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFreelancer
                      ? 'Accédez à vos missions et candidatures'
                      : 'Gérez vos projets et freelancers',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.inkSoft),
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Email invalide' : null,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.inkSoft),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.inkSoft,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Minimum 6 caractères' : null,
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password?role=${widget.role}'),
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                BrandButton(
                  label: 'Se connecter',
                  loading: auth.status == AuthStatus.loading,
                  onTap: _submit,
                ),
                const SizedBox(height: 16),

                // Séparateur
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                BrandButton(
                  label: "Créer un compte",
                  outline: true,
                  onTap: () => context.go(registerRoute),
                ),
                const SizedBox(height: 24),

                // Switch rôle
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(
                      isFreelancer ? '/login/client' : '/login/freelancer',
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                        children: [
                          TextSpan(
                            text: isFreelancer ? 'Vous êtes client ? ' : 'Vous êtes freelancer ? ',
                          ),
                          TextSpan(
                            text: isFreelancer ? 'Connexion client' : 'Connexion freelancer',
                            style: const TextStyle(
                              color: AppColors.ink, fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
