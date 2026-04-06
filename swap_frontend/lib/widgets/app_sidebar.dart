// lib/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../pages/post_skill_page.dart';
import '../pages/my_skills_page.dart';
import '../pages/home_page.dart';
import '../pages/marketplace_page.dart';
import '../pages/landing_page.dart';
import '../pages/profile_page.dart';
import '../pages/request_page.dart';
import '../pages/wallet_page.dart';
import '../pages/messages/conversations_page.dart';
import '../services/b2c_auth_service.dart';
import '../services/messaging_service.dart';
import '../services/profile_service.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key, this.active = 'Home'});

  final String active;

  static const double width = 240;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final _messagingService = MessagingService();
  int _unreadCount = 0;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _fetchPhoto();
  }

  Future<void> _fetchUnreadCount() async {
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final count = await _messagingService.getTotalUnreadCount(uid);
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> _fetchPhoto() async {
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final profile = await ProfileService().getProfile(uid);
      final url = profile?['photo_url'] as String?;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _photoUrl = url);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    bool isActive(String label) =>
        widget.active.toLowerCase() == label.toLowerCase();

    return Container(
      width: AppSidebar.width,
      decoration: BoxDecoration(
        color: HomePage.sidebar,
        border: Border(right: BorderSide(color: HomePage.line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 70,
                child: Image.asset(
                  'assets/Swap-removebg-preview.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Divider(color: HomePage.line, height: 1),
          const SizedBox(height: 12),
          _NavItem(
            icon: HugeIcons.strokeRoundedHome01,
            label: 'Home',
            active: isActive('Home'),
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomePage()),
              (route) => false,
            ),
          ),
          _NavItem(
            icon: HugeIcons.strokeRoundedStore01,
            label: 'Marketplace',
            active: isActive('Marketplace'),
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MarketplacePage()),
              (route) => false,
            ),
          ),
          _NavItem(
            icon: HugeIcons.strokeRoundedPlusSign,
            label: 'Post Skill',
            active: isActive('Post Skill'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PostSkillPage())),
          ),
          _NavItem(
            icon: HugeIcons.strokeRoundedTask01,
            label: 'My Skills',
            active: isActive('My Skills'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MySkillsPage()),
            ),
          ),
          _NavItem(
            icon: HugeIcons.strokeRoundedInbox,
            label: 'Requests',
            active: isActive('Requests'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RequestsPage())),
          ),
          _NavItem(
            icon: HugeIcons.strokeRoundedMessage01,
            label: 'Messages',
            badge: _unreadCount > 0 ? '$_unreadCount' : null,
            active: isActive('Messages'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ConversationsPage())),
          ),
          _NavItem(
            icon: HugeIcons.strokeRoundedAnalytics01,
            label: 'Dashboard',
            active: isActive('Dashboard'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletPage()),
            ),
          ),
          _NavItem(
            icon: HugeIcons.strokeRoundedUser,
            label: 'Profile',
            active: isActive('Profile'),
            photoUrl: _photoUrl,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
          const Spacer(),
          _NavItem(
            icon: HugeIcons.strokeRoundedLogout01,
            label: 'Log Out',
            onTap: () async {
              await B2CAuthService.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.badge,
    this.photoUrl,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final String? badge;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      leadingWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? HomePage.accentAlt : HomePage.textMuted.withValues(alpha: 0.4),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      leadingWidget = Icon(
        icon,
        color: active ? HomePage.accentAlt : HomePage.textMuted,
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: active ? const Color(0x201A1333) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: leadingWidget,
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : HomePage.textMuted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: badge == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF164E63),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: HomePage.line),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
