import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/job_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

// Standalone page wrapper (used when navigating outside the shell)
class ActiveMissionsPage extends StatelessWidget {
  const ActiveMissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Missions actives'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: const ActiveMissionsScreen(),
    );
  }
}

class ActiveMissionsScreen extends StatefulWidget {
  const ActiveMissionsScreen({super.key});

  @override
  State<ActiveMissionsScreen> createState() => _ActiveMissionsScreenState();
}

class _ActiveMissionsScreenState extends State<ActiveMissionsScreen> {
  final _svc = JobService();
  List<ApplicationModel> _missions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _svc.getMyApplications();
      final active = all.where((a) => a.isAccepted || a.isCompleted).toList();
      if (mounted) setState(() { _missions = active; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markComplete(ApplicationModel app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Marquer comme terminée'),
        content: const Text('Confirmez-vous la fin de cette mission ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer', style: TextStyle(color: AppColors.brand500)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.completeApplication(app.id);
        _load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SingleChildScrollView(child: SkeletonList());
    if (_missions.isEmpty) {
      return const EmptyState(
        icon: Icons.rocket_launch_outlined,
        title: 'Aucune mission active',
        subtitle: 'Vos missions acceptées\napparaîtront ici.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brand500,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _missions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _MissionCard(
          app: _missions[i],
          onComplete: _missions[i].isAccepted ? () => _markComplete(_missions[i]) : null,
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback? onComplete;

  const _MissionCard({required this.app, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isCompleted = app.isCompleted;
    final accent = isCompleted ? AppColors.inkMuted : AppColors.brand500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? AppColors.border : AppColors.brand500.withValues(alpha: 0.3),
          width: isCompleted ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.work_outline,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.offerTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    if (app.offerCategory != null)
                      Text(
                        app.categoryLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isCompleted ? 'Terminée' : 'En cours',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              if (app.proposedBudget != null) ...[
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label: '${app.proposedBudget!.toInt()} DH',
                ),
                const SizedBox(width: 10),
              ],
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd MMM', 'fr').format(app.appliedAt),
              ),
              const Spacer(),
              if (onComplete != null)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onComplete,
                  child: const Text('Terminer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
      ],
    );
  }
}
