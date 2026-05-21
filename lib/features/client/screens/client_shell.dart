import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/job_service.dart';
import '../../../data/services/message_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../shared/widgets/app_logo.dart';

class ClientShell extends StatefulWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  static const _routes = [
    '/client/dashboard',
    '/client/offers',
    '/client/applications',
    '/client/missions',
    '/client/freelancers',
  ];

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _unreadMessages  = 0;
  int _unreadNotifs    = 0;
  int _openOffers      = 0;
  int _pendingApps     = 0;
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
      final svc = JobService();
      final offers = await svc.getMyOffers();
      final open = offers.where((o) => o.status == 'OPEN').toList();
      if (mounted) setState(() => _openOffers = open.length);
      if (open.isNotEmpty) {
        final groups = await Future.wait(open.map((o) => svc.getOfferApplications(o.id)));
        final pending = groups.expand((l) => l).where((a) => a.isPending).length;
        if (mounted) setState(() => _pendingApps = pending);
      } else {
        if (mounted) setState(() => _pendingApps = 0);
      }
    } catch (_) {}
  }

  int _indexFor(String path) {
    for (int i = 0; i < ClientShell._routes.length; i++) {
      if (path.startsWith(ClientShell._routes[i])) return i;
    }
    return 0;
  }

  // Badge overlay for AppBar icons
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
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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

  // Badge overlay for bottom nav tab icons
  Widget _tabIcon(IconData icon, int count, {bool urgent = false}) {
    if (count == 0) return Icon(icon, size: 22);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22),
        Positioned(
          top: -5,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: urgent ? Colors.red : AppColors.inkSoft,
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

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined, size: 22),
      activeIcon: Icon(Icons.dashboard, size: 22),
      label: 'Accueil',
    ),
    BottomNavigationBarItem(
      icon: _tabIcon(Icons.work_outline, _openOffers),
      activeIcon: _tabIcon(Icons.work, _openOffers),
      label: 'Offres',
    ),
    BottomNavigationBarItem(
      icon: _tabIcon(Icons.people_outline, _pendingApps, urgent: _pendingApps > 0),
      activeIcon: _tabIcon(Icons.people, _pendingApps, urgent: _pendingApps > 0),
      label: 'Candidatures',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.rocket_launch_outlined, size: 22),
      activeIcon: Icon(Icons.rocket_launch, size: 22),
      label: 'Missions',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.group_outlined, size: 22),
      activeIcon: Icon(Icons.group, size: 22),
      label: 'Freelancers',
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
          _badgeIcon(
            icon: Icons.chat_bubble_outline,
            count: _unreadMessages,
            tooltip: 'Messages',
            onTap: () async {
              await context.push('/client/messages');
              if (mounted) _fetchCounts();
            },
          ),
          _badgeIcon(
            icon: Icons.notifications_outlined,
            count: _unreadNotifs,
            tooltip: 'Notifications',
            onTap: () async {
              await context.push('/client/notifications');
              if (mounted) _fetchCounts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Wallet',
            onPressed: () => context.push('/client/wallet'),
          ),
          _ClientAvatar(),
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
          onTap: (i) => context.go(ClientShell._routes[i]),
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

class _ClientAvatar extends StatelessWidget {
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
          color: AppColors.sidebarActive,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink,
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
      builder: (_) => _ClientProfileSheet(),
    );
  }
}

class _ClientProfileSheet extends StatelessWidget {
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
                    color: AppColors.sidebarActive,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
          _tile(context, Icons.settings_outlined, 'Paramètres', () {
            Navigator.pop(context);
            context.push('/client/settings');
          }),
          const Divider(height: 1),
          _tile(context, Icons.logout, 'Se déconnecter', () async {
            final router = GoRouter.of(context);
            Navigator.pop(context);
            await auth.logout();
            router.go('/login/client');
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
