import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/job_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ClientMissionsScreen extends StatefulWidget {
  const ClientMissionsScreen({super.key});

  @override
  State<ClientMissionsScreen> createState() => _ClientMissionsScreenState();
}

class _ClientMissionsScreenState extends State<ClientMissionsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = JobService();
  List<ApplicationModel> _active = [];
  List<ApplicationModel> _completed = [];
  bool _loading = true;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final offers = await _svc.getMyOffers();
      final nested = await Future.wait(
        offers.map((o) => _svc.getOfferApplications(o.id)),
      );
      final all = nested.expand((l) => l).toList();
      if (mounted) {
        setState(() {
          _active = all.where((a) => a.isAccepted || a.isAwaitingValidation).toList();
          _completed = all.where((a) => a.isCompleted).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _validate(ApplicationModel app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Valider la mission'),
        content: const Text('Confirmez-vous la validation et le paiement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Valider', style: TextStyle(color: AppColors.brand500)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.validateMission(app.id);
        _load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.inkMuted,
            indicatorColor: AppColors.brand500,
            tabs: [
              Tab(text: 'En cours (${_loading ? '…' : _active.length})'),
              Tab(text: 'Terminées (${_loading ? '…' : _completed.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _MissionList(
                apps: _loading ? [] : _active,
                loading: _loading,
                emptyTitle: 'Aucune mission en cours',
                emptySubtitle: 'Acceptez des candidatures pour\ndémarrer des missions.',
                onValidate: _validate,
              ),
              _MissionList(
                apps: _loading ? [] : _completed,
                loading: _loading,
                emptyTitle: 'Aucune mission terminée',
                emptySubtitle: 'Les missions complétées\napparaîtront ici.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionList extends StatelessWidget {
  final List<ApplicationModel> apps;
  final bool loading;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(ApplicationModel)? onValidate;

  const _MissionList({
    required this.apps,
    required this.loading,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const SingleChildScrollView(child: SkeletonList());
    if (apps.isEmpty) {
      return EmptyState(
        icon: Icons.rocket_launch_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ClientMissionCard(
        app: apps[i],
        onValidate: (onValidate != null && apps[i].isAwaitingValidation)
            ? () => onValidate!(apps[i])
            : null,
      ),
    );
  }
}

class _ClientMissionCard extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback? onValidate;

  const _ClientMissionCard({required this.app, this.onValidate});

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
          Text(
            app.offerTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink),
          ),
          if (app.offerCategory != null) ...[
            const SizedBox(height: 2),
            Text(app.categoryLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              if (app.proposedBudget != null) ...[
                _Chip(Icons.payments_outlined, '${app.proposedBudget!.toInt()} DH'),
                const SizedBox(width: 10),
              ],
              _Chip(Icons.calendar_today_outlined,
                  DateFormat('dd MMM', 'fr').format(app.appliedAt)),
              const Spacer(),
              if (onValidate != null)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onValidate,
                  child: const Text('Valider & payer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.inkMuted),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
    ],
  );
}
