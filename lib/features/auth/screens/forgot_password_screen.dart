import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/brand_button.dart';

enum _Step { email, code, password, success }

class ForgotPasswordScreen extends StatefulWidget {
  final String role;
  const ForgotPasswordScreen({super.key, this.role = 'FREELANCER'});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _svc         = AuthService();
  _Step  _step       = _Step.email;
  bool   _loading    = false;
  String? _error;

  final _emailCtrl   = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool   _obscure    = true;
  bool   _obscureC   = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _loginRoute =>
      widget.role == 'CLIENT' ? '/login/client' : '/login/freelancer';

  // ── Étape 1 : envoyer le code ──────────────────────────────────────────────
  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Entrez une adresse email valide');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _svc.forgotPassword(email);
      if (mounted) setState(() { _step = _Step.code; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Impossible d\'envoyer le code. Vérifiez l\'email.';
      });
    }
  }

  // ── Étape 2 : vérifier le code ─────────────────────────────────────────────
  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Entrez le code reçu par email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _svc.verifyResetCode(_emailCtrl.text.trim(), code);
      if (mounted) setState(() { _step = _Step.password; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Code invalide ou expiré. Vérifiez et réessayez.';
      });
    }
  }

  // ── Étape 3 : nouveau mot de passe ─────────────────────────────────────────
  Future<void> _resetPassword() async {
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pass.length < 8) {
      setState(() => _error = 'Le mot de passe doit avoir au moins 8 caractères');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Le token = le code de réinitialisation (même valeur)
      await _svc.resetPassword(_codeCtrl.text.trim(), pass);
      if (mounted) setState(() { _step = _Step.success; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Erreur lors de la réinitialisation. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: _step != _Step.success
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_step == _Step.email) {
                    context.pop();
                  } else {
                    setState(() {
                      _error = null;
                      _step = _Step.values[_step.index - 1];
                    });
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.email:    return _buildEmail();
      case _Step.code:     return _buildCode();
      case _Step.password: return _buildPassword();
      case _Step.success:  return _buildSuccess();
    }
  }

  // ── STEP 1 ─────────────────────────────────────────────────────────────────
  Widget _buildEmail() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 1, total: 3),
        const SizedBox(height: 24),
        const Text(
          'Mot de passe oublié',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        const Text(
          'Entrez votre email pour recevoir un code de réinitialisation.',
          style: TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        if (_error != null) _ErrorBox(message: _error!),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Adresse email',
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.inkSoft),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 24),
        BrandButton(label: 'Envoyer le code', loading: _loading, onTap: _sendCode),
      ],
    );
  }

  // ── STEP 2 ─────────────────────────────────────────────────────────────────
  Widget _buildCode() {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 2, total: 3),
        const SizedBox(height: 24),
        const Text(
          'Vérification',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'Un code a été envoyé à '),
              TextSpan(
                text: _emailCtrl.text,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (_error != null) _ErrorBox(message: _error!),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '——————',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          onSubmitted: (_) => _verifyCode(),
        ),
        const SizedBox(height: 24),
        BrandButton(label: 'Vérifier le code', loading: _loading, onTap: _verifyCode),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _loading ? null : () {
              _codeCtrl.clear();
              setState(() { _step = _Step.email; _error = null; });
            },
            child: const Text(
              'Renvoyer le code',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 3 ─────────────────────────────────────────────────────────────────
  Widget _buildPassword() {
    return Column(
      key: const ValueKey('password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 3, total: 3),
        const SizedBox(height: 24),
        const Text(
          'Nouveau mot de passe',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choisissez un mot de passe sécurisé d\'au moins 8 caractères.',
          style: TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        if (_error != null) _ErrorBox(message: _error!),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nouveau mot de passe',
            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.inkSoft),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.inkSoft,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureC,
          decoration: InputDecoration(
            labelText: 'Confirmer le mot de passe',
            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.inkSoft),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureC ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.inkSoft,
              ),
              onPressed: () => setState(() => _obscureC = !_obscureC),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          onSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 24),
        BrandButton(
          label: 'Réinitialiser le mot de passe',
          loading: _loading,
          onTap: _resetPassword,
        ),
      ],
    );
  }

  // ── SUCCESS ────────────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        key: const ValueKey('success'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 28),
          const Text(
            'Mot de passe modifié !',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vous pouvez maintenant vous connecter\navec votre nouveau mot de passe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 36),
          BrandButton(
            label: 'Se connecter',
            onTap: () => context.go(_loginRoute),
          ),
        ],
      ),
    );
  }
}

// ── Widgets helpers ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppColors.ink : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
