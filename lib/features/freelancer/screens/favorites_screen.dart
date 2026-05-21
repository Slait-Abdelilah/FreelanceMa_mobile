import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/favorite_model.dart';
import '../../../data/services/job_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _svc = JobService();
  List<FavoriteModel> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final favs = await _svc.getMyFavorites();
      if (mounted) setState(() { _favorites = favs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(FavoriteModel fav) async {
    try {
      await _svc.toggleFavorite(fav.offerId);
      setState(() => _favorites.removeWhere((f) => f.favoriteId == fav.favoriteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre retirée des favoris'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SingleChildScrollView(child: SkeletonList());
    }
    if (_favorites.isEmpty) {
      return const EmptyState(
        icon: Icons.bookmark_outline,
        title: 'Aucun favori',
        subtitle: 'Sauvegardez des offres intéressantes\npour les retrouver ici.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brand500,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _FavoriteCard(
          fav: _favorites[i],
          onRemove: () => _remove(_favorites[i]),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final FavoriteModel fav;
  final VoidCallback onRemove;

  const _FavoriteCard({required this.fav, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fav.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fav.categoryLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark, size: 18, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fav.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  fav.budgetDisplay,
                  style: const TextStyle(
                    color: AppColors.brand700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: fav.status, small: true),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 13, color: AppColors.inkMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${fav.applicationsCount}',
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
