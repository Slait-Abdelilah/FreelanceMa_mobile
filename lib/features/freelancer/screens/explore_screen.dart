import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/services/job_service.dart';
import '../../../shared/widgets/brand_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _svc = JobService();
  final _searchCtrl = TextEditingController();
  List<OfferModel> _offers = [];
  bool _loading = true;
  String _selectedCategory = 'Toutes';
  String _sort = 'Récent';
  Set<int> _favorites = {};

  static const _categories = [
    'Toutes', 'Dev web', 'Dev mobile', 'Design', 'Marketing',
    'Rédaction', 'Vidéo', 'Traduction', 'Data Science', 'Autre',
  ];
  static const _categoryKeys = {
    'Toutes':       null,
    'Dev web':      'WEB_DEVELOPMENT',
    'Dev mobile':   'MOBILE_DEVELOPMENT',
    'Design':       'DESIGN',
    'Marketing':    'MARKETING',
    'Rédaction':    'WRITING',
    'Vidéo':        'VIDEO',
    'Traduction':   'TRANSLATION',
    'Data Science': 'DATA_SCIENCE',
    'Autre':        'OTHER',
  };
  static const _sorts = ['Récent', 'Budget croissant', 'Budget décroissant', 'Moins candidats'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final offers = await _svc.getOffers();
      if (mounted) setState(() { _offers = offers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(OfferModel offer) async {
    final isFav = _favorites.contains(offer.id);
    setState(() {
      if (isFav) {
        _favorites.remove(offer.id);
      } else {
        _favorites.add(offer.id);
      }
    });
    try {
      await _svc.toggleFavorite(offer.id);
    } catch (_) {
      setState(() {
        if (isFav) {
          _favorites.add(offer.id);
        } else {
          _favorites.remove(offer.id);
        }
      });
    }
  }

  List<OfferModel> get _filtered {
    var list = List<OfferModel>.from(_offers);

    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) =>
        o.title.toLowerCase().contains(q) ||
        o.description.toLowerCase().contains(q)
      ).toList();
    }

    final catKey = _categoryKeys[_selectedCategory];
    if (catKey != null) {
      list = list.where((o) => o.category == catKey).toList();
    }

    switch (_sort) {
      case 'Budget croissant':
        list.sort((a, b) => (a.budgetMin).compareTo(b.budgetMin));
      case 'Budget décroissant':
        list.sort((a, b) => (b.budgetMax).compareTo(a.budgetMax));
      case 'Moins candidats':
        list.sort((a, b) => (a.applicationsCount ?? 0).compareTo(b.applicationsCount ?? 0));
      default:
        list.sort((a, b) => b.id.compareTo(a.id));
    }

    return list;
  }

  void _showApplySheet(OfferModel offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ApplySheet(offer: offer, service: _svc),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Trier par', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ..._sorts.map((s) {
              final selected = _sort == s;
              return ListTile(
                title: Text(s, style: TextStyle(
                  fontSize: 14,
                  color: selected ? AppColors.brand500 : AppColors.ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
                leading: Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? AppColors.brand500 : AppColors.inkMuted,
                  size: 20,
                ),
                dense: true,
                onTap: () {
                  setState(() => _sort = s);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une mission...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.inkMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () { _searchCtrl.clear(); setState(() {}); },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.sidebarActive,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.sort, size: 20, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.brand500,
                        backgroundColor: AppColors.cream,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: selected ? AppColors.brand500 : AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        if (!_loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${filtered.length} offre${filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const SingleChildScrollView(child: SkeletonList())
              : filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'Aucune offre trouvée',
                      subtitle: 'Essayez d\'autres critères\nde recherche.',
                      actionLabel: 'Réinitialiser',
                      onAction: () {
                        _searchCtrl.clear();
                        setState(() { _selectedCategory = 'Toutes'; _sort = 'Récent'; });
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.brand500,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _OfferCard(
                          offer: filtered[i],
                          isFavorite: _favorites.contains(filtered[i].id),
                          onFavorite: () => _toggleFavorite(filtered[i]),
                          onApply: () => _showApplySheet(filtered[i]),
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
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onApply;

  const _OfferCard({
    required this.offer,
    required this.isFavorite,
    required this.onFavorite,
    required this.onApply,
  });

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.categoryLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onFavorite,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                    color: isFavorite ? AppColors.brand500 : AppColors.inkMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            offer.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.4),
          ),
          if (offer.requiredSkills != null && offer.requiredSkills!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: offer.requiredSkills!.take(4).map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sidebarActive,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(skill, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
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
                    style: const TextStyle(
                      color: AppColors.brand700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: offer.status, small: true),
              if (offer.applicationsCount != null) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 13, color: AppColors.inkMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${offer.applicationsCount}',
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ],
              if (offer.deadline != null) ...[
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 13, color: AppColors.inkMuted),
                    const SizedBox(width: 3),
                    Text(
                      DateFormat('dd MMM', 'fr').format(offer.deadline!),
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ] else
                const Spacer(),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: onApply,
                child: const Text('Candidater'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplySheet extends StatefulWidget {
  final OfferModel offer;
  final JobService service;
  const _ApplySheet({required this.offer, required this.service});

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _letterCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _daysCtrl   = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _letterCtrl.dispose();
    _budgetCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final letter = _letterCtrl.text.trim();
    final budget = double.tryParse(_budgetCtrl.text.trim());
    final days   = int.tryParse(_daysCtrl.text.trim());

    if (letter.isEmpty) {
      setState(() => _error = 'La lettre de motivation est obligatoire');
      return;
    }
    if (budget == null || budget <= 0) {
      setState(() => _error = 'Entrez un budget proposé valide');
      return;
    }
    if (days == null || days <= 0) {
      setState(() => _error = 'Entrez un délai proposé valide (en jours)');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await widget.service.applyToOffer({
        'offerId':        widget.offer.id,
        'coverLetter':    letter,
        'proposedBudget': budget,
        'proposedDays':   days,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature envoyée avec succès !'),
            backgroundColor: AppColors.brand500,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de la candidature'),
            backgroundColor: AppColors.error,
          ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.offer.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.offer.budgetDisplay,
                        style: const TextStyle(color: AppColors.brand500, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 15),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                  ],
                ),
              ),
            const Text('Lettre de motivation *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
            const SizedBox(height: 8),
            TextField(
              controller: _letterCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Décrivez votre expérience et votre approche pour ce projet...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Budget proposé (DH) *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _budgetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: widget.offer.budgetDisplay,
                          prefixText: 'DH ',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Délai (jours) *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _daysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '7',
                          suffixText: 'j',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BrandButton(
              label: 'Envoyer la candidature',
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
