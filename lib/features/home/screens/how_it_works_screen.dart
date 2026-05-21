import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const AppLogo(showText: false)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment ça marche ?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink)),
            SizedBox(height: 8),
            Text('Un processus simple et transparent pour trouver le bon freelancer ou le bon projet.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
            SizedBox(height: 32),
            _StepTile(num: '01', title: 'Créez votre compte',
              desc: 'Inscription gratuite en 2 minutes. Complétez votre profil.'),
            _StepTile(num: '02', title: 'Publiez ou candidatez',
              desc: 'Clients publient leur projet. Freelancers envoient leurs propositions.'),
            _StepTile(num: '03', title: 'Collaborez en confiance',
              desc: 'Messagerie intégrée, partage de fichiers, suivi des jalons.'),
            _StepTile(num: '04', title: 'Paiement sécurisé',
              desc: 'Système escrow : fonds bloqués et libérés après validation.'),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String num, title, desc;
  const _StepTile({required this.num, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.brand500,
          )),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
