import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../services/b2c_auth_service.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../services/skill_service.dart';
import '../services/swap_request_service.dart';
import '../services/messaging_service.dart';
import '../models/swap_request.dart';

import '../widgets/app_sidebar.dart';
import '../widgets/star_rating.dart';

import 'home_page.dart';
import 'post_skill_page.dart';
import 'onboarding.dart';
import 'edit_profile_page.dart';
import 'messages/chat_page.dart';

// Restrained palette — 5 muted category tones
const _catPurple = Color(0xFFA78BFA); // Design/Writing/Photo
const _catBlue   = Color(0xFF7DD3FC); // Dev/Business/Marketing
const _catRose   = Color(0xFFFCA5A5); // Music/Language
const _catGreen  = Color(0xFF6EE7B7); // Tutoring/Fitness
const _catAmber  = Color(0xFFFCD34D); // Other/Cooking

const _textPrimary   = HomePage.textPrimary;
const _textSecondary = Color(0xFF9CA3AF);
const _textMuted     = HomePage.textMuted;
const _accent        = HomePage.accent;
const _line          = HomePage.line;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.uid});

  /// If null, shows the current user's profile. If set, shows another user's profile.
  final String? uid;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _refreshKey = 0;

  Future<void> _pickAndUploadPhoto(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    // Crop to circle for profile photo
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Photo',
          toolbarColor: const Color(0xFF1A1A2E),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: HomePage.accent,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Crop Profile Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
        ),
        WebUiSettings(context: context),
      ],
    );
    if (cropped == null) return;

    try {
      final bytes = await cropped.readAsBytes();
      final name = picked.name;
      await ProfileService().uploadPhoto(uid, bytes, name);
      // Clear Flutter's image cache so the new photo shows immediately
      imageCache.clear();
      imageCache.clearLiveImages();
      if (mounted) setState(() => _refreshKey++);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = B2CAuthService.instance.currentUser?.uid;
    final targetUid = widget.uid ?? currentUid;
    if (targetUid == null) return const _AuthGuard();
    final isOwnProfile = (widget.uid == null || widget.uid == currentUid);

    return Scaffold(
      backgroundColor: HomePage.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(active: isOwnProfile ? 'Profile' : ''),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                key: ValueKey(_refreshKey),
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

                  final skillsToOffer = (data['skills_to_offer'] ?? '').toString();
                  final servicesNeeded = (data['services_needed'] ?? '').toString();
                  final swapCredits = (data['swap_credits'] as num?)?.toInt() ?? 0;
                  final swapsCompleted = (data['swaps_completed'] as num?)?.toInt() ?? 0;
                  final averageRating = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
                  final reviewCount = (data['review_count'] as num?)?.toInt() ?? 0;
                  final accountType = (data['account_type'] ?? '').toString().trim();
                  final joinedAt = DateTime.tryParse(data['created_at'] ?? '');

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
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
                                    icon: const Icon(HugeIcons.strokeRoundedArrowLeft01, size: 18),
                                    label: const Text('Back'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _textMuted,
                                    ),
                                  ),
                                ),
                              ),

                            // ===== HERO SECTION =====
                            _HeroSection(
                              name: name.isEmpty ? (isOwnProfile ? 'Your Name' : 'User') : name,
                              username: username,
                              city: city,
                              bio: bio,
                              photoUrl: photoUrl,
                              accountType: accountType,
                              averageRating: averageRating,
                              reviewCount: reviewCount,
                              joinedAt: joinedAt,
                              isOwnProfile: isOwnProfile,
                              onEdit: isOwnProfile
                                  ? () async {
                                      final changed = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                                      );
                                      if (changed == true && mounted) setState(() => _refreshKey++);
                                    }
                                  : null,
                              onSettings: isOwnProfile
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Settings coming soon')),
                                      );
                                    }
                                  : null,
                              onEditPhoto: isOwnProfile
                                  ? () => _pickAndUploadPhoto(targetUid)
                                  : null,
                              onMessage: !isOwnProfile
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Send a swap request to start a conversation')),
                                      );
                                    }
                                  : null,
                            ),

                            const SizedBox(height: 24),

                            // ===== STATS ROW (inline text) =====
                            _InlineStats(
                              swapsCompleted: swapsCompleted,
                              averageRating: averageRating,
                              swapCredits: swapCredits,
                              joinedAt: joinedAt,
                            ),

                            const SizedBox(height: 28),

                            // ===== TABS =====
                            _SegmentedTabs(
                              skillsLabel: isOwnProfile ? 'My Skills' : 'Skills',
                              reviewsLabel: 'Reviews',
                              activityLabel: 'Swap History',
                              skillsBuilder: () => _SkillsSection(
                                uid: targetUid,
                                isOwnProfile: isOwnProfile,
                                skillsToOffer: skillsToOffer,
                                servicesNeeded: servicesNeeded,
                                onPostFirst: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PostSkillPage()),
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

/* ========================== HERO SECTION ========================== */

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.name,
    required this.username,
    required this.city,
    required this.bio,
    required this.photoUrl,
    required this.accountType,
    required this.averageRating,
    required this.reviewCount,
    required this.joinedAt,
    required this.isOwnProfile,
    this.onEdit,
    this.onSettings,
    this.onEditPhoto,
    this.onMessage,
  });

  final String name;
  final String username;
  final String city;
  final String bio;
  final String? photoUrl;
  final String accountType;
  final double averageRating;
  final int reviewCount;
  final DateTime? joinedAt;
  final bool isOwnProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onSettings;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: HomePage.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (left)
          GestureDetector(
            onTap: onEditPhoto,
            child: Stack(
              children: [
                FutureBuilder<String?>(
                  future: _resolvePhotoUrl(photoUrl),
                  builder: (context, snap) {
                    final url = snap.data;
                    return CircleAvatar(
                      radius: 56,
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
                                color: _textPrimary,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    );
                  },
                ),
                if (onEditPhoto != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: HomePage.surface, width: 2),
                      ),
                      child: const Icon(HugeIcons.strokeRoundedCamera01, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Name / meta (center)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (accountType.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      _AccountTypeBadge(type: accountType),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (username.isNotEmpty)
                      _MetaChip(icon: HugeIcons.strokeRoundedUser, text: '@$username'),
                    if (city.isNotEmpty)
                      _MetaChip(icon: HugeIcons.strokeRoundedLocation01, text: city),
                    if (joinedAt != null)
                      _MetaChip(icon: HugeIcons.strokeRoundedCalendar03, text: 'Joined ${_formatMonthYear(joinedAt!)}'),
                    StarRating(rating: averageRating, count: reviewCount, compact: true),
                  ],
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    bio,
                    style: const TextStyle(color: _textSecondary, fontSize: 15, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          // Actions (far-right)
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isOwnProfile && onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(foregroundColor: _textMuted),
                  child: const Text('Edit Profile'),
                ),
              if (isOwnProfile && onSettings != null)
                TextButton(
                  onPressed: onSettings,
                  style: TextButton.styleFrom(foregroundColor: _textMuted),
                  child: const Text('Settings'),
                ),
              if (!isOwnProfile && onMessage != null)
                TextButton(
                  onPressed: onMessage,
                  style: TextButton.styleFrom(foregroundColor: HomePage.accentAlt),
                  child: const Text('Message'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<String?> _resolvePhotoUrl(String? raw) async {
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}

class _AccountTypeBadge extends StatelessWidget {
  const _AccountTypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isBusiness = type.toLowerCase() == 'business';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isBusiness ? const Color(0xFF22C55E) : _accent).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isBusiness ? const Color(0xFF22C55E) : _accent).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBusiness ? HugeIcons.strokeRoundedStore01 : HugeIcons.strokeRoundedUser,
            size: 12,
            color: isBusiness ? const Color(0xFF22C55E) : HomePage.accentAlt,
          ),
          const SizedBox(width: 4),
          Text(
            isBusiness ? 'Business' : 'Personal',
            style: TextStyle(
              color: isBusiness ? const Color(0xFF22C55E) : HomePage.accentAlt,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textMuted),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: _textMuted, fontSize: 13)),
      ],
    );
  }
}

