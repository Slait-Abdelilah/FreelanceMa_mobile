import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/services/job_service.dart';
import '../../../shared/widgets/brand_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ClientOffersScreen extends StatefulWidget {
  const ClientOffersScreen({super.key});

  @override
  State<ClientOffersScreen> createState() => _ClientOffersScreenState();
}

class _ClientOffersScreenState extends State<ClientOffersScreen> {
  final _svc = JobService();
  List<OfferModel> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final offers = await _svc.getMyOffers();
      if (mounted) setState(() { _offers = offers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OfferFormSheet(service: _svc, onDone: _load),
    );
  }

  void _showEditSheet(OfferModel offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OfferFormSheet(service: _svc, existing: offer, onDone: _load),
    );
  }

  Future<void> _closeOffer(OfferModel offer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Fermer l\'offre'),
        content: Text('Fermer "${offer.title}" ? Aucune nouvelle candidature ne sera acceptée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Fermer', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.closeOffer(offer.id);
        _load();
      } catch (_) {}
    }
  }

  Future<void> _deleteOffer(OfferModel offer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'offre'),
        content: Text('Supprimer définitivement "${offer.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.deleteOffer(offer.id);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offre supprimée'), backgroundColor: AppColors.ink),
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: BrandButton(
            label: 'Publier une nouvelle offre',
            icon: Icons.add,
            onTap: _showCreateSheet,
          ),
        ),
        Expanded(
          child: _loading
              ? const SingleChildScrollView(child: SkeletonList())
              : _offers.isEmpty
                  ? EmptyState(
                      icon: Icons.work_outline,
                      title: 'Aucune offre publiée',
                      subtitle: 'Publiez votre première offre\npour trouver des talents.',
                      actionLabel: 'Publier une offre',
                      onAction: _showCreateSheet,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.brand500,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _offers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _OfferCard(
                          offer: _offers[i],
                          onEdit: () => _showEditSheet(_offers[i]),
                          onClose: _offers[i].status == 'OPEN' ? () => _closeOffer(_offers[i]) : null,
                          onDelete: () => _deleteOffer(_offers[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onEdit;
  final VoidCallback? onClose;
  final VoidCallback onDelete;

  const _OfferCard({
    required this.offer,
    required this.onEdit,
    this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = offer.status == 'OPEN';
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.categoryLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.brand100 : AppColors.sidebarActive,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isOpen ? 'Ouverte' : 'Fermée',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isOpen ? AppColors.brand700 : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            offer.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.4),
          ),
          if (offer.requiredSkills != null && offer.requiredSkills!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: offer.requiredSkills!.take(3).map((s) => Container(
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brand100,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    offer.budgetDisplay,
                    style: const TextStyle(color: AppColors.brand700, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (offer.applicationsCount != null) ...[
                const SizedBox(width: 10),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 13, color: AppColors.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.applicationsCount}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ],
              if (offer.deadline != null) ...[
                const SizedBox(width: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 13, color: AppColors.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM', 'fr').format(offer.deadline!),
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.inkSoft),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              if (onClose != null) ...[
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.lock_outline, size: 18, color: AppColors.warning),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferFormSheet extends StatefulWidget {
  final JobService service;
  final OfferModel? existing;
  final VoidCallback onDone;

  const _OfferFormSheet({required this.service, this.existing, required this.onDone});

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _deadlineCtrl;
  String _category = 'WEB_DEVELOPMENT';
  String _budgetType = 'FIXED';
  bool _loading = false;

  static const _categories = [
    ('WEB_DEVELOPMENT',    'Développement web'),
    ('MOBILE_DEVELOPMENT', 'Développement mobile'),
    ('DESIGN',             'Design'),
    ('MARKETING',          'Marketing'),
    ('WRITING',            'Rédaction'),
    ('VIDEO',              'Vidéo'),
    ('TRANSLATION',        'Traduction'),
    ('DATA_SCIENCE',       'Data Science'),
    ('OTHER',              'Autre'),
  ];

  static const _budgetTypes = [
    ('FIXED', 'Forfait'),
    ('HOURLY', 'Taux horaire'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _minCtrl = TextEditingController(text: e?.budgetMin != null && e!.budgetMin > 0 ? e.budgetMin.toInt().toString() : '');
    _maxCtrl = TextEditingController(text: e?.budgetMax != null && e!.budgetMax > 0 ? e.budgetMax.toInt().toString() : '');
    _skillsCtrl = TextEditingController(text: e?.requiredSkills?.join(', ') ?? '');
    _deadlineCtrl = TextEditingController(
      text: e?.deadline != null ? DateFormat('yyyy-MM-dd').format(e!.deadline!) : '',
    );
    if (e != null) {
      _category = e.category;
      _budgetType = e.budgetType;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _skillsCtrl.dispose();
    _deadlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand500),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _deadlineCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    final skills = _skillsCtrl.text.trim().isEmpty
        ? null
        : _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      'budgetType': _budgetType,
      if (_minCtrl.text.isNotEmpty) 'budgetMin': double.tryParse(_minCtrl.text) ?? 0,
      if (_maxCtrl.text.isNotEmpty) 'budgetMax': double.tryParse(_maxCtrl.text) ?? 0,
      if (skills != null) 'requiredSkills': skills.join(', '),
      if (_deadlineCtrl.text.isNotEmpty) 'deadline': _deadlineCtrl.text,
    };

    try {
      if (widget.existing != null) {
        await widget.service.updateOffer(widget.existing!.id, data);
      } else {
        await widget.service.createOffer(data);
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        widget.onDone();
        messenger.showSnackBar(
          SnackBar(
            content: Text(widget.existing != null ? 'Offre modifiée !' : 'Offre publiée !'),
            backgroundColor: AppColors.brand500,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing != null ? 'Modifier l\'offre' : 'Publier une offre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre du projet *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: _categories.map((c) => DropdownMenuItem(
                value: c.$1,
                child: Text(c.$2),
              )).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _budgetType,
              decoration: const InputDecoration(labelText: 'Type de budget'),
              items: _budgetTypes.map((t) => DropdownMenuItem(
                value: t.$1,
                child: Text(t.$2),
              )).toList(),
              onChanged: (v) => setState(() => _budgetType = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Budget min (DH)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Budget max (DH)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillsCtrl,
              decoration: const InputDecoration(
                labelText: 'Compétences requises',
                hintText: 'Ex: Flutter, Dart, Firebase',
                helperText: 'Séparez par des virgules',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deadlineCtrl,
              readOnly: true,
              onTap: _pickDeadline,
              decoration: const InputDecoration(
                labelText: 'Date limite',
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                hintText: 'Sélectionner une date',
              ),
            ),
            const SizedBox(height: 24),
            BrandButton(
              label: widget.existing != null ? 'Modifier' : 'Publier',
              loading: _loading,
              onTap: _submit,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
