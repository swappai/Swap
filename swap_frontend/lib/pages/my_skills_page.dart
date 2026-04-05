import 'package:flutter/material.dart';

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
                        const Spacer(),
                        SizedBox(
                          height: 42,
                          child: FilledButton.icon(
                            onPressed: _postNewSkill,
                            icon: const Icon(Icons.add, size: 18),
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
                child: Icon(Icons.lightbulb_outline, color: HomePage.textMuted, size: 40),
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
                  icon: const Icon(Icons.add, size: 18),
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
                _badge(skill.category, HomePage.accent),
                const SizedBox(width: 6),
                _badge(skill.difficulty, const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _actionButton(Icons.edit_outlined, 'Edit', onEdit),
                const SizedBox(width: 4),
                _actionButton(Icons.delete_outline, 'Delete', onDelete, color: Colors.red),
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
                _infoPill(Icons.schedule, '${skill.estimatedHours.toStringAsFixed(skill.estimatedHours == skill.estimatedHours.roundToDouble() ? 0 : 1)}h'),
                const SizedBox(width: 8),
                _infoPill(Icons.location_on_outlined, skill.delivery),
                if (skill.deliverables.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _infoPill(Icons.check_circle_outline, '${skill.deliverables.length} deliverable${skill.deliverables.length == 1 ? '' : 's'}'),
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
