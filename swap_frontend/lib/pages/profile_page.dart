import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/b2c_auth_service.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../services/skill_service.dart';
import '../services/swap_request_service.dart';
import '../services/messaging_service.dart';
import '../models/swap_request.dart';
import '../models/conversation.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/star_rating.dart';
import '../widgets/review_dialog.dart';
import 'home_page.dart';
import 'post_skill_page.dart';
import 'onboarding.dart';
import 'messages/chat_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.uid});

  /// If null, shows the current user's profile. If set, shows another user's profile.
  final String? uid;

  static const double _gutter = 12;

  @override
  Widget build(BuildContext context) {
    final currentUid = B2CAuthService.instance.currentUser?.uid;
    final targetUid = uid ?? currentUid;
    if (targetUid == null) return const _AuthGuard();
    final isOwnProfile = (uid == null || uid == currentUid);

    return Scaffold(
      backgroundColor: HomePage.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(active: isOwnProfile ? 'Profile' : ''),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: ProfileService().getProfile(targetUid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || snap.data == null) {
                    return _EmptyProfileCard(
                      onSetup: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSetupFlow(),
                        ),
                      ),
                    );
                  }

                  final data = snap.data!;
                  final name = (data['full_name'] ?? data['display_name'] ?? '').toString().trim();
                  final username = (data['username'] ?? '').toString().trim();
                  final city = (data['city'] ?? '').toString().trim();
                  final bio = (data['bio'] ?? '').toString().trim();
                  final photoUrl = data['photo_url'] as String?;
                  final timezone = (data['timezone'] ?? '').toString().trim();
                  final skillsToOffer = (data['skills_to_offer'] ?? '').toString();
                  final servicesNeeded = (data['services_needed'] ?? '').toString();
                  final swapCredits = (data['swap_credits'] as num?)?.toInt() ?? 0;
                  final swapsCompleted = (data['swaps_completed'] as num?)?.toInt() ?? 0;
                  final averageRating = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
                  final reviewCount = (data['review_count'] as num?)?.toInt() ?? 0;
                  final joinedAt = DateTime.tryParse(data['created_at'] ?? '');

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back button when viewing another user
                            if (!isOwnProfile)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back, size: 18),
                                    label: const Text('Back'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: HomePage.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            _HeaderBanner(
                              name: name.isEmpty ? (isOwnProfile ? 'Your Name' : 'User') : name,
                              username: username,
                              city: city,
                              timezone: timezone,
                              photoUrl: photoUrl,
                              joinedLabel: joinedAt == null
                                  ? 'Joined recently'
                                  : 'Joined ${_formatMonthYear(joinedAt)}',
                              swapCredits: swapCredits,
                              swapsCompleted: swapsCompleted,
                              averageRating: averageRating,
                              reviewCount: reviewCount,
                              verified: false,
                              topRated: false,
                              isOwnProfile: isOwnProfile,
                              onEdit: isOwnProfile
                                  ? () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProfileSetupFlow(),
                                      ),
                                    )
                                  : null,
                              onSettings: isOwnProfile
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Settings coming soon')),
                                      );
                                    }
                                  : null,
                            ),
                            if (bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Card(
                                color: HomePage.surface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: HomePage.line),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(HugeIcons.strokeRoundedUserAccount, size: 18, color: HomePage.accentAlt),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(bio, style: const TextStyle(color: HomePage.textPrimary, fontSize: 14, height: 1.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _StatCard(icon: HugeIcons.strokeRoundedExchange01, label: 'Total Swaps', value: '$swapsCompleted')),
                                const SizedBox(width: ProfilePage._gutter),
                                Expanded(child: _StatCard(icon: HugeIcons.strokeRoundedStar, label: 'Avg Rating', value: averageRating > 0 ? averageRating.toStringAsFixed(1) : '-')),
                                const SizedBox(width: ProfilePage._gutter),
                                Expanded(child: _StatCard(icon: HugeIcons.strokeRoundedCoins01, label: 'Credits', value: '$swapCredits')),
                                const SizedBox(width: ProfilePage._gutter),
                                Expanded(child: _StatCard(icon: HugeIcons.strokeRoundedCalendar03, label: 'Member Since', value: joinedAt != null ? _formatMonthYear(joinedAt) : 'Recently')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SegmentedTabs(
                              skillsLabel: 'My Skills',
                              reviewsLabel: 'Reviews',
                              activityLabel: 'Swap History',
                              skillsBuilder: () => _SkillsSection(
                                uid: targetUid,
                                isOwnProfile: isOwnProfile,
                                skillsToOffer: skillsToOffer,
                                servicesNeeded: servicesNeeded,
                                onPostFirst: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PostSkillPage(),
                                  ),
                                ),
                              ),
                              reviewsBuilder: () => _ReviewsSection(uid: targetUid),
                              activityBuilder: () => _SwapHistorySection(uid: targetUid),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Pieces ------------------------------ */

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({
    required this.name,
    required this.username,
    required this.city,
    required this.timezone,
    required this.photoUrl,
    required this.joinedLabel,
    required this.verified,
    required this.topRated,
    this.swapCredits = 0,
    this.swapsCompleted = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isOwnProfile = true,
    this.onEdit,
    this.onSettings,
  });

  final String name;
  final String username;
  final String city;
  final String timezone;
  final String? photoUrl;
  final String joinedLabel;
  final bool verified;
  final bool topRated;
  final int swapCredits;
  final int swapsCompleted;
  final double averageRating;
  final int reviewCount;
  final bool isOwnProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: HomePage.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          // Gradient banner
          Container(
            height: 128,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // content
                Padding(
                  padding: const EdgeInsets.only(top: 44),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 92), // under avatar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: HomePage.textPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                StarRating(
                                  rating: averageRating,
                                  count: reviewCount,
                                ),
                                if (verified)
                                  _pill(
                                    icon: Icons.verified,
                                    label: 'Verified',
                                    fg: const Color(0xFF22C55E),
                                  ),
                                if (topRated)
                                  _pill(
                                    icon: Icons.emoji_events_outlined,
                                    label: 'Top Rated',
                                    fg: const Color(0xFFF59E0B),
                                  ),
                                if (swapCredits > 0)
                                  _pill(
                                    icon: Icons.verified_outlined,
                                    label: '$swapCredits Credits',
                                    fg: const Color(0xFF22C55E),
                                  ),
                                if (swapsCompleted > 0)
                                  _pill(
                                    icon: Icons.swap_horiz,
                                    label: '$swapsCompleted Swap${swapsCompleted == 1 ? '' : 's'}',
                                    fg: const Color(0xFF7C3AED),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                if (city.isNotEmpty)
                                  _subInfo(
                                    icon: Icons.location_on_outlined,
                                    text: city,
                                  ),
                                if (joinedLabel.isNotEmpty)
                                  _subInfo(
                                    icon: Icons.calendar_month_outlined,
                                    text: joinedLabel,
                                  ),
                                _subInfo(
                                  icon: Icons.access_time,
                                  text: 'Responds in ~2h',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isOwnProfile && onEdit != null && onSettings != null)
                        Wrap(
                          spacing: 10,
                          children: [
                            _DarkChipButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit Profile',
                              onPressed: onEdit!,
                            ),
                            _DarkChipButton(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              onPressed: onSettings!,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // floating avatar with gradient ring + soft drop shadow
                Positioned(
                  left: 0,
                  top: -42,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF9F67FF), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FutureBuilder<String?>(
                      future: _resolvePhotoUrl(photoUrl),
                      builder: (context, snap) {
                        final url = snap.data;
                        return CircleAvatar(
                          radius: 42,
                          backgroundColor: HomePage.surfaceAlt,
                          foregroundImage: (url != null && url.isNotEmpty)
                              ? NetworkImage(url)
                              : null,
                          child: (url == null || url.isEmpty)
                              ? Text(
                                  name.isNotEmpty
                                      ? name.characters.first.toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: HomePage.textPrimary,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<String?> _resolvePhotoUrl(String? raw) async {
    if (raw == null || raw.isEmpty) return null;
    return raw; // https URL stored in Cosmos DB
  }

  static Widget _pill({
    required IconData icon,
    required String label,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HomePage.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HomePage.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  static Widget _subInfo({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: HomePage.textMuted, fontSize: 15),
        ),
      ],
    );
  }
}

/// Dark pill action like in the screenshot, matching theme
class _DarkChipButton extends StatelessWidget {
  const _DarkChipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomePage.surfaceAlt,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: HomePage.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: HomePage.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: HomePage.textPrimary,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        color: HomePage.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: HomePage.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomePage.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: HomePage.line),
                ),
                child: Icon(icon, color: HomePage.accentAlt),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: HomePage.accentAlt,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(color: HomePage.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatefulWidget {
  const _SegmentedTabs({
    required this.skillsBuilder,
    required this.reviewsBuilder,
    required this.activityBuilder,
    required this.skillsLabel,
    required this.reviewsLabel,
    required this.activityLabel,
  });
  final Widget Function() skillsBuilder;
  final Widget Function() reviewsBuilder;
  final Widget Function() activityBuilder;
  final String skillsLabel;
  final String reviewsLabel;
  final String activityLabel;

  @override
  State<_SegmentedTabs> createState() => _SegmentedTabsState();
}

class _SegmentedTabsState extends State<_SegmentedTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // dark pill bar
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: HomePage.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomePage.line),
          ),
          child: Row(
            children: [
              _tab(widget.skillsLabel, 0),
              _tab(widget.reviewsLabel, 1),
              _tab(widget.activityLabel, 2),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (_index) {
            0 => widget.skillsBuilder(),
            1 => widget.reviewsBuilder(),
            _ => widget.activityBuilder(),
          },
        ),
      ],
    );
  }

  Expanded _tab(String label, int i) {
    final active = _index == i;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _index = i),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? HomePage.surfaceAlt : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? HomePage.accentAlt : HomePage.line,
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? HomePage.textPrimary : HomePage.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillsSection extends StatefulWidget {
  const _SkillsSection({
    required this.uid,
    required this.isOwnProfile,
    required this.skillsToOffer,
    required this.servicesNeeded,
    required this.onPostFirst,
  });

  final String uid;
  final bool isOwnProfile;
  final String skillsToOffer;
  final String servicesNeeded;
  final VoidCallback onPostFirst;

  @override
  State<_SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<_SkillsSection> {
  List<Skill>? _skills;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await SkillService().getSkillsByUser(widget.uid);
      if (mounted) setState(() { _skills = skills; _loading = false; });
    } catch (e) {
      debugPrint('Error loading skills: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSkill(Skill skill) async {
    try {
      await SkillService().deleteSkill(skill.id, widget.uid);
      if (mounted) _loadSkills();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    final skills = _skills ?? [];
    if (skills.isEmpty) return _EmptySkills(onPostFirst: widget.onPostFirst);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final skill in skills) ...[
          _SkillCardItem(
            skill: skill,
            showDelete: widget.isOwnProfile,
            onDelete: () => _deleteSkill(skill),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.servicesNeeded.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          _SectionCard(
            title: 'Services I Need',
            child: Text(widget.servicesNeeded,
                style: const TextStyle(color: HomePage.textPrimary)),
          ),
        ],
      ],
    );
  }
}

class _SkillCardItem extends StatelessWidget {
  const _SkillCardItem({
    required this.skill,
    this.showDelete = false,
    this.onDelete,
  });
  final Skill skill;
  final bool showDelete;
  final VoidCallback? onDelete;

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'design': return const Color(0xFFEC4899);
      case 'development': return const Color(0xFF3B82F6);
      case 'business': return const Color(0xFF22C55E);
      case 'writing': return const Color(0xFFF59E0B);
      case 'language': return const Color(0xFF8B5CF6);
      case 'tutoring': return const Color(0xFF06B6D4);
      case 'music': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: HomePage.surface,
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: HomePage.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _categoryColor(skill.category),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill.title,
                            style: const TextStyle(
                              color: HomePage.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _badge(skill.category, _categoryColor(skill.category)),
                        const SizedBox(width: 6),
                        _badge(skill.difficulty, const Color(0xFFF59E0B)),
                        if (showDelete) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (skill.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        skill.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: HomePage.textMuted, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _infoPill(HugeIcons.strokeRoundedClock01, '${skill.estimatedHours.toStringAsFixed(skill.estimatedHours == skill.estimatedHours.roundToDouble() ? 0 : 1)}h'),
                        const SizedBox(width: 8),
                        _infoPill(HugeIcons.strokeRoundedLocation01, skill.delivery),
                      ],
                    ),
                    if (skill.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: skill.tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: HomePage.surfaceAlt,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: HomePage.line),
                          ),
                          child: Text(t, style: const TextStyle(color: HomePage.textPrimary, fontSize: 11)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  static Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HomePage.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: HomePage.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: HomePage.textMuted),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: HomePage.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: HomePage.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: HomePage.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: HomePage.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/* ---------------------------- Placeholders ---------------------------- */

class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard({required this.onSetup});
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: HomePage.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: HomePage.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_outline,
                size: 40,
                color: HomePage.textMuted,
              ),
              const SizedBox(height: 10),
              const Text(
                "Let's set up your profile",
                style: TextStyle(
                  color: HomePage.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We'll use your details to personalize your page.",
                style: TextStyle(color: HomePage.textMuted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: onSetup,
                  style: FilledButton.styleFrom(
                    backgroundColor: HomePage.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Complete Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySkills extends StatelessWidget {
  const _EmptySkills({required this.onPostFirst});
  final VoidCallback onPostFirst;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: HomePage.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: HomePage.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: HomePage.surfaceAlt,
              child: Icon(
                Icons.person_outline,
                color: HomePage.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No skills posted yet',
              style: TextStyle(
                color: HomePage.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share your expertise with the community',
              style: TextStyle(color: HomePage.textMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: onPostFirst,
                style: FilledButton.styleFrom(
                  backgroundColor: HomePage.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Post Your First Skill'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.uid});
  final String uid;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  List<ReviewModel>? _reviews;
  double _avgRating = 0.0;
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final result = await ReviewService().getUserReviews(widget.uid);
      if (mounted) {
        setState(() {
          _reviews = result.reviews;
          _avgRating = result.averageRating;
          _total = result.total;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final reviews = _reviews ?? [];
    if (reviews.isEmpty) {
      return _SectionCard(
        title: 'Reviews',
        child: const Text(
          'No reviews yet.',
          style: TextStyle(color: HomePage.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary
        Card(
          color: HomePage.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: HomePage.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                StarRating(rating: _avgRating, count: _total),
                const Spacer(),
                Text(
                  '$_total review${_total == 1 ? '' : 's'}',
                  style: const TextStyle(color: HomePage.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Individual reviews
        for (final review in reviews) ...[
          _ReviewCard(review: review),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(review.createdAt);
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '';

    return Card(
      color: HomePage.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: HomePage.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HomePage.surfaceAlt,
                  foregroundImage: review.reviewerPhoto != null && review.reviewerPhoto!.isNotEmpty
                      ? NetworkImage(review.reviewerPhoto!)
                      : null,
                  child: Text(
                    (review.reviewerName ?? 'U').characters.first.toUpperCase(),
                    style: const TextStyle(color: HomePage.textPrimary, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName ?? 'Anonymous',
                        style: const TextStyle(
                          color: HomePage.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          StarRating(rating: review.rating.toDouble(), compact: true),
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(dateStr, style: const TextStyle(color: HomePage.textMuted, fontSize: 11)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.skillExchanged != null && review.skillExchanged!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Skill: ${review.skillExchanged}',
                style: const TextStyle(color: HomePage.textMuted, fontSize: 12),
              ),
            ],
            if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.reviewText!,
                style: const TextStyle(color: HomePage.textPrimary, fontSize: 13, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwapHistorySection extends StatefulWidget {
  const _SwapHistorySection({required this.uid});
  final String uid;

  @override
  State<_SwapHistorySection> createState() => _SwapHistorySectionState();
}

class _SwapHistorySectionState extends State<_SwapHistorySection> {
  List<SwapRequest>? _swaps;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSwaps();
  }

  Future<void> _loadSwaps() async {
    try {
      final service = SwapRequestService();
      final incoming = await service.getIncomingRequests(widget.uid);
      final outgoing = await service.getOutgoingRequests(widget.uid);
      final all = [...incoming, ...outgoing]
        .where((r) => r.isAccepted || r.isCompleted)
        .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() { _swaps = all; _loading = false; });
    } catch (e) {
      debugPrint('Error loading swap history: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openChat(BuildContext context, SwapRequest req) async {
    if (req.conversationId == null) return;
    final uid = B2CAuthService.instance.currentUser?.uid ?? '';
    try {
      final conversation = await MessagingService().getConversation(req.conversationId!, uid);
      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    final swaps = _swaps ?? [];
    if (swaps.isEmpty) {
      return _SectionCard(
        title: 'Swap History',
        child: const Text('No completed swaps yet.', style: TextStyle(color: HomePage.textMuted)),
      );
    }

    final currentUid = B2CAuthService.instance.currentUser?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final swap in swaps) ...[
          _SwapHistoryCard(
            swap: swap,
            currentUid: currentUid ?? '',
            onTap: swap.conversationId != null ? () => _openChat(context, swap) : null,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SwapHistoryCard extends StatelessWidget {
  const _SwapHistoryCard({required this.swap, required this.currentUid, this.onTap});
  final SwapRequest swap;
  final String currentUid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncoming = swap.recipientUid == currentUid;
    final other = isIncoming ? swap.requesterProfile : swap.recipientProfile;
    final statusColor = swap.isCompleted ? HomePage.success : Colors.greenAccent;
    final date = swap.respondedAt ?? swap.updatedAt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: HomePage.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: HomePage.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: HomePage.surfaceAlt,
                backgroundImage: (other?.photoUrl != null && other!.photoUrl!.isNotEmpty) ? NetworkImage(other.photoUrl!) : null,
                child: (other?.photoUrl == null || other!.photoUrl!.isEmpty)
                    ? Text((other?.displayName ?? 'U').characters.first.toUpperCase(), style: const TextStyle(color: HomePage.textPrimary))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other?.displayName ?? 'Unknown user',
                      style: const TextStyle(color: HomePage.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${swap.requesterOffer}  \u2192  ${swap.requesterNeed}',
                      style: const TextStyle(color: HomePage.textMuted, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      swap.status.name.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(color: HomePage.textMuted, fontSize: 11),
                  ),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(HugeIcons.strokeRoundedMessage01, size: 18, color: HomePage.accentAlt),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _AuthGuard extends StatelessWidget {
  const _AuthGuard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Please sign in to view your profile.',
        style: TextStyle(color: HomePage.textPrimary),
      ),
    );
  }
}

/* ----------------------------- Utilities ----------------------------- */

DateTime? _parseJoinedAt(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

String _formatMonthYear(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.year}';
}