/* ========================== INLINE STATS ========================== */

class _InlineStats extends StatelessWidget {
  const _InlineStats({
    required this.swapsCompleted,
    required this.averageRating,
    required this.swapCredits,
    required this.joinedAt,
  });
  final int swapsCompleted;
  final double averageRating;
  final int swapCredits;
  final DateTime? joinedAt;

  @override
  Widget build(BuildContext context) {
    final items = <_InlineStatItem>[
      _InlineStatItem('$swapsCompleted', 'Swaps'),
      _InlineStatItem(
        averageRating > 0 ? averageRating.toStringAsFixed(1) : '-',
        'Rating',
      ),
      _InlineStatItem('$swapCredits', 'Credits'),
      _InlineStatItem(
        joinedAt != null ? _formatMonthYear(joinedAt!) : 'Recently',
        'Joined',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: items[i].value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: ' ${items[i].label}',
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (i < items.length - 1)
            const Text(
              '  \u00B7  ',
              style: TextStyle(color: _textMuted, fontSize: 14),
            ),
        ],
      ],
    );
  }
}

class _InlineStatItem {
  const _InlineStatItem(this.value, this.label);
  final String value;
  final String label;
}

/* ========================== SEGMENTED TABS (underline style) ========================== */

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
        Column(
          children: [
            Row(
              children: [
                _tab(widget.skillsLabel, 0),
                _tab(widget.reviewsLabel, 1),
                _tab(widget.activityLabel, 2),
              ],
            ),
            Container(height: 1, color: _line),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (_index) {
            0 => widget.skillsBuilder(),
            1 => widget.reviewsBuilder(),
            _ => widget.activityBuilder(),
          },
        ),
      ],
    );
  }

  Widget _tab(String label, int i) {
    final active = _index == i;
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: () => setState(() => _index = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? _textPrimary : _textMuted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================== SKILLS SECTION ========================== */

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 2 : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 220,
              ),
              itemCount: skills.length,
              itemBuilder: (context, i) => _ProfileSkillCard(
                skill: skills[i],
                showDelete: widget.isOwnProfile,
                onDelete: () => _deleteSkill(skills[i]),
              ),
            ),
            if (widget.isOwnProfile) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final posted = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const PostSkillPage(popOnSuccess: true)),
                    );
                    if (posted == true && mounted) _loadSkills();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Skill'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomePage.accentAlt,
                    side: const BorderSide(color: _line),
                  ),
                ),
              ),
            ],
            if (widget.servicesNeeded.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _InfoCard(
                icon: HugeIcons.strokeRoundedSearchList01,
                title: 'Looking For',
                content: widget.servicesNeeded,
              ),
            ],
          ],
        );
      },
    );
  }
}

