import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/freelancer_model.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/services/user_service.dart';

class FreelancerPublicProfileScreen extends StatefulWidget {
  final FreelancerModel freelancer;
  const FreelancerPublicProfileScreen({super.key, required this.freelancer});

  @override
  State<FreelancerPublicProfileScreen> createState() => _FreelancerPublicProfileScreenState();
}

class _FreelancerPublicProfileScreenState extends State<FreelancerPublicProfileScreen> {
  final _svc = UserService();
  List<PortfolioModel> _portfolio = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    try {
      final items = await _svc.getPublicPortfolio(widget.freelancer.id);
      if (mounted) setState(() { _portfolio = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.freelancer;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(f.displayName),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.brand100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.brand500.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            f.initials,
                            style: const TextStyle(
                              color: AppColors.brand700,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            if (f.title != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                f.title!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            if (f.available)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Text(
                                  'Disponible',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (f.levelLabel.isNotEmpty)
                        _InfoRow(Icons.bar_chart_outlined, f.levelLabel),
                      if (f.hourlyRate != null)
                        _InfoRow(Icons.payments_outlined, '${f.hourlyRate!.toInt()} DH/h'),
                      if (f.location != null)
                        _InfoRow(Icons.location_on_outlined, f.location!),
                      if (f.averageRating != null)
                        _InfoRow(Icons.star_outline, f.averageRating!.toStringAsFixed(1)),
                      if (f.completedMissions != null)
                        _InfoRow(Icons.check_circle_outline, '${f.completedMissions} missions'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Compétences ──────────────────────────────────────────────
            if (f.skills.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Compétences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: f.skills.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                )).toList(),
              ),
            ],

            // ── Portfolio ────────────────────────────────────────────────
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Portfolio',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                if (!_loading)
                  Text(
                    '(${_portfolio.length})',
                    style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.brand500, strokeWidth: 2),
                ),
              )
            else if (_portfolio.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 28, color: AppColors.inkMuted),
                    SizedBox(height: 10),
                    Text(
                      'Aucun projet dans le portfolio',
                      style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              )
            else
              ...(_portfolio.map((p) => _PortfolioCard(project: p))),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.inkMuted),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
    ],
  );
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioModel project;
  const _PortfolioCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline, size: 18, color: AppColors.brand500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (project.projectUrl != null && project.projectUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.link, size: 13, color: AppColors.brand500),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    project.projectUrl!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brand500,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
