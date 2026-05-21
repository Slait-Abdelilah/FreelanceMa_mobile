import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _cats = [
    ('💻', 'Développement', '2,340 freelancers', 'dès 150 DH/h'),
    ('🎨', 'Design & UI/UX', '1,890 freelancers', 'dès 120 DH/h'),
    ('✍️', 'Rédaction', '1,420 freelancers', 'dès 80 DH/h'),
    ('📱', 'Marketing', '980 freelancers', 'dès 100 DH/h'),
    ('🎬', 'Vidéo & Animation', '650 freelancers', 'dès 200 DH/h'),
    ('🎵', 'Audio & Musique', '430 freelancers', 'dès 90 DH/h'),
    ('📊', 'Business', '720 freelancers', 'dès 180 DH/h'),
    ('🌐', 'Traduction', '540 freelancers', 'dès 70 DH/h'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Catégories'),
        backgroundColor: AppColors.cream,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: _cats.map((c) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.$1, style: const TextStyle(fontSize: 32)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(c.$3, style: const TextStyle(color: AppColors.inkSoft, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(c.$4, style: const TextStyle(
                    color: AppColors.brand500, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