/* ========================== PROFILE SKILL CARD ========================== */

class _ProfileSkillCard extends StatelessWidget {
  const _ProfileSkillCard({
    required this.skill,
    this.showDelete = false,
    this.onDelete,
  });
  final Skill skill;
  final bool showDelete;
  final VoidCallback? onDelete;

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'design':
      case 'writing':
      case 'photography':
        return _catPurple;
      case 'development':
      case 'programming':
      case 'business':
      case 'marketing':
        return _catBlue;
      case 'music':
      case 'language':
        return _catRose;
      case 'tutoring':
      case 'fitness':
        return _catGreen;
      case 'cooking':
      default:
        return _catAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(skill.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: HomePage.surface,
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with category dot
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill.title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showDelete) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(HugeIcons.strokeRoundedDelete02, size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Description
          if (skill.description.isNotEmpty)
            Expanded(
              child: Text(
                skill.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.4),
              ),
            ),
          if (skill.description.isEmpty) const Spacer(),
          const SizedBox(height: 8),
          // Tags (monochrome)
          if (skill.tags.isNotEmpty)
            SizedBox(
              height: 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: skill.tags.length > 4 ? 4 : skill.tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  if (i == 3 && skill.tags.length > 4) {
                    return _tagChip('+${skill.tags.length - 3}');
                  }
                  return _tagChip(skill.tags[i]);
                },
              ),
            ),
          const SizedBox(height: 8),
          // Bottom stats: plain text with middle dots
          Text.rich(
            TextSpan(
              style: const TextStyle(color: _textMuted, fontSize: 12),
              children: [
                TextSpan(text: skill.difficulty),
                const TextSpan(text: '  \u00B7  '),
                TextSpan(text: skill.delivery),
                const TextSpan(text: '  \u00B7  '),
                TextSpan(
                  text: '${skill.estimatedHours.toStringAsFixed(skill.estimatedHours == skill.estimatedHours.roundToDouble() ? 0 : 1)}h',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: HomePage.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _textMuted,
          fontSize: 11,
        ),
      ),
    );
  }
}

