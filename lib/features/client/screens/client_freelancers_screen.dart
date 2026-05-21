import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/freelancer_model.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ClientFreelancersScreen extends StatefulWidget {
  const ClientFreelancersScreen({super.key});

  @override
  State<ClientFreelancersScreen> createState() => _ClientFreelancersScreenState();
}

class _ClientFreelancersScreenState extends State<ClientFreelancersScreen> {
  final _svc = UserService();
  final _searchCtrl = TextEditingController();
  List<FreelancerModel> _freelancers = [];
  bool _loading = true;
  String _selectedLevel = 'Tous';

  static const _levels = ['Tous', 'Junior', 'Intermédiaire', 'Senior', 'Expert'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final results = await _svc.getFreelancers(search: search);
      if (mounted) setState(() { _freelancers = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<FreelancerModel> get _filtered {
    if (_selectedLevel == 'Tous') return _freelancers;
    return _freelancers.where((f) => f.levelLabel == _selectedLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher un freelancer...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.inkMuted),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _load();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (v) => _load(search: v.isEmpty ? null : v),
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _levels.map((level) {
                    final selected = _selectedLevel == level;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(level),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedLevel = level),
                        selectedColor: AppColors.brand500,
                        backgroundColor: AppColors.cream,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: BorderSide(color: selected ? AppColors.brand500 : AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const SingleChildScrollView(child: SkeletonList())
              : _filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'Aucun freelancer trouvé',
                      subtitle: 'Essayez d\'autres critères\nde recherche.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.brand500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _FreelancerCard(
                          freelancer: _filtered[i],
                          onTap: () => context.push(
                            '/client/freelancer/${_filtered[i].id}',
                            extra: _filtered[i],
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _FreelancerCard extends StatelessWidget {
  final FreelancerModel freelancer;
  final VoidCallback? onTap;
  const _FreelancerCard({required this.freelancer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                freelancer.initials,
                style: const TextStyle(
                  color: AppColors.brand700,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        freelancer.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (freelancer.available)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Disponible',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (freelancer.title != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    freelancer.title!,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (freelancer.averageRating != null)
                      _InfoBadge(icon: Icons.star_outline, label: freelancer.averageRating!.toStringAsFixed(1)),
                    if (freelancer.completedMissions != null)
                      _InfoBadge(icon: Icons.check_circle_outline, label: '${freelancer.completedMissions} missions'),
                    if (freelancer.levelLabel.isNotEmpty)
                      _InfoBadge(icon: Icons.bar_chart_outlined, label: freelancer.levelLabel),
                    if (freelancer.hourlyRate != null)
                      _InfoBadge(icon: Icons.payments_outlined, label: '${freelancer.hourlyRate!.toInt()} DH/h'),
                  ],
                ),
                if (freelancer.skills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: freelancer.skills.take(4).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sidebarActive,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.inkMuted),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      ],
    );
  }
}
