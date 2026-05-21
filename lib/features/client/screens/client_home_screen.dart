import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/job_service.dart';
import '../../../data/services/user_service.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/offer_model.dart';
import '../../../shared/widgets/brand_button.dart';
import '../../../shared/widgets/stat_card.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _jobSvc = JobService();
  final _userSvc = UserService();
  List<OfferModel> _myOffers = [];
  List<ApplicationModel> _allApps = [];
  Map<String, dynamic>? _wallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final offers = await _jobSvc.getMyOffers();
      final nestedApps = await Future.wait(
        offers.map((o) => _jobSvc.getOfferApplications(o.id)),
      );
      final wallet = await _userSvc.getWallet();
      if (mounted) {
        setState(() {
          _myOffers = offers;
          _allApps = nestedApps.expand((l) => l).toList();
          _wallet = wallet;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _pendingApps => _allApps.where((a) => a.isPending).length;
  int get _activeMissions => _allApps.where((a) => a.isAccepted || a.isAwaitingValidation).length;

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
            const Text('Tableau de bord Client', style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
            const SizedBox(height: 20),

            BrandButton(
              label: 'Publier une offre',
              icon: Icons.add,
              onTap: () => context.go('/client/offers'),
            ),
            const SizedBox(height: 20),

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
                    onTap: () => context.go('/client/offers'),
                    child: StatCard(
                      value: '${_myOffers.length}',
                      label: 'Offres publiées',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/client/applications'),
                    child: StatCard(
                      value: '$_pendingApps',
                      label: 'Candidatures',
                      valueColor: _pendingApps > 0 ? AppColors.warning : AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/client/missions'),
                    child: StatCard(
                      value: '$_activeMissions',
                      label: 'Missions actives',
                      valueColor: _activeMissions > 0 ? AppColors.brand500 : AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/client/wallet'),
                    child: StatCard(
                      value: '${(_wallet?['balance'] as num?)?.toStringAsFixed(0) ?? '0'} DH',
                      label: 'Solde Wallet',
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
                    'Mes offres récentes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => context.go('/client/offers'),
                    child: const Text('Gérer', style: TextStyle(color: AppColors.brand500, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_myOffers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.work_outline, size: 40, color: AppColors.border),
                      SizedBox(height: 8),
                      Text(
                        'Publiez votre première offre\npour trouver des talents.',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._myOffers.take(3).map((o) => _ClientOfferSummary(offer: o)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClientOfferSummary extends StatelessWidget {
  final OfferModel offer;
  const _ClientOfferSummary({required this.offer});

  @override
  Widget build(BuildContext context) {
    final isOpen = offer.status == 'OPEN';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.brand100 : AppColors.sidebarActive,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.work_outline,
              size: 20,
              color: isOpen ? AppColors.brand500 : AppColors.inkMuted,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.brand100 : AppColors.sidebarActive,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isOpen ? 'Ouverte' : 'Fermée',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isOpen ? AppColors.brand700 : AppColors.inkSoft,
                  ),
                ),
              ),
              if (offer.applicationsCount != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 11, color: AppColors.inkMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${offer.applicationsCount}',
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
