import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/user_service.dart';

class FreelancerWalletScreen extends StatefulWidget {
  const FreelancerWalletScreen({super.key});

  @override
  State<FreelancerWalletScreen> createState() => _FreelancerWalletScreenState();
}

class _FreelancerWalletScreenState extends State<FreelancerWalletScreen> {
  final _svc = UserService();
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_svc.getWallet(), _svc.getTransactions()]);
      if (mounted) {
        setState(() {
          _wallet = results[0] as Map<String, dynamic>;
          _transactions = results[1] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.brand500));

    final balance  = (_wallet?['balance']        as num?)?.toDouble() ?? 0;
    final pending  = (_wallet?['pendingBalance']  as num?)?.toDouble() ?? 0;
    final earned   = (_wallet?['totalEarned']     as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brand500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte solde
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solde disponible', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.toStringAsFixed(2)} DH',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _WalletChip(label: 'En attente', value: '${pending.toStringAsFixed(2)} DH'),
                        const SizedBox(width: 10),
                        _WalletChip(label: 'Total gagné', value: '${earned.toStringAsFixed(2)} DH'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text('Historique', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              if (_transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aucune transaction', style: TextStyle(color: AppColors.inkSoft)),
                  ),
                )
              else
                ..._transactions.map((t) => _TransactionTile(data: t)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label, value;
  const _WalletChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TransactionTile({required this.data});

  // Types créditeurs : argent qui entre dans le wallet du freelancer
  static const _creditTypes = {'DEPOSIT', 'ESCROW_RELEASE'};
  // Types débiteurs : argent qui sort
  static const _debitTypes  = {'WITHDRAWAL', 'ESCROW_HOLD', 'ESCROW_REFUND'};

  @override
  Widget build(BuildContext context) {
    final type   = data['type'] as String? ?? '';
    final isCredit = _creditTypes.contains(type);
    final isDebit  = _debitTypes.contains(type);
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;

    final Color iconBg    = isCredit ? AppColors.brand100 : isDebit ? const Color(0xFFFEE2E2) : AppColors.sidebarActive;
    final Color iconColor = isCredit ? AppColors.brand500 : isDebit ? AppColors.error : AppColors.inkMuted;
    final IconData icon   = isCredit ? Icons.arrow_downward : isDebit ? Icons.arrow_upward : Icons.swap_horiz;
    final String sign     = isCredit ? '+' : isDebit ? '-' : '';
    final Color amtColor  = isCredit ? AppColors.brand500 : isDebit ? AppColors.error : AppColors.inkSoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] as String? ?? _typeLabel(type),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data['status'] != null)
                  Text(
                    _statusLabel(data['status'] as String),
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${amount.abs().toStringAsFixed(2)} DH',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: amtColor),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
    'DEPOSIT'        => 'Dépôt',
    'WITHDRAWAL'     => 'Retrait',
    'ESCROW_HOLD'    => 'Fonds bloqués',
    'ESCROW_RELEASE' => 'Paiement reçu',
    'ESCROW_REFUND'  => 'Remboursement',
    _                => type,
  };

  String _statusLabel(String status) => switch (status) {
    'COMPLETED' => 'Complété',
    'PENDING'   => 'En attente',
    'FAILED'    => 'Échoué',
    _           => status,
  };
}

