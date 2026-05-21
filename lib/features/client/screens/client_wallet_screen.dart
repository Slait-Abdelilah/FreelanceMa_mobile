import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/brand_button.dart';

class ClientWalletScreen extends StatefulWidget {
  const ClientWalletScreen({super.key});

  @override
  State<ClientWalletScreen> createState() => _ClientWalletScreenState();
}

class _ClientWalletScreenState extends State<ClientWalletScreen> {
  final _svc = UserService();
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showDepositSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DepositSheet(service: _svc, onDone: _load),
    );
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
    final balance = (_wallet?['balance'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brand500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  Text('${balance.toStringAsFixed(2)} DH',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BrandButton(
              label: 'Alimenter le wallet',
              icon: Icons.add,
              onTap: _showDepositSheet,
            ),
            const SizedBox(height: 24),
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

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TransactionTile({required this.data});

  static const _creditTypes = {'DEPOSIT', 'ESCROW_REFUND'};
  static const _debitTypes  = {'ESCROW_HOLD'};

  @override
  Widget build(BuildContext context) {
    final type     = data['type'] as String? ?? '';
    final isCredit = _creditTypes.contains(type);
    final isDebit  = _debitTypes.contains(type);
    final amount   = (data['amount'] as num?)?.toDouble() ?? 0;

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
    'DEPOSIT'      => 'Dépôt',
    'ESCROW_HOLD'  => 'Fonds bloqués (mission)',
    'ESCROW_REFUND'=> 'Remboursement',
    _              => type,
  };

  String _statusLabel(String status) => switch (status) {
    'COMPLETED' => 'Complété',
    'PENDING'   => 'En attente',
    'FAILED'    => 'Échoué',
    _           => status,
  };
}

class _DepositSheet extends StatefulWidget {
  final UserService service;
  final VoidCallback onDone;

  const _DepositSheet({required this.service, required this.onDone});

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _amountCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  static const _quickAmounts = [100, 200, 500, 1000];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Entrez un montant valide');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.service.deposit(amount);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        widget.onDone();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Wallet alimenté avec succès !'),
            backgroundColor: AppColors.brand500,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erreur lors du dépôt. Veuillez réessayer.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20, right: 20, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Alimenter le wallet',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Montant (DH)',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: AppColors.cream,
            ),
          ),
          const SizedBox(height: 12),
          // Montants rapides
          Row(
            children: _quickAmounts.map((amt) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () => setState(() => _amountCtrl.text = '$amt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand500,
                    side: const BorderSide(color: AppColors.brand500),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('$amt DH'),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          BrandButton(label: 'Confirmer le dépôt', loading: _loading, onTap: _submit),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
