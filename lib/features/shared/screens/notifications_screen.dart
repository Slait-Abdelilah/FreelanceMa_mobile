import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _svc = NotificationService();
  List<NotificationModel> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notifs = await _svc.getNotifications();
      if (mounted) setState(() { _notifs = notifs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _svc.markAllAsRead();
      setState(() {
        _notifs = _notifs.map((n) => NotificationModel(
          id: n.id, type: n.type, title: n.title, message: n.message,
          offerId: n.offerId, applicationId: n.applicationId,
          isRead: true, createdAt: n.createdAt,
        )).toList();
      });
    } catch (_) {}
  }

  Future<void> _delete(NotificationModel n) async {
    try {
      await _svc.delete(n.id);
      setState(() => _notifs.removeWhere((x) => x.id == n.id));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tout lire', style: TextStyle(color: AppColors.brand500, fontSize: 13)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(child: SkeletonList())
          : _notifs.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'Aucune notification',
                  subtitle: 'Vous serez notifié ici des\nnouvelles candidatures et mises à jour.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brand500,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _NotifTile(
                      notif: _notifs[i],
                      onRead: () async {
                        if (!_notifs[i].isRead) {
                          await _svc.markAsRead(_notifs[i].id);
                          _load();
                        }
                      },
                      onDelete: () => _delete(_notifs[i]),
                    ),
                  ),
                ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onRead;
  final VoidCallback onDelete;

  const _NotifTile({
    required this.notif,
    required this.onRead,
    required this.onDelete,
  });

  IconData get _icon {
    switch (notif.type) {
      case 'APPLICATION_RECEIVED': return Icons.person_add_outlined;
      case 'APPLICATION_ACCEPTED': return Icons.check_circle_outline;
      case 'APPLICATION_REJECTED': return Icons.cancel_outlined;
      case 'MISSION_COMPLETED': return Icons.star_outline;
      case 'PAYMENT': return Icons.payments_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (notif.type) {
      case 'APPLICATION_ACCEPTED': return AppColors.brand500;
      case 'APPLICATION_REJECTED': return AppColors.error;
      case 'PAYMENT': return AppColors.warning;
      default: return AppColors.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notif-${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onRead,
        child: Container(
          color: notif.isRead ? AppColors.surface : AppColors.brand100.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.message,
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('dd MMM · HH:mm', 'fr').format(notif.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.brand500,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
