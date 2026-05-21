import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/services/job_service.dart';
import '../../../data/services/message_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ClientMessagesScreen extends StatefulWidget {
  const ClientMessagesScreen({super.key});

  @override
  State<ClientMessagesScreen> createState() => _ClientMessagesScreenState();
}

class _ClientMessagesScreenState extends State<ClientMessagesScreen> {
  final _svc = JobService();
  List<ApplicationModel> _conversations = [];
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
      if (offers.isEmpty) {
        if (mounted) setState(() { _conversations = []; _loading = false; });
        return;
      }
      final nested = await Future.wait(
        offers.map((o) => _svc.getOfferApplications(o.id)),
      );
      final all = nested.expand((l) => l).toList();
      final convs = all
          .where((a) =>
              a.isAccepted ||
              a.isCompleted ||
              a.status == 'AWAITING_VALIDATION')
          .toList();
      if (mounted) setState(() { _conversations = convs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _loading
          ? const SingleChildScrollView(child: SkeletonList())
          : _conversations.isEmpty
              ? const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'Aucune conversation',
                  subtitle: 'Vos échanges avec les freelancers\napparaîtront ici.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brand500,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _ConvTile(
                      app: _conversations[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _ClientChatView(app: _conversations[i]),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

// ── Conversation tile ────────────────────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback onTap;
  const _ConvTile({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = app.freelancerName;
    final initials = app.freelancerInitials;
    final isActive = app.isAccepted || app.status == 'AWAITING_VALIDATION';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brand500.withValues(alpha: 0.12)
              : AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: name != null
            ? Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.brand700 : AppColors.inkMuted,
                  ),
                ),
              )
            : Icon(
                Icons.person_outline,
                color: isActive ? AppColors.brand500 : AppColors.inkMuted,
                size: 22,
              ),
      ),
      title: Text(
        name ?? 'Freelancer',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        app.offerTitle,
        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted, size: 18),
    );
  }
}

// ── Chat view ────────────────────────────────────────────────────────────────

class _ClientChatView extends StatefulWidget {
  final ApplicationModel app;
  const _ClientChatView({required this.app});

  @override
  State<_ClientChatView> createState() => _ClientChatViewState();
}

class _ClientChatViewState extends State<_ClientChatView> {
  final _msgSvc = MessageService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessageModel> _messages = [];
  StompClient? _stomp;
  String? _myUserId;
  bool _loading = true;
  bool _connected = false;

  String get _convId => 'conv_${widget.app.id}';

  bool _isMe(ChatMessageModel msg) {
    if (_myUserId != null && _myUserId!.isNotEmpty) {
      return msg.senderId == _myUserId;
    }
    return msg.senderRole == 'CLIENT';
  }

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _myUserId = await _msgSvc.getUserId();
    final token = await _msgSvc.getToken();

    try {
      final history = await _msgSvc.getHistory(_convId);
      if (mounted) setState(() { _messages = history; _loading = false; });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    if (token != null) {
      _stomp = StompClient(
        config: StompConfig(
          url: ApiConstants.wsJobServiceUrl,
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
          heartbeatOutgoing: const Duration(milliseconds: 0),
          heartbeatIncoming: const Duration(milliseconds: 0),
          reconnectDelay: const Duration(seconds: 5),
          onConnect: _onConnect,
          onDisconnect: (_) {
            if (mounted) setState(() => _connected = false);
          },
          onWebSocketError: (e) => debugPrint('WS error: $e'),
          onStompError: (f) => debugPrint('STOMP error: ${f.body}'),
        ),
      );
      _stomp!.activate();
    }
  }

  void _onConnect(StompFrame frame) {
    if (mounted) setState(() => _connected = true);
    _stomp!.subscribe(
      destination: '/topic/conversation/$_convId',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final msg = ChatMessageModel.fromJson(
            jsonDecode(frame.body!) as Map<String, dynamic>,
          );
          if (mounted) {
            setState(() {
              if (!_messages.any((m) => m.id == msg.id)) {
                _messages.add(msg);
              }
            });
            _scrollToBottom();
          }
        } catch (_) {}
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || !_connected || _stomp == null) return;
    _textCtrl.clear();
    _stomp!.send(
      destination: '/app/chat/$_convId',
      body: jsonEncode({'content': text}),
    );
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final freelancerName = widget.app.freelancerName ?? 'Freelancer';
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              freelancerName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _connected ? widget.app.offerTitle : 'Connexion...',
              style: TextStyle(
                fontSize: 11,
                color: _connected ? AppColors.inkSoft : AppColors.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const SingleChildScrollView(child: SkeletonList())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun message.\nCommencez la conversation !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.inkSoft, fontSize: 14, height: 1.6),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe = _isMe(msg);
                          final prevIsMe = i > 0 ? _isMe(_messages[i - 1]) : !isMe;
                          return _MessageBubble(
                            msg: msg,
                            isMe: isMe,
                            showDate: i == 0 ||
                                !_isSameDay(_messages[i - 1].createdAt, msg.createdAt),
                            showSenderLabel: isMe != prevIsMe,
                          );
                        },
                      ),
          ),
          _InputBar(controller: _textCtrl, onSend: _send, enabled: _connected),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMe;
  final bool showDate;
  final bool showSenderLabel;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    this.showDate = false,
    this.showSenderLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final local = msg.createdAt.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDate)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                DateFormat('EEEE d MMMM', 'fr').format(local),
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
            ),
          ),
        if (showSenderLabel)
          Padding(
            padding: EdgeInsets.only(
              bottom: 4,
              left: isMe ? 0 : 12,
              right: isMe ? 12 : 0,
              top: 6,
            ),
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                isMe ? 'Vous' : 'Freelancer',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            margin: EdgeInsets.only(
              bottom: 3,
              left: isMe ? 56 : 0,
              right: isMe ? 0 : 56,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.ink : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.ink,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(local),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.55)
                        : AppColors.inkMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: enabled ? 'Écrire un message...' : 'Connexion en cours...',
                  hintStyle:
                      const TextStyle(color: AppColors.inkMuted, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.cream,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.brand500 : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
