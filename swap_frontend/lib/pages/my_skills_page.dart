import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/b2c_auth_service.dart';
import '../services/skill_service.dart';
import '../widgets/app_sidebar.dart';
import 'home_page.dart';
import 'post_skill_page.dart';

class MySkillsPage extends StatefulWidget {
  const MySkillsPage({super.key});

  @override
  State<MySkillsPage> createState() => _MySkillsPageState();
}

class _MySkillsPageState extends State<MySkillsPage> {
  List<Skill>? _skills;
  bool _loading = true;

  String? get _uid => B2CAuthService.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final skills = await SkillService().getSkillsByUser(uid);
      if (mounted) setState(() { _skills = skills; _loading = false; });
    } catch (e) {
      debugPrint('Error loading skills: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSkill(Skill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HomePage.surface,
        title: const Text('Delete Skill', style: TextStyle(color: HomePage.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${skill.title}"?',
          style: const TextStyle(color: HomePage.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await SkillService().deleteSkill(skill.id, _uid!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill deleted')),
        );
        _loadSkills();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _editSkill(Skill skill) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostSkillPage(existingSkill: skill)),
    );
    _loadSkills();
  }

  void _postNewSkill() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostSkillPage()),
    );
    _loadSkills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSidebar(active: 'My Skills'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Text(
                          'My Skills',
                          style: TextStyle(
                            color: HomePage.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                        if (_skills != null && _skills!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: HomePage.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: HomePage.accent.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${_skills!.length}',
                              style: const TextStyle(color: HomePage.accentAlt, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        const Spacer(),
                        SizedBox(
                          height: 42,
                          child: FilledButton.icon(
                            onPressed: _postNewSkill,
                            icon: const Icon(HugeIcons.strokeRoundedPlusSign, size: 18),
                            label: const Text('Post New Skill'),
                            style: FilledButton.styleFrom(
                              backgroundColor: HomePage.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage the skills you offer to the community',
                      style: TextStyle(color: HomePage.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Content
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_skills == null || _skills!.isEmpty)
                      _buildEmptyState()
                    else
                      ..._skills!.map((skill) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SkillCard(
                          skill: skill,
                          onEdit: () => _editSkill(skill),
                          onDelete: () => _deleteSkill(skill),
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        color: HomePage.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: HomePage.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: HomePage.surfaceAlt,
                child: Icon(HugeIcons.strokeRoundedIdea, color: HomePage.textMuted, size: 40),
              ),
              const SizedBox(height: 14),
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
                'Share your expertise and start swapping',
                style: TextStyle(color: HomePage.textMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: _postNewSkill,
                  icon: const Icon(HugeIcons.strokeRoundedPlusSign, size: 18),
                  label: const Text('Post Your First Skill'),
                  style: FilledButton.styleFrom(
                    backgroundColor: HomePage.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.onEdit,
    required this.onDelete,
  });

  final Skill skill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Design':
        return const Color(0xFFE879F9);
      case 'Development':
      case 'Programming':
        return const Color(0xFF60A5FA);
      case 'Business':
        return const Color(0xFF34D399);
      case 'Music':
        return const Color(0xFFFBBF24);
      case 'Language':
        return const Color(0xFFF87171);
      case 'Writing':
        return const Color(0xFF818CF8);
      case 'Tutoring':
        return const Color(0xFF2DD4BF);
      case 'Cooking':
        return const Color(0xFFFF9F43);
      case 'Photography':
        return const Color(0xFFFF6B6B);
      case 'Marketing':
        return const Color(0xFF48DBFB);
      case 'Fitness':
        return const Color(0xFF1DD1A1);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(skill.category);

    return Container(
      decoration: BoxDecoration(
        color: HomePage.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomePage.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: catColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      _badge(skill.category, _categoryColor(skill.category), icon: _categoryIcon(skill.category)),
                      const SizedBox(width: 6),
                      _badge(skill.difficulty, const Color(0xFFF59E0B)),
                      const SizedBox(width: 12),
                      _actionButton(HugeIcons.strokeRoundedEdit01, 'Edit', onEdit),
                      const SizedBox(width: 4),
                      _actionButton(HugeIcons.strokeRoundedDelete01, 'Delete', onDelete, color: Colors.red),
                    ],
                  ),
                  if (skill.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      skill.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: HomePage.textMuted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoPill(HugeIcons.strokeRoundedClock01, '${skill.estimatedHours.toStringAsFixed(skill.estimatedHours == skill.estimatedHours.roundToDouble() ? 0 : 1)}h'),
                      const SizedBox(width: 8),
                      _infoPill(HugeIcons.strokeRoundedLocation01, skill.delivery),
                      if (skill.deliverables.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _infoPill(HugeIcons.strokeRoundedCheckmarkCircle01, '${skill.deliverables.length} deliverable${skill.deliverables.length == 1 ? '' : 's'}'),
                      ],
                    ],
                  ),
                  if (skill.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: skill.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: catColor.withValues(alpha: 0.3)),
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
    );
  }

  static Widget _actionButton(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? HomePage.textMuted),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'Design':
        return HugeIcons.strokeRoundedPaintBrush01;
      case 'Development':
      case 'Programming':
        return HugeIcons.strokeRoundedSourceCode;
      case 'Business':
        return HugeIcons.strokeRoundedChart;
      case 'Music':
        return HugeIcons.strokeRoundedMusicNote01;
      case 'Language':
        return HugeIcons.strokeRoundedTranslation;
      case 'Writing':
        return HugeIcons.strokeRoundedQuillWrite01;
      case 'Tutoring':
        return HugeIcons.strokeRoundedTeacher;
      case 'Cooking':
        return HugeIcons.strokeRoundedChefHat;
      case 'Photography':
        return HugeIcons.strokeRoundedCamera01;
      case 'Marketing':
        return HugeIcons.strokeRoundedMegaphone01;
      case 'Fitness':
        return HugeIcons.strokeRoundedDumbbell01;
      default:
        return HugeIcons.strokeRoundedStars;
    }
  }

  static Widget _badge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
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
