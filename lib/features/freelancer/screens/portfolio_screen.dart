import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/brand_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _svc = UserService();
  List<PortfolioModel> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final projects = await _svc.getPortfolio();
      if (mounted) setState(() { _projects = projects; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddSheet({PortfolioModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProjectSheet(
        service: _svc,
        existing: existing,
        onDone: _load,
      ),
    );
  }

  Future<void> _delete(PortfolioModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le projet'),
        content: Text('Supprimer "${p.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.deletePortfolioProject(p.id);
        _load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Portfolio'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showAddSheet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter'),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand500),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(child: SkeletonList())
          : _projects.isEmpty
              ? EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'Portfolio vide',
                  subtitle: 'Showcasez vos meilleurs projets\npour attirer plus de clients.',
                  actionLabel: 'Ajouter un projet',
                  onAction: _showAddSheet,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brand500,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ProjectCard(
                      project: _projects[i],
                      onEdit: () => _showAddSheet(existing: _projects[i]),
                      onDelete: () => _delete(_projects[i]),
                    ),
                  ),
                ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final PortfolioModel project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Image.network(
                project.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: AppColors.sidebarActive,
                  child: const Center(child: Icon(Icons.image_outlined, color: AppColors.inkMuted)),
                ),
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sidebarActive,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: const Center(
                child: Icon(Icons.code_outlined, size: 32, color: AppColors.inkMuted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.inkSoft),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  project.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (project.projectUrl != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(project.projectUrl!);
                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 14, color: AppColors.brand500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.projectUrl!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.brand500,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSheet extends StatefulWidget {
  final UserService service;
  final PortfolioModel? existing;
  final VoidCallback onDone;

  const _ProjectSheet({
    required this.service,
    this.existing,
    required this.onDone,
  });

  @override
  State<_ProjectSheet> createState() => _ProjectSheetState();
}

class _ProjectSheetState extends State<_ProjectSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imgCtrl;
  late final TextEditingController _urlCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _imgCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
    _urlCtrl = TextEditingController(text: widget.existing?.projectUrl ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      if (_imgCtrl.text.isNotEmpty) 'imageUrl': _imgCtrl.text.trim(),
      if (_urlCtrl.text.isNotEmpty) 'projectUrl': _urlCtrl.text.trim(),
    };
    try {
      if (widget.existing != null) {
        await widget.service.updatePortfolioProject(widget.existing!.id, data);
      } else {
        await widget.service.addPortfolioProject(data);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null ? 'Projet modifié' : 'Projet ajouté'),
            backgroundColor: AppColors.brand500,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
                    widget.existing != null ? 'Modifier le projet' : 'Ajouter un projet',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Titre du projet *')),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _imgCtrl, decoration: const InputDecoration(labelText: 'URL de l\'image', prefixIcon: Icon(Icons.image_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Lien du projet', prefixIcon: Icon(Icons.link))),
            const SizedBox(height: 24),
            BrandButton(
              label: widget.existing != null ? 'Modifier' : 'Ajouter',
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
