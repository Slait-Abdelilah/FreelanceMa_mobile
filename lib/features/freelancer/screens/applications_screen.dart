import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/job_service.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = JobService();
  List<ApplicationModel> _apps = [];
  bool _loading = true;
  bool _error = false;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(_onTabChange);
    _load();
  }

  void _onTabChange() {
    if (_tab.indexIsChanging) return;
    _load(silent: true);
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChange);
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = false; });
    try {
      final apps = await _svc.getMyApplications();
      if (mounted) setState(() { _apps = apps; _loading = false; _error = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = !silent; });
    }
  }

  Future<void> _withdraw(ApplicationModel app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Retirer la candidature'),
        content: const Text('Voulez-vous vraiment retirer cette candidature ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Retirer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.withdrawApplication(app.id);
        await _load(silent: true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidature retirée'), backgroundColor: AppColors.ink),
        );
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du retrait'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _complete(ApplicationModel app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Marquer comme terminée'),
        content: const Text('Confirmez-vous la fin de cette mission ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Confirmer', style: TextStyle(color: AppColors.brand500)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.completeApplication(app.id);
        await _load(silent: true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission envoyée en validation'), backgroundColor: AppColors.ink),
        );
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<ApplicationModel> get _pending  => _apps.where((a) => a.isPending).toList();
  List<ApplicationModel> get _active   => _apps.where((a) => a.isAccepted || a.isCompleted || a.isAwaitingValidation).toList();
  List<ApplicationModel> get _archived => _apps.where((a) => a.isRejected || a.isWithdrawn).toList();

  String _tabLabel(String base, int count) =>
      _loading ? base : (count > 0 ? '$base ($count)' : base);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.inkMuted,
            indicatorColor: AppColors.ink,
            indicatorWeight: 2,
            dividerColor: AppColors.border,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            tabs: [
              Tab(text: _tabLabel('En attente', _pending.length)),
              Tab(text: _tabLabel('Missions',   _active.length)),
              Tab(text: _tabLabel('Archivées',  _archived.length)),
            ],
          ),
        ),

        // ── Contenu ──────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const SingleChildScrollView(child: SkeletonList())
              : _error
                  ? _ErrorRetry(onRetry: _load)
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _TabContent(
                          apps: _pending,
                          onRefresh: () => _load(silent: true),
                          emptyIcon: Icons.hourglass_empty_outlined,
                          emptyTitle: 'Aucune candidature en attente',
                          emptySubtitle: 'Explorez les offres disponibles pour postuler.',
                          onWithdraw: _withdraw,
                        ),
                        _TabContent(
                          apps: _active,
                          onRefresh: () => _load(silent: true),
                          emptyIcon: Icons.work_outline,
                          emptyTitle: 'Aucune mission active',
                          emptySubtitle: 'Dès qu\'un client accepte votre candidature,\nla mission apparaît ici.',
                          onComplete: _complete,
                        ),
                        _TabContent(
                          apps: _archived,
                          onRefresh: () => _load(silent: true),
                          emptyIcon: Icons.inbox_outlined,
                          emptyTitle: 'Aucune candidature archivée',
                          emptySubtitle: 'Les candidatures retirées ou refusées\napparaissent ici.',
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ── Error / retry ─────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 28, color: AppColors.inkMuted),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les candidatures',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Réessayer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brand500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab content ──────────────────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final List<ApplicationModel> apps;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(ApplicationModel)? onWithdraw;
  final void Function(ApplicationModel)? onComplete;

  const _TabContent({
    required this.apps,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onWithdraw,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return LayoutBuilder(
        builder: (_, constraints) => RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.brand500,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(emptyIcon, size: 22, color: AppColors.inkMuted),
                      const SizedBox(height: 14),
                      Text(
                        emptyTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptySubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.brand500,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: apps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _AppCard(
          app: apps[i],
          onWithdraw: onWithdraw != null && apps[i].isPending  ? () => onWithdraw!(apps[i]) : null,
          onComplete: onComplete != null && apps[i].isAccepted ? () => onComplete!(apps[i]) : null,
        ),
      ),
    );
  }
}

// ── Application card ──────────────────────────────────────────────────────────

class _AppCard extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback? onWithdraw;
  final VoidCallback? onComplete;

  const _AppCard({required this.app, this.onWithdraw, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final hasActions = onWithdraw != null || onComplete != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Ligne 1 — titre + budget
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  app.offerTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_budget != null) ...[
                const SizedBox(width: 14),
                Text(
                  _budget!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: app.proposedBudget != null ? AppColors.brand500 : AppColors.inkSoft,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Ligne 2 — méta + statut
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _meta,
                style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
              ),
              const Spacer(),
              _StatusBadge(status: app.status),
            ],
          ),

          // Ligne 3 — actions (si applicable)
          if (hasActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onWithdraw != null)
                  GestureDetector(
                    onTap: onWithdraw,
                    child: const Text(
                      'Retirer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                if (onComplete != null) ...[
                  if (onWithdraw != null) const SizedBox(width: 20),
                  GestureDetector(
                    onTap: onComplete,
                    child: const Text(
                      'Marquer terminée',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? get _budget {
    if (app.proposedBudget != null) {
      return '${app.proposedBudget!.toStringAsFixed(0)} DH';
    }
    if (app.offerBudgetMin != null) {
      final max = app.offerBudgetMax?.toStringAsFixed(0) ?? '?';
      return '${app.offerBudgetMin!.toStringAsFixed(0)}–$max DH';
    }
    return null;
  }

  String get _meta {
    final parts = <String>[];
    if (app.offerCategory != null) parts.add(app.categoryLabel);
    parts.add(DateFormat('d MMM yyyy', 'fr').format(app.appliedAt));
    return parts.join(' · ');
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  (String, Color) _resolve(String s) => switch (s) {
    'ACCEPTED'            => ('Acceptée',      AppColors.brand500),
    'COMPLETED'           => ('Terminée',      AppColors.inkSoft),
    'REJECTED'            => ('Refusée',       AppColors.error),
    'WITHDRAWN'           => ('Retirée',       AppColors.inkMuted),
    'AWAITING_VALIDATION' => ('En validation', AppColors.warning),
    _                     => ('En attente',    AppColors.warning),
  };
}
