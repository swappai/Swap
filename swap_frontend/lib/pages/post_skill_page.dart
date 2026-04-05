import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/b2c_auth_service.dart';
import '../services/skill_service.dart';
import 'home_page.dart';
import '../widgets/app_sidebar.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF08080A);
const Color _surface = Color(0xFF111216);
const Color _card = Color(0xFF16171C);
const Color _border = Color(0xFF232530);
const Color _borderFocus = Color(0xFF6D5BF7);
const Color _accent = Color(0xFF6D5BF7);
const Color _accentSoft = Color(0xFF2A2350);
const Color _textSuccess = Color(0xFF6EE7B7);
const Color _textPrimary = Color(0xFFF0F0F8);
const Color _textSecondary = Color(0xFF9CA3AF);
const Color _textDim = Color(0xFF6B7280);

class PostSkillPage extends StatefulWidget {
  final Skill? existingSkill;
  final bool popOnSuccess;
  const PostSkillPage({super.key, this.existingSkill, this.popOnSuccess = false});

  @override
  State<PostSkillPage> createState() => _PostSkillPageState();
}

class _PostSkillPageState extends State<PostSkillPage> {
  final _formKey = GlobalKey<FormState>();
  bool _publishing = false;
  int _step = 0; // 0 = essentials, 1 = details, 2 = review

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '1');
  final _tagCtrl = TextEditingController();
  final _deliverableCtrl = TextEditingController();

  String? _category;
  String? _difficulty;
  String _delivery = 'Remote Only';
  final List<String> _tags = [];
  final List<String> _deliverables = [];

  static const _categories = [
    ('Design', Icons.brush_outlined, Color(0xFFE879F9)),
    ('Development', Icons.code_outlined, Color(0xFF60A5FA)),
    ('Business', Icons.trending_up_outlined, Color(0xFF34D399)),
    ('Music', Icons.music_note_outlined, Color(0xFFFBBF24)),
    ('Language', Icons.translate_outlined, Color(0xFFF87171)),
    ('Writing', Icons.edit_note_outlined, Color(0xFF818CF8)),
    ('Tutoring', Icons.school_outlined, Color(0xFF2DD4BF)),
    ('Other', Icons.category_outlined, Color(0xFF94A3B8)),
  ];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const _deliveryOptions = ['Remote Only', 'In-Person', 'Hybrid'];

  bool get _isEditing => widget.existingSkill != null;

  @override
  void initState() {
    super.initState();

    final skill = widget.existingSkill;
    if (skill != null) {
      _titleCtrl.text = skill.title;
      _descCtrl.text = skill.description;
      _hoursCtrl.text = skill.estimatedHours.toString();
      _category = skill.category.isNotEmpty ? skill.category : null;
      _difficulty = skill.difficulty.isNotEmpty ? skill.difficulty : null;
      _delivery = skill.delivery;
      _tags.addAll(skill.tags);
      _deliverables.addAll(skill.deliverables);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    _tagCtrl.dispose();
    _deliverableCtrl.dispose();
    super.dispose();
  }

  bool get _step0Valid =>
      _titleCtrl.text.trim().isNotEmpty &&
      _descCtrl.text.trim().isNotEmpty &&
      _category != null;

  bool get _step1Valid => _difficulty != null;

  bool get _canPublish => _step0Valid && _step1Valid;

  int get _completionPercent {
    int score = 0;
    if (_titleCtrl.text.trim().isNotEmpty) score += 15;
    if (_descCtrl.text.trim().length > 20) score += 15;
    if (_category != null) score += 15;
    if (_difficulty != null) score += 15;
    if (_tags.isNotEmpty) score += 10;
    if (_deliverables.isNotEmpty) score += 10;
    if (double.tryParse(_hoursCtrl.text) != null) score += 10;
    if (_descCtrl.text.trim().length > 80) score += 10;
    return score.clamp(0, 100);
  }

  void _addTag() {
    final v = _tagCtrl.text.trim();
    if (v.isNotEmpty && !_tags.contains(v)) {
      setState(() {
        _tags.add(v);
        _tagCtrl.clear();
      });
    }
  }

  void _addDeliverable() {
    final v = _deliverableCtrl.text.trim();
    if (v.isNotEmpty) {
      setState(() {
        _deliverables.add(v);
        _deliverableCtrl.clear();
      });
    }
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    final user = B2CAuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to post a skill')),
      );
      return;
    }

    setState(() => _publishing = true);
    try {
      final skillData = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'difficulty': _difficulty,
        'estimated_hours': double.tryParse(_hoursCtrl.text) ?? 1,
        'delivery': _delivery,
        'tags': _tags,
        'deliverables': _deliverables,
      };

      if (_isEditing) {
        await SkillService().updateSkill(
          widget.existingSkill!.id,
          user.uid,
          skillData,
        );
      } else {
        await SkillService().createSkill(user.uid, skillData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Skill updated!' : 'Skill posted!'),
          backgroundColor: _accent,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSidebar(active: 'Post Skill'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 40 : 20,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildStepIndicator(),
                            const SizedBox(height: 28),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildCurrentStep(),
                                  ),
                                  const SizedBox(width: 28),
                                  SizedBox(
                                    width: 340,
                                    child: _buildSidePanel(),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCurrentStep(),
                                  const SizedBox(height: 24),
                                  _buildSidePanel(),
                                ],
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

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Your Skill' : 'Create a Skill Listing',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share what you know, learn what you need',
                style: TextStyle(color: _textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
        Text(
          'Step ${_step + 1} of 3',
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Step Indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const labels = ['Essentials', 'Details', 'Review & Post'];
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 20),
                color: i <= _step ? _accent : _border,
              ),
            ),
          GestureDetector(
            onTap: () {
              if (i == 0 || (i == 1 && _step0Valid) || (i == 2 && _canPublish)) {
                setState(() => _step = i);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _step
                          ? _accent
                          : i == _step
                              ? _accent
                              : _border,
                    ),
                    child: Center(
                      child: i < _step
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == _step ? Colors.white : _textDim,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: i <= _step ? _textPrimary : _textDim,
                      fontSize: 12,
                      fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Step Content ──────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (_step) {
        0 => _buildStep0(),
        1 => _buildStep1(),
        _ => _buildStep2(),
      },
    );
  }

  // ── Step 0: Essentials ─────────────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionShell(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Skill Title', required: true),
                const SizedBox(height: 8),
                _textField(
                  controller: _titleCtrl,
                  hint: 'e.g., Logo Design in Figma',
                  maxLength: 200,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                _label('Description', required: true),
                const SizedBox(height: 8),
                _textField(
                  controller: _descCtrl,
                  hint:
                      "What will you teach? What's your experience? What will students walk away with?",
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 2000,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_descCtrl.text.length} / 2000',
                    style: TextStyle(
                      color: _descCtrl.text.length > 1800
                          ? _accent
                          : _textDim,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Category', required: true),
              const SizedBox(height: 12),
              _buildCategoryGrid(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildNavButtons(
          onNext: _step0Valid
              ? () => setState(() => _step = 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((cat) {
            final selected = _category == cat.$1;
            return GestureDetector(
              onTap: () => setState(() => _category = cat.$1),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: itemWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: selected ? _accentSoft : _card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: selected ? _accent : Colors.transparent,
                        width: 3,
                      ),
                      bottom: BorderSide(
                        color: selected ? Colors.transparent : _border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.$2, size: 18, color: selected ? _textPrimary : _textDim),
                      const SizedBox(width: 10),
                      Text(
                        cat.$1,
                        style: TextStyle(
                          color: selected ? _textPrimary : _textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Step 1: Details ────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Difficulty Level', required: true),
              const SizedBox(height: 12),
              Row(
                children: _levels.map((level) {
                  final selected = _difficulty == level;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: level != 'Advanced' ? 10 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _difficulty = level),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? Colors.transparent : _border,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  level,
                                  style: TextStyle(
                                    color: selected ? _textPrimary : _textSecondary,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 2,
                                  width: selected ? 24 : 0,
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Estimated Hours'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _hoursCtrl,
                          hint: '1',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Delivery Format'),
                        const SizedBox(height: 8),
                        _dropdown(
                          value: _delivery,
                          items: _deliveryOptions,
                          onChanged: (v) => setState(() => _delivery = v ?? _delivery),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Tags'),
              const SizedBox(height: 4),
              const Text(
                'Help people discover your skill',
                style: TextStyle(color: _textDim, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _tagCtrl,
                      hint: 'e.g., figma, branding, ui...',
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(Icons.add_rounded, onTap: _addTag),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((t) => _tagChip(t)).toList(),
                ),
              ],
              const SizedBox(height: 24),
              _label('Deliverables'),
              const SizedBox(height: 4),
              const Text(
                'What will the learner walk away with?',
                style: TextStyle(color: _textDim, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _deliverableCtrl,
                      hint: 'e.g., 3 logo concepts with revisions',
                      onSubmitted: (_) => _addDeliverable(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(Icons.add_rounded, onTap: _addDeliverable),
                ],
              ),
              if (_deliverables.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(_deliverables.length, (i) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '\u2014',
                          style: const TextStyle(color: _textDim, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _deliverables[i],
                            style: const TextStyle(color: _textPrimary, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _deliverables.removeAt(i)),
                          child: const Icon(Icons.close_rounded, size: 16, color: _textDim),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildNavButtons(
          onBack: () => setState(() => _step = 0),
          onNext: _step1Valid
              ? () => setState(() => _step = 2)
              : null,
        ),
      ],
    );
  }

  // ── Step 2: Review & Publish ───────────────────────────────────────────────

  Widget _buildStep2() {
    final catEntry = _categories.firstWhere(
      (c) => c.$1 == _category,
      orElse: () => _categories.last,
    );

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live preview card
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent bar at top
              Container(height: 3, color: _accent),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18, color: _textDim),
                        const SizedBox(width: 8),
                        const Text(
                          'Preview \u2014 how others will see your listing',
                          style: TextStyle(color: _textDim, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _titleCtrl.text.isEmpty ? 'Untitled Skill' : _titleCtrl.text,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: catEntry.$3.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: catEntry.$3.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(catEntry.$2, size: 14, color: catEntry.$3),
                              const SizedBox(width: 4),
                              Text(
                                _category ?? 'Category',
                                style: TextStyle(
                                  color: catEntry.$3,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Metadata pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _previewPill(Icons.signal_cellular_alt_rounded, _difficulty ?? 'Level'),
                        _previewPill(Icons.schedule_rounded, '${_hoursCtrl.text}h'),
                        _previewPill(Icons.language_rounded, _delivery),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Description
                    Text(
                      _descCtrl.text.isEmpty
                          ? 'Your description will appear here...'
                          : _descCtrl.text,
                      style: TextStyle(
                        color: _descCtrl.text.isEmpty ? _textDim : _textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _border),
                            ),
                            child: Text(t, style: const TextStyle(color: _textSecondary, fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ],
                    if (_deliverables.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'DELIVERABLES',
                        style: TextStyle(
                          color: _textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_deliverables.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Text(
                                  '\u2014 ',
                                  style: TextStyle(color: _textDim, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _deliverables[i],
                                  style: const TextStyle(color: _textPrimary, fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Publish bar
        _SectionShell(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _canPublish ? 'Ready to go!' : 'Almost there...',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _canPublish
                          ? 'Your skill listing looks great'
                          : 'Go back and fill in the required fields',
                      style: const TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: _canPublish && !_publishing ? _publish : null,
                  icon: _publishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: Text(
                    _isEditing ? 'Save Changes' : 'Publish Skill',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _canPublish ? _accent : _card,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _card,
                    disabledForegroundColor: _textDim,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildNavButtons(
          onBack: () => setState(() => _step = 1),
          showNext: false,
        ),
      ],
    );
  }

  // ─── Side Panel ────────────────────────────────────────────────────────────

  Widget _buildSidePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Completion card
        _SectionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Completion',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_completionPercent%',
                    style: TextStyle(
                      color: _completionPercent >= 80
                          ? _textPrimary
                          : _textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _completionPercent / 100,
                  minHeight: 6,
                  backgroundColor: _card,
                  valueColor: const AlwaysStoppedAnimation(_accent),
                ),
              ),
              const SizedBox(height: 14),
              _checkItem('Title added', _titleCtrl.text.trim().isNotEmpty),
              _checkItem('Description (20+ chars)', _descCtrl.text.trim().length > 20),
              _checkItem('Category selected', _category != null),
              _checkItem('Difficulty set', _difficulty != null),
              _checkItem('Tags added', _tags.isNotEmpty),
              _checkItem('Deliverables listed', _deliverables.isNotEmpty),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tips
        _SectionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tips for Success',
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              _tipItem('Be specific about outcomes \u2014 "you\'ll build a portfolio site" beats "learn web dev"'),
              _tipItem('Mention your experience level so people know what to expect'),
              _tipItem('Realistic hour estimates build trust'),
              _tipItem('Tags are how people find you \u2014 use 3-5 relevant ones'),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Nav Buttons ───────────────────────────────────────────────────────────

  Widget _buildNavButtons({
    VoidCallback? onBack,
    VoidCallback? onNext,
    bool showNext = true,
  }) {
    return Row(
      children: [
        if (onBack != null)
          TextButton(
            onPressed: onBack,
            style: TextButton.styleFrom(
              foregroundColor: _textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        const Spacer(),
        if (showNext)
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: onNext != null ? _accent : _card,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _card,
              disabledForegroundColor: _textDim,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  // ─── Shared Micro-Widgets ──────────────────────────────────────────────────

  Widget _label(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textDim, fontSize: 14),
        counterText: '',
        filled: true,
        fillColor: _card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderFocus, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _card,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textDim),
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _tagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _tags.remove(tag)),
            child: Icon(Icons.close_rounded, size: 14, color: _textDim),
          ),
        ],
      ),
    );
  }

  Widget _previewPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textDim),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: _textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: done ? _textSuccess : _textDim,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: done ? _textPrimary : _textDim,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u2014 ',
            style: TextStyle(color: _textDim, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Shell ────────────────────────────────────────────────────────────

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}
