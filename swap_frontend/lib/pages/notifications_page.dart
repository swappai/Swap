import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/swap_request_service.dart';
import '../services/messaging_service.dart';
import '../services/b2c_auth_service.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'messages/chat_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    final items = await _service.getNotifications(uid);
    if (mounted) setState(() { _notifications = items; _loading = false; });
  }

  Future<void> _markAllRead() async {
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.markAllRead(uid);
    _load();
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.markRead(n.id, uid);
    _load();
  }

  Future<void> _handleTap(AppNotification n) async {
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null) return;

    // Mark as read first
    if (!n.isRead) {
      _service.markRead(n.id, uid);
    }

    try {
      switch (n.type) {
        case 'swap_accepted':
          // relatedId = swap request id → get conversation → open chat
          if (n.relatedId != null) {
            final req = await SwapRequestService().getRequest(n.relatedId!, uid);
            if (req.conversationId != null && mounted) {
              final conv = await MessagingService().getConversation(req.conversationId!, uid);
              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatPage(conversation: conv)),
                );
              }
            }
          }
          break;
        case 'new_message':
          // relatedId = conversation_id
          if (n.relatedId != null) {
            final conv = await MessagingService().getConversation(n.relatedId!, uid);
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatPage(conversation: conv)),
              );
            }
          }
          break;
        case 'swap_request':
          // Navigate to requester's profile
          if (n.senderUid != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage(uid: n.senderUid)),
            );
          }
          break;
        case 'swap_declined':
          // Just mark read, no navigation
          break;
      }
    } catch (e) {
      debugPrint('Notification tap error: $e');
    }

    _load();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'swap_request':
        return HugeIcons.strokeRoundedArrowDataTransferHorizontal;
      case 'swap_accepted':
        return HugeIcons.strokeRoundedCheckmarkCircle01;
      case 'swap_declined':
        return HugeIcons.strokeRoundedCancel01;
      case 'new_message':
        return HugeIcons.strokeRoundedMessage01;
      default:
        return HugeIcons.strokeRoundedNotification01;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'swap_request':
        return HomePage.accent;
      case 'swap_accepted':
        return HomePage.success;
      case 'swap_declined':
        return Colors.redAccent;
      case 'new_message':
        return const Color(0xFF60A5FA);
      default:
        return HomePage.textMuted;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: HomePage.bg,
      appBar: AppBar(
        backgroundColor: HomePage.bg,
        foregroundColor: HomePage.textPrimary,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: HomePage.accentAlt)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(HugeIcons.strokeRoundedNotification01, size: 48, color: HomePage.textMuted),
                      SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(color: HomePage.textMuted, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final color = _typeColor(n.type);
                      return InkWell(
                        onTap: () => _handleTap(n),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.isRead ? HomePage.surface : HomePage.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: n.isRead ? HomePage.line : color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_typeIcon(n.type), size: 18, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: TextStyle(
                                        color: HomePage.textPrimary,
                                        fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      n.body,
                                      style: const TextStyle(color: HomePage.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _timeAgo(n.createdAt),
                                    style: const TextStyle(color: HomePage.textMuted, fontSize: 11),
                                  ),
                                  if (!n.isRead) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
