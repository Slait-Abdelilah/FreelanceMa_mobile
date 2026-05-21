import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/job_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ClientApplicationsScreen extends StatefulWidget {
  const ClientApplicationsScreen({super.key});

  @override
  State<ClientApplicationsScreen> createState() => _ClientApplicationsScreenState();
}

class _ClientApplicationsScreenState extends State<ClientApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = JobService();
  List<ApplicationModel> _apps = [];
  bool _loading = true;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
      final all = nested.expand((list) => list).toList();
      if (mounted) setState(() { _apps = all; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(ApplicationModel app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accepter la candidature'),
        content: Text('Accepter la candidature de ${app.freelancerName ?? 'ce freelancer'} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Accepter', style: TextStyle(color: AppColors.brand500)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.acceptApplication(app.id);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidature acceptée'), backgroundColor: AppColors.brand500),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _reject(ApplicationModel app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Refuser la candidature'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Refuser', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.rejectApplication(app.id);
        _load();
      } catch (_) {}
    }
  }

  List<ApplicationModel> get _pending => _apps.where((a) => a.isPending).toList();
  List<ApplicationModel> get _accepted => _apps.where((a) => a.isAccepted || a.isAwaitingValidation || a.isCompleted).toList();
  List<ApplicationModel> get _rejected => _apps.where((a) => a.isRejected || a.isWithdrawn).toList();

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
              Tab(text: 'En attente (${_loading ? '…' : _pending.length})'),
              Tab(text: 'Acceptées (${_loading ? '…' : _accepted.length})'),
              Tab(text: 'Refusées (${_loading ? '…' : _rejected.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _AppList(
                apps: _loading ? [] : _pending,
                loading: _loading,
                emptyTitle: 'Aucune candidature en attente',
                emptySubtitle: 'Les nouvelles candidatures\napparaîtront ici.',
                onAccept: _accept,
                onReject: _reject,
              ),
              _AppList(
                apps: _loading ? [] : _accepted,
                loading: _loading,
                emptyTitle: 'Aucune candidature acceptée',
                emptySubtitle: 'Les candidatures que vous\nacceptez apparaîtront ici.',
              ),
              _AppList(
                apps: _loading ? [] : _rejected,
                loading: _loading,
                emptyTitle: 'Aucune candidature refusée',
                emptySubtitle: '',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppList extends StatelessWidget {
  final List<ApplicationModel> apps;
  final bool loading;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(ApplicationModel)? onAccept;
  final void Function(ApplicationModel)? onReject;

  const _AppList({
    required this.apps,
    required this.loading,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const SingleChildScrollView(child: SkeletonList());
    if (apps.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _AppCard(
        app: apps[i],
        onAccept: onAccept != null ? () => onAccept!(apps[i]) : null,
        onReject: onReject != null ? () => onReject!(apps[i]) : null,
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _AppCard({required this.app, this.onAccept, this.onReject});

  Color get _statusColor {
    if (app.isAccepted || app.isCompleted) return AppColors.brand500;
    if (app.isAwaitingValidation) return AppColors.warning;
    if (app.isRejected || app.isWithdrawn) return AppColors.error;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (app.isAccepted) return 'Acceptée';
    if (app.isAwaitingValidation) return 'En validation';
    if (app.isCompleted) return 'Terminée';
    if (app.isRejected) return 'Refusée';
    if (app.isWithdrawn) return 'Retirée';
    return 'En attente';
  }

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    app.freelancerInitials,
                    style: const TextStyle(
                      color: AppColors.brand700,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.freelancerName ?? 'Freelancer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      app.offerTitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (app.coverLetter != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              app.coverLetter!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (app.proposedBudget != null) ...[
                const Icon(Icons.payments_outlined, size: 13, color: AppColors.inkMuted),
                const SizedBox(width: 4),
                Text(
                  '${app.proposedBudget!.toInt()} DH',
                  style: const TextStyle(fontSize: 12, color: AppColors.brand500, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
              ],
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.inkMuted),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy', 'fr').format(app.appliedAt),
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const Spacer(),
              if (onReject != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onReject,
                  child: const Text('Refuser'),
                ),
              if (onAccept != null) ...[
                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onAccept,
                  child: const Text('Accepter'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