/* ========================== INFO CARD ========================== */

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.content});
  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomePage.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: HomePage.accentAlt),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

/* ========================== REVIEWS SECTION ========================== */

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
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    final reviews = _reviews ?? [];
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: HomePage.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Icon(HugeIcons.strokeRoundedStar, size: 40, color: _textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            const Text('No reviews yet', style: TextStyle(color: _textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inline review summary (no card)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: const TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              StarRating(rating: _avgRating, compact: true),
              const SizedBox(width: 10),
              Text(
                '$_total review${_total == 1 ? '' : 's'}',
                style: const TextStyle(color: _textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        for (int i = 0; i < reviews.length; i++) ...[
          _ReviewCard(review: reviews[i]),
          if (i < reviews.length - 1)
            const Divider(color: _line, height: 1),
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
        ? '${_monthName(date.month)} ${date.day}, ${date.year}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _accent.withValues(alpha: 0.15),
                foregroundImage: review.reviewerPhoto != null && review.reviewerPhoto!.isNotEmpty
                    ? NetworkImage(review.reviewerPhoto!)
                    : null,
                child: Text(
                  (review.reviewerName ?? 'U').characters.first.toUpperCase(),
                  style: const TextStyle(color: HomePage.accentAlt, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? 'Anonymous',
                      style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Row(
                      children: [
                        StarRating(rating: review.rating.toDouble(), compact: true),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(dateStr, style: const TextStyle(color: _textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.skillExchanged != null && review.skillExchanged!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                review.skillExchanged!,
                style: const TextStyle(color: HomePage.accentAlt, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.reviewText!,
              style: const TextStyle(color: _textPrimary, fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}

/* ========================== SWAP HISTORY SECTION ========================== */

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
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: HomePage.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Icon(HugeIcons.strokeRoundedExchange01, size: 40, color: _textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            const Text('No completed swaps yet', style: TextStyle(color: _textMuted, fontSize: 15)),
          ],
        ),
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
    final isCompleted = swap.isCompleted;
    final statusColor = isCompleted ? HomePage.success : const Color(0xFF60A5FA);
    final statusLabel = swap.status.name.toUpperCase();
    final date = swap.respondedAt ?? swap.updatedAt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HomePage.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _accent.withValues(alpha: 0.15),
              backgroundImage: (other?.photoUrl != null && other!.photoUrl!.isNotEmpty) ? NetworkImage(other.photoUrl!) : null,
              child: (other?.photoUrl == null || other!.photoUrl!.isEmpty)
                  ? Text(
                      (other?.displayName ?? 'U').characters.first.toUpperCase(),
                      style: const TextStyle(color: HomePage.accentAlt, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other?.displayName ?? 'Unknown user',
                    style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HomePage.bg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            swap.requesterOffer,
                            style: const TextStyle(color: _textPrimary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(HugeIcons.strokeRoundedArrowDataTransferHorizontal, size: 14, color: HomePage.accentAlt),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HomePage.bg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            swap.requesterNeed,
                            style: const TextStyle(color: _textPrimary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: const TextStyle(color: _textMuted, fontSize: 11),
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
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

/* ========================== PLACEHOLDERS ========================== */

class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard({required this.onSetup});
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: HomePage.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.1),
              ),
              child: const Icon(HugeIcons.strokeRoundedUser, size: 40, color: HomePage.accentAlt),
            ),
            const SizedBox(height: 16),
            const Text(
              "Let's set up your profile",
              style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              "We'll use your details to personalize your page.",
              style: TextStyle(color: _textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: FilledButton(
                onPressed: onSetup,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Complete Profile'),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: HomePage.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.1),
            ),
            child: const Icon(HugeIcons.strokeRoundedStars, size: 36, color: HomePage.accentAlt),
          ),
          const SizedBox(height: 14),
          const Text(
            'No skills posted yet',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share your expertise with the community',
            style: TextStyle(color: _textMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onPostFirst,
              icon: const Icon(HugeIcons.strokeRoundedAdd01, size: 18),
              label: const Text('Post Your First Skill'),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthGuard extends StatelessWidget {
  const _AuthGuard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Please sign in to view your profile.',
        style: TextStyle(color: _textPrimary),
      ),
    );
  }
}

/* ========================== UTILITIES ========================== */

String _formatMonthYear(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.year}';
}
