import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _open;

  static const _faqs = [
    ('Comment fonctionne le paiement escrow ?',
     'Le client dépose les fonds à l\'acceptation. L\'argent est bloqué et libéré au freelancer uniquement après validation du livrable final.'),
    ('Quels sont les frais ?',
     'L\'inscription est gratuite. Nous prélevons 10% de commission sur chaque transaction réussie.'),
    ('Comment sont vérifiés les freelancers ?',
     'Chaque freelancer passe par une vérification manuelle d\'identité, compétences et portfolio.'),
    ('Puis-je annuler un projet ?',
     'Oui, les deux parties peuvent annuler. Si le projet est commencé, notre équipe support intervient.'),
    ('Les paiements sont-ils disponibles au Maroc ?',
     'Oui — virements bancaires, cartes marocaines et internationales, et paiements mobiles.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('FAQ'), backgroundColor: AppColors.cream),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        separatorBuilder: (context, i) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final open = _open == i;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    _faqs[i].$1,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: Icon(
                    open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.inkSoft,
                  ),
                  onTap: () => setState(() => _open = open ? null : i),
                ),
                if (open)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      _faqs[i].$2,
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.5),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
