import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'landing_page.dart';
import 'marketplace_page.dart';
import 'notifications_page.dart';
import 'post_skill_page.dart';
import 'profile_page.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/search_service.dart';
import '../services/b2c_auth_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/star_rating.dart';
import '../services/swap_request_service.dart';
import '../models/swap_request.dart';
import 'request_page.dart';
import 'messages/conversations_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // ---- Theme (same palette family you've been using)
  static const Color bg = Color(0xFF0A0A0B);
  static const Color sidebar = Color(0xFF0F1115);
  static const Color surface = Color(0xFF12141B);
  static const Color surfaceAlt = Color(0xFF12141B);
  static const Color card = Color(0xFF111318);
  static const Color textPrimary = Color(0xFFEAEAF2);
  static const Color textMuted = Color(0xFFB6BDD0);
  static const Color line = Color(0xFF1F2937);
  static const Color accent = Color(0xFF7C3AED); // purple
  static const Color accentAlt = Color(0xFF9F67FF);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _profileService = ProfileService();
  final _searchService = SearchService();
  final _swapRequestService = SwapRequestService();

  Map<String, dynamic>? _profile;
  List<SearchResult> _reciprocalMatches = [];
  List<SkillSearchResult> _recommendedSkills = [];
  List<SwapRequest> _pendingRequests = [];
  List<SwapRequest> _activeSwaps = [];
  int _pointsBalance = 0;
  int _swapCredits = 0;
  int _swapsCompleted = 0;
  int _unreadNotifCount = 0;
  Timer? _notifTimer;
  bool _loading = true;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _pollNotifications();
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    // Load profile first, then dependent data in parallel.
    try {
      final profile = await _profileService.getProfile(uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _photoUrl = profile?['photo_url'] as String?;
        _swapCredits = (profile?['swap_credits'] as num?)?.toInt() ?? 0;
        _swapsCompleted = (profile?['swaps_completed'] as num?)?.toInt() ?? 0;
      });

      final servicesNeeded =
          (profile?['services_needed'] as String?) ?? '';

      // Fire parallel requests.
      await Future.wait([
        _loadPoints(uid),
        _loadPendingRequests(uid),
        _loadActiveSwaps(uid),
        if (servicesNeeded.isNotEmpty) _loadReciprocalMatches(servicesNeeded),
        if (servicesNeeded.isNotEmpty) _loadRecommendedSkills(servicesNeeded),
      ]);
    } catch (e) {
      debugPrint('[HomePage] load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPoints(String uid) async {
    try {
      final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}/points/balance?uid=$uid');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _pointsBalance = (data['balance'] as num?)?.toInt() ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('[HomePage] points error: $e');
    }
  }

  Future<void> _loadReciprocalMatches(String servicesNeeded) async {
    try {
      final results = await _searchService.search(
        servicesNeeded,
        mode: 'offers',
        limit: 10,
      );
      if (mounted) setState(() => _reciprocalMatches = results);
    } catch (e) {
      debugPrint('[HomePage] reciprocal matches error: $e');
    }
  }

  Future<void> _loadRecommendedSkills(String servicesNeeded) async {
    try {
      final results = await _searchService.searchSkills(
        servicesNeeded,
        limit: 10,
      );
      if (mounted) setState(() => _recommendedSkills = results);
    } catch (e) {
      debugPrint('[HomePage] recommended skills error: $e');
    }
  }

  Future<void> _loadPendingRequests(String uid) async {
    try {
      final results = await _swapRequestService.getIncomingRequests(
        uid,
        status: SwapRequestStatus.pending,
      );
      if (mounted) setState(() => _pendingRequests = results);
    } catch (e) {
      debugPrint('[HomePage] pending requests error: $e');
    }
  }

  Future<void> _loadActiveSwaps(String uid) async {
    try {
      final results = await Future.wait([
        _swapRequestService.getIncomingRequests(uid, status: SwapRequestStatus.accepted),
        _swapRequestService.getOutgoingRequests(uid, status: SwapRequestStatus.accepted),
      ]);
      final merged = [...results[0], ...results[1]];
      merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() => _activeSwaps = merged);
    } catch (e) {
      debugPrint('[HomePage] active swaps error: $e');
    }
  }

  void _pollNotifications() {
    Future<void> fetch() async {
      final uid = B2CAuthService.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      try {
        final count =
            await NotificationService().getUnreadCount(uid);
        if (mounted) setState(() => _unreadNotifCount = count);
      } catch (_) {}
    }

    fetch();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName {
    final display =
        _profile?['display_name'] as String? ??
        B2CAuthService.instance.currentUser?.displayName ??
        '';
    return display.split(' ').first;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.bg,
      body: Row(
        children: [
          const AppSidebar(active: 'Home'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: HomePage.accent))
              : RefreshIndicator(
                  color: HomePage.accent,
                  onRefresh: () async {
                    setState(() => _loading = true);
                    await _loadAll();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreetingCard(),
                        if (_pendingRequests.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _buildPendingRequests(),
                        ],
                        const SizedBox(height: 28),
                        _buildOverviewRow(),
                        if (_activeSwaps.isNotEmpty) ...[
                          const SizedBox(height: 36),
                          _buildActiveSwaps(),
                        ],
                        const SizedBox(height: 36),
                        _buildPerfectSwaps(),
                        const SizedBox(height: 36),
                        _buildRecommended(),
                        const SizedBox(height: 36),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: HomePage.surface,
        border: Border(bottom: BorderSide(color: HomePage.line)),
      ),
      child: Row(
        children: [
          const Text(
            'Home',
            style: TextStyle(
              color: HomePage.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(HugeIcons.strokeRoundedNotification02,
                    color: HomePage.textMuted),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const NotificationsPage()),
                ),
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadNotifCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: HomePage.accent,
              backgroundImage:
                  _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl == null
                  ? Text(
                      _firstName.isNotEmpty
                          ? _firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting card ───────────────────────────────────────────────────────────

  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1033), Color(0xFF12141B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomePage.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $_firstName!',
                  style: const TextStyle(
                    color: HomePage.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's your swap overview",
                  style: TextStyle(
                    color: HomePage.textMuted,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 32,
            backgroundColor: HomePage.accent,
            backgroundImage:
                _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null
                ? Text(
                    _firstName.isNotEmpty
                        ? _firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // ── Overview stats ──────────────────────────────────────────────────────────

  Widget _buildOverviewRow() {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                'Points Balance',
                '$_pointsBalance',
                HugeIcons.strokeRoundedCoins01,
                HomePage.accent)),
        const SizedBox(width: 16),
        Expanded(
            child: _statCard(
                'Swap Credits',
                '$_swapCredits',
                HugeIcons.strokeRoundedExchange01,
                HomePage.success)),
        const SizedBox(width: 16),
        Expanded(
            child: _statCard(
                'Swaps Completed',
                '$_swapsCompleted',
                HugeIcons.strokeRoundedCheckmarkCircle02,
                HomePage.warning)),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomePage.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomePage.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: HomePage.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: HomePage.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending Requests ────────────────────────────────────────────────────────

  Widget _buildPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pending Requests',
              style: TextStyle(
                color: HomePage.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: HomePage.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_pendingRequests.length}',
                style: const TextStyle(
                  color: HomePage.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RequestsPage()),
              ),
              child: const Text(
                'View All →',
                style: TextStyle(
                  color: HomePage.accentAlt,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _pendingRequests.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _pendingRequestCard(_pendingRequests[i]),
          ),
        ),
      ],
    );
  }

  Widget _pendingRequestCard(SwapRequest req) {
    final profile = req.requesterProfile;
    final name = profile?.displayName ?? 'Someone';
    final photoUrl = profile?.photoUrl;
    final timeAgo = _timeAgo(req.createdAt);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RequestsPage()),
      ),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomePage.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomePage.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: HomePage.accent,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: HomePage.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeAgo,
                  style: const TextStyle(
                      color: HomePage.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _tagLine(
              HugeIcons.strokeRoundedSearch01,
              'Wants: ${_truncate(req.requesterNeed, 35)}',
              HomePage.warning,
            ),
            const SizedBox(height: 6),
            _tagLine(
              HugeIcons.strokeRoundedCheckmarkCircle02,
              'Offering: ${_truncate(req.requesterOffer, 35)}',
              HomePage.success,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: HomePage.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Awaiting your response',
                style: TextStyle(
                  color: HomePage.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Swaps ──────────────────────────────────────────────────────────

  Widget _buildActiveSwaps() {
    final uid = B2CAuthService.instance.currentUser?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Swaps In Progress',
              style: TextStyle(
                color: HomePage.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: HomePage.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_activeSwaps.length}',
                style: const TextStyle(
                  color: HomePage.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _activeSwaps.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _activeSwapCard(_activeSwaps[i], uid),
          ),
        ),
      ],
    );
  }

  Widget _activeSwapCard(SwapRequest req, String? currentUid) {
    // Show the other person's info
    final isRequester = req.requesterUid == currentUid;
    final partner = isRequester ? req.recipientProfile : req.requesterProfile;
    final partnerName = partner?.displayName ?? 'Swap Partner';
    final photoUrl = partner?.photoUrl;
    final daysAgo = DateTime.now().difference(req.updatedAt).inDays;
    final startedText = daysAgo == 0 ? 'Started today' : 'Started $daysAgo day${daysAgo == 1 ? '' : 's'} ago';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConversationsPage()),
      ),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomePage.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomePage.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: HomePage.accent,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          partnerName.isNotEmpty
                              ? partnerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    partnerName,
                    style: const TextStyle(
                      color: HomePage.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tagLine(
              HugeIcons.strokeRoundedExchange01,
              '${_truncate(req.requesterOffer, 20)} ↔ ${_truncate(req.requesterNeed, 20)}',
              HomePage.accentAlt,
            ),
            const Spacer(),
            Text(
              startedText,
              style: const TextStyle(color: HomePage.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  // ── Perfect Swaps ───────────────────────────────────────────────────────────

  Widget _buildPerfectSwaps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfect Swaps',
          style: TextStyle(
            color: HomePage.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'People who want what you offer and offer what you need',
          style: TextStyle(color: HomePage.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_reciprocalMatches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HomePage.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomePage.line),
            ),
            child: const Text(
              'Complete your profile to see matches',
              style: TextStyle(color: HomePage.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _reciprocalMatches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) =>
                  _reciprocalMatchCard(_reciprocalMatches[i]),
            ),
          ),
      ],
    );
  }

  Widget _reciprocalMatchCard(SearchResult match) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfilePage(uid: match.uid),
        ),
      ),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomePage.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomePage.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: HomePage.accent,
                  child: Text(
                    match.displayName.isNotEmpty
                        ? match.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    match.displayName,
                    style: const TextStyle(
                      color: HomePage.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tagLine(
                HugeIcons.strokeRoundedCheckmarkCircle02,
                'Offers: ${_truncate(match.skillsToOffer, 40)}',
                HomePage.success),
            const SizedBox(height: 6),
            _tagLine(
                HugeIcons.strokeRoundedSearch01,
                'Needs: ${_truncate(match.servicesNeeded, 40)}',
                HomePage.warning),
            const Spacer(),
            if (match.city.isNotEmpty)
              Row(
                children: [
                  const Icon(HugeIcons.strokeRoundedLocation01,
                      color: HomePage.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    match.city,
                    style: const TextStyle(
                        color: HomePage.textMuted, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tagLine(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: HomePage.textMuted, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}...';

  // ── Recommended for You ─────────────────────────────────────────────────────

  Widget _buildRecommended() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for You',
          style: TextStyle(
            color: HomePage.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Skills that match what you\'re looking for',
          style: TextStyle(color: HomePage.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_recommendedSkills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HomePage.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomePage.line),
            ),
            child: const Text(
              'Add services you need to your profile to see recommendations',
              style: TextStyle(color: HomePage.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedSkills.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                if (i == _recommendedSkills.length) {
                  return _browseMarketplaceCard();
                }
                return _skillCard(_recommendedSkills[i]);
              },
            ),
          ),
      ],
    );
  }

  Widget _skillCard(SkillSearchResult skill) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfilePage(uid: skill.postedBy),
        ),
      ),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomePage.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomePage.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HomePage.accent,
                  backgroundImage: skill.posterPhotoUrl.isNotEmpty
                      ? NetworkImage(skill.posterPhotoUrl)
                      : null,
                  child: skill.posterPhotoUrl.isEmpty
                      ? Text(
                          skill.posterName.isNotEmpty
                              ? skill.posterName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    skill.posterName,
                    style: const TextStyle(
                      color: HomePage.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              skill.title,
              style: const TextStyle(
                color: HomePage.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: HomePage.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                skill.category.isNotEmpty ? skill.category : 'Skill',
                style: const TextStyle(
                  color: HomePage.accentAlt,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _browseMarketplaceCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MarketplacePage()),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: HomePage.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomePage.line),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(HugeIcons.strokeRoundedArrowRight01,
                  color: HomePage.accentAlt, size: 32),
              SizedBox(height: 8),
              Text(
                'Browse\nMarketplace',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HomePage.accentAlt,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick Actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            'Post a Skill',
            HugeIcons.strokeRoundedPlusSign,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostSkillPage()),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _actionButton(
            'Browse Marketplace',
            HugeIcons.strokeRoundedSearch01,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MarketplacePage()),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _actionButton(
            'View Messages',
            HugeIcons.strokeRoundedMessage01,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ConversationsPage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: HomePage.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomePage.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: HomePage.accentAlt, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: HomePage.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
