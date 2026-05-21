import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/job_service.dart';
import '../../../data/services/user_service.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/offer_model.dart';
import '../../../shared/widgets/stat_card.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen> {
  final _jobSvc = JobService();
  final _userSvc = UserService();

  List<OfferModel> _recentOffers = [];
  List<ApplicationModel> _myApps = [];
  Map<String, dynamic>? _wallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    final results = await Future.wait([
      _jobSvc.getOffers(params: {'size': 3}).catchError((_) => <OfferModel>[]),
      _jobSvc.getMyApplications().catchError((_) => <ApplicationModel>[]),
      _userSvc.getWallet().catchError((_) => <String, dynamic>{}),
    ]);

    if (mounted) {
      setState(() {
        _recentOffers = results[0] as List<OfferModel>;
        _myApps       = results[1] as List<ApplicationModel>;
        final w       = results[2] as Map<String, dynamic>;
        _wallet       = w.isNotEmpty ? w : null;
        _loading      = false;
      });
    }
  }

  int get _pendingCount => _myApps.where((a) => a.isPending).length;
  int get _activeMissions => _myApps.where((a) => a.isAccepted).length;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brand500,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${user?.displayName.split(' ').first ?? ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            const Text('Voici votre tableau de bord', style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
            const SizedBox(height: 24),

            if (_loading)
              Column(
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/freelancer/wallet'),
                    child: StatCard(
                      value: _wallet == null ? '—' : '${(_wallet!['balance'] as num?)?.toStringAsFixed(0) ?? '0'} DH',
                      label: 'Solde Wallet',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/freelancer/applications'),
                    child: StatCard(
                      value: '$_activeMissions',
                      label: 'Missions actives',
                      valueColor: _activeMissions > 0 ? AppColors.brand500 : AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/freelancer/applications'),
                    child: StatCard(
                      value: '$_pendingCount',
                      label: 'En attente',
                      valueColor: _pendingCount > 0 ? AppColors.warning : AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/freelancer/explore'),
                    child: StatCard(
                      value: '${_recentOffers.length}+',
                      label: 'Offres dispo.',
                      valueColor: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Offres récentes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => context.go('/freelancer/explore'),
                    child: const Text('Voir tout', style: TextStyle(color: AppColors.brand500, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_recentOffers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Aucune offre disponible pour le moment.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._recentOffers.map((o) => _OfferPreviewCard(offer: o)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfferPreviewCard extends StatelessWidget {
  final OfferModel offer;
  const _OfferPreviewCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sidebarActive,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.work_outline, size: 20, color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  offer.categoryLabel,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  offer.budgetDisplay,
                  style: const TextStyle(
                    color: AppColors.brand700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => context.go('/freelancer/explore'),
                child: const Text(
                  'Postuler →',
                  style: TextStyle(
                    color: AppColors.brand500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
