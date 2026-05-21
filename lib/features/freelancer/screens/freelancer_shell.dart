import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/job_service.dart';
import '../../../data/services/message_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/app_logo.dart';

class FreelancerShell extends StatefulWidget {
  final Widget child;
  const FreelancerShell({super.key, required this.child});

  static const _routes = [
    '/freelancer/dashboard',
    '/freelancer/explore',
    '/freelancer/applications',
    '/freelancer/favorites',
    '/freelancer/profile',
  ];

  @override
  State<FreelancerShell> createState() => _FreelancerShellState();
}

class _FreelancerShellState extends State<FreelancerShell> {
  int  _unreadMessages   = 0;
  int  _unreadNotifs     = 0;
  int  _openOffersCount  = 0;
  int  _applicationsCount = 0;
  bool _available        = true;
  bool _togglingAvail    = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchCounts());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCounts() async {
    try {
      final n = await MessageService().getUnreadCount();
      if (mounted) setState(() => _unreadMessages = n);
    } catch (_) {}
    try {
      final n = await NotificationService().getUnreadCount();
      if (mounted) setState(() => _unreadNotifs = n);
    } catch (_) {}
    try {
      final profile = await UserService().getProfile();
      if (mounted) setState(() => _available = profile['available'] ?? true);
    } catch (_) {}
    try {
      final offers = await JobService().getOffers(params: {'size': 100});
      final open = offers.where((o) => o.status == 'OPEN').length;
      if (mounted) setState(() => _openOffersCount = open);
    } catch (_) {}
    try {
      final apps = await JobService().getMyApplications();
      if (mounted) setState(() => _applicationsCount = apps.length);
    } catch (_) {}
  }

  Future<void> _toggleAvailable() async {
    if (_togglingAvail) return;
    setState(() => _togglingAvail = true);
    final next = !_available;
    try {
      await UserService().updateProfile({'available': next});
      if (mounted) setState(() { _available = next; _togglingAvail = false; });
    } catch (_) {
      if (mounted) setState(() => _togglingAvail = false);
    }
  }

  int _indexFor(String path) {
    for (int i = 0; i < FreelancerShell._routes.length; i++) {
      if (path.startsWith(FreelancerShell._routes[i])) return i;
    }
    return 0;
  }

  // Badge for AppBar icons
  Widget _badgeIcon({
    required IconData icon,
    required int count,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onTap),
        if (count > 0)
          Positioned(
            top: 6, right: 6,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Badge for bottom nav tab icons
  Widget _tabIcon(IconData icon, int count) {
    if (count == 0) return Icon(icon, size: 22);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22),
        Positioned(
          top: -5, right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.inkSoft,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Availability chip shown in AppBar
  Widget _availChip() {
    return GestureDetector(
      onTap: _togglingAvail ? null : _toggleAvailable,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _available
              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
              : AppColors.border,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _available
                ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _togglingAvail
                    ? AppColors.inkMuted
                    : (_available ? const Color(0xFF22C55E) : AppColors.inkMuted),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _available ? 'Dispo' : 'Indispo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _togglingAvail
                    ? AppColors.inkMuted
                    : (_available ? const Color(0xFF22C55E) : AppColors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined, size: 22),
      activeIcon: Icon(Icons.dashboard, size: 22),
      label: 'Accueil',
    ),
    BottomNavigationBarItem(
      icon: _tabIcon(Icons.search_outlined, _openOffersCount),
      activeIcon: _tabIcon(Icons.search, _openOffersCount),
      label: 'Explorer',
    ),
    BottomNavigationBarItem(
      icon: _tabIcon(Icons.description_outlined, _applicationsCount),
      activeIcon: _tabIcon(Icons.description, _applicationsCount),
      label: 'Candidatures',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.bookmark_outline, size: 22),
      activeIcon: Icon(Icons.bookmark, size: 22),
      label: 'Favoris',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_circle_outlined, size: 22),
      activeIcon: Icon(Icons.account_circle, size: 22),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _indexFor(location);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const AppLogo(size: 28, showText: false),
        actions: [
          _availChip(),
          _badgeIcon(
            icon: Icons.chat_bubble_outline,
            count: _unreadMessages,
            tooltip: 'Messages',
            onTap: () async {
              await context.push('/freelancer/messages');
              if (mounted) _fetchCounts();
            },
          ),
          _badgeIcon(
            icon: Icons.notifications_outlined,
            count: _unreadNotifs,
            tooltip: 'Notifications',
            onTap: () async {
              await context.push('/freelancer/notifications');
              if (mounted) _fetchCounts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Wallet',
            onPressed: () => context.push('/freelancer/wallet'),
          ),
          _UserAvatar(),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => context.go(FreelancerShell._routes[i]),
          selectedItemColor: AppColors.brand500,
          unselectedItemColor: AppColors.inkMuted,
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: _navItems,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initials = auth.user?.initials ?? '?';

    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        width: 32, height: 32,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: AppColors.brand100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand700,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProfileSheet(),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brand100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.brand700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _tile(context, Icons.rocket_launch_outlined, 'Missions actives', () {
            Navigator.pop(context);
            context.push('/freelancer/active-missions');
          }),
          _tile(context, Icons.folder_outlined, 'Portfolio', () {
            Navigator.pop(context);
            context.push('/freelancer/portfolio');
          }),
          _tile(context, Icons.account_balance_wallet_outlined, 'Wallet', () {
            Navigator.pop(context);
            context.push('/freelancer/wallet');
          }),
          _tile(context, Icons.settings_outlined, 'Paramètres', () {
            Navigator.pop(context);
            context.push('/freelancer/settings');
          }),
          const Divider(height: 1),
          _tile(context, Icons.logout, 'Se déconnecter', () async {
            Navigator.pop(context);
            await auth.logout();
            if (context.mounted) context.go('/login/freelancer');
          }, color: AppColors.error),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.inkSoft, size: 20),
      title: Text(label, style: TextStyle(color: color ?? AppColors.ink, fontSize: 14)),
      trailing: color == null
          ? const Icon(Icons.chevron_right, color: AppColors.inkMuted, size: 18)
          : null,
      onTap: onTap,
      dense: true,
    );
  }
}
