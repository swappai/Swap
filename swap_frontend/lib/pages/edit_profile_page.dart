import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../services/b2c_auth_service.dart';
import '../services/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color bg = Color(0xFF0A0A0B);
  static const Color card = Color(0xFF0F1115);
  static const Color surfaceAlt = Color(0xFF12141B);
  static const Color textPrimary = Color(0xFFEAEAF2);
  static const Color textMuted = Color(0xFFB6BDD0);
  static const Color line = Color(0xFF1F2937);
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentSoft = Color(0xFF2D1B69);

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();

  String? _timezone;
  String _accountType = 'person';
  bool _dmOpen = true;
  bool _emailUpdates = true;
  bool _showCity = false;

  // Preserved from loaded profile — passed through unchanged on save
  String _skillsToOffer = '';
  String _servicesNeeded = '';

  Uint8List? _avatarBytes;
  String? _avatarFilename;
  String? _existingPhotoUrl;

  bool _loading = true;
  bool _saving = false;

  static const _timezones = <String>[
    'UTC−08:00 (PST)',
    'UTC−06:00 (CST)',
    'UTC−05:00 (EST)',
    'UTC±00:00 (UTC)',
    'UTC+01:00 (CET)',
  ];

  // Structured services-needed rows for editing
  final List<_ServiceEntry> _needs = [];


  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _bio.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = B2CAuthService.instance.currentUser;
    if (user == null) return;
    final data = await ProfileService().getProfile(user.uid);
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _fullName.text = (data['full_name'] ?? data['display_name'] ?? '').toString();
        _username.text = (data['username'] ?? '').toString();
        _bio.text = (data['bio'] ?? '').toString();
        _city.text = (data['city'] ?? '').toString();
        _timezone = data['timezone'] as String?;
        _accountType = (data['account_type'] ?? 'person').toString();
        _dmOpen = data['dm_open'] == true;
        _emailUpdates = data['email_updates'] == true;
        _showCity = data['show_city'] == true;
        _skillsToOffer = (data['skills_to_offer'] ?? '').toString();
        _servicesNeeded = (data['services_needed'] ?? '').toString();
        _existingPhotoUrl = data['photo_url'] as String?;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop Photo', toolbarColor: bg, toolbarWidgetColor: Colors.white),
        IOSUiSettings(title: 'Crop Photo'),
        if (kIsWeb) WebUiSettings(context: context),
      ],
    );
    if (cropped != null && mounted) {
      final bytes = await cropped.readAsBytes();
      final filename = cropped.path.split('/').last;
      setState(() {
        _avatarBytes = bytes;
        _avatarFilename = filename;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = B2CAuthService.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Rebuild services_needed from structured entries if any were added
      final needsText = _needs.isNotEmpty
          ? _needs.map((e) => e.level.isNotEmpty ? '${e.name} (${e.level})' : e.name).join(', ')
          : _servicesNeeded;

      // Upload photo first so we have the URL for upsert
      String? photoUrl = _existingPhotoUrl;
      if (_avatarBytes != null) {
        try {
          photoUrl = await ProfileService().uploadPhoto(user.uid, _avatarBytes!, _avatarFilename ?? 'avatar.jpg');
        } catch (e) {
          debugPrint('Photo upload error (non-fatal): $e');
        }
      }

      await ProfileService().upsertProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: _fullName.text.trim().isNotEmpty
            ? _fullName.text.trim()
            : (user.email ?? ''),
        skillsToOffer: _skillsToOffer, // pass through unchanged
        servicesNeeded: needsText,
        bio: _bio.text.trim(),
        city: _city.text.trim(),
        fullName: _fullName.text.trim(),
        username: _username.text.trim(),
        timezone: _timezone ?? '',
        dmOpen: _dmOpen,
        emailUpdates: _emailUpdates,
        showCity: _showCity,
        accountType: _accountType,
        photoUrl: photoUrl,
        timeout: const Duration(seconds: 12),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      Navigator.pop(context, true); // true = changed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        surface: card,
        background: bg,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0, backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary, centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true, fillColor: surfaceAlt,
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: line, width: 1)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accent, width: 1.6)),
      ),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStatePropertyAll(accentSoft),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Avatar
                            Center(
                              child: GestureDetector(
                                onTap: _pickAvatar,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF9F67FF), Color(0xFF7C3AED)],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 44,
                                        backgroundColor: surfaceAlt,
                                        foregroundImage: _avatarBytes != null
                                            ? MemoryImage(_avatarBytes!)
                                            : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                                                ? NetworkImage(_existingPhotoUrl!) as ImageProvider
                                                : null),
                                        child: _avatarBytes == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty)
                                            ? const Text('U', style: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700))
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Tap to change photo', style: TextStyle(color: textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name + Username
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _fullName,
                                  style: const TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(labelText: 'Full Name *'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _username,
                                  style: const TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(labelText: 'Username *'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    return RegExp(r'^[a-zA-Z0-9_\.]{3,20}$').hasMatch(v.trim()) ? null : '3-20 chars, letters/numbers/._';
                                  },
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),

                            // Bio
                            TextFormField(
                              controller: _bio,
                              style: const TextStyle(color: textPrimary),
                              minLines: 3, maxLines: 5,
                              decoration: const InputDecoration(labelText: 'Bio'),
                            ),
                            const SizedBox(height: 12),

                            // City + Timezone
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _city,
                                  style: const TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'City *',
                                    prefixIcon: Icon(Icons.location_on_outlined, color: textMuted),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _timezones.contains(_timezone) ? _timezone : null,
                                  dropdownColor: surfaceAlt,
                                  items: _timezones.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: textPrimary)))).toList(),
                                  onChanged: (v) => setState(() => _timezone = v),
                                  decoration: const InputDecoration(labelText: 'Timezone *'),
                                  validator: (v) => v == null ? 'Select timezone' : null,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),

                            // Account Type
                            Text('Account Type', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                child: _AccountTypeOption(
                                  icon: HugeIcons.strokeRoundedUser,
                                  label: 'Person',
                                  selected: _accountType == 'person',
                                  onTap: () => setState(() => _accountType = 'person'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AccountTypeOption(
                                  icon: HugeIcons.strokeRoundedStore01,
                                  label: 'Business',
                                  selected: _accountType == 'business',
                                  onTap: () => setState(() => _accountType = 'business'),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),

                            // Services needed (display current, allow editing)
                            Text('Services You Need', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('What you want to learn or get help with', style: TextStyle(color: textMuted, fontSize: 13)),
                            const SizedBox(height: 8),
                            if (_servicesNeeded.isNotEmpty && _needs.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: line),
                                ),
                                child: Text(_servicesNeeded, style: const TextStyle(color: textPrimary)),
                              ),
                            if (_needs.isNotEmpty)
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: [
                                  for (int i = 0; i < _needs.length; i++)
                                    Chip(
                                      label: Text('${_needs[i].name} (${_needs[i].level})', style: const TextStyle(color: textPrimary)),
                                      backgroundColor: surfaceAlt,
                                      side: const BorderSide(color: line),
                                      deleteIcon: const Icon(Icons.close, size: 16, color: textMuted),
                                      onDeleted: () => setState(() => _needs.removeAt(i)),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 24),

                            // Preferences
                            Text('Preferences', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: const Text('Allow direct messages', style: TextStyle(color: textPrimary)),
                              value: _dmOpen,
                              onChanged: (v) => setState(() => _dmOpen = v),
                            ),
                            SwitchListTile(
                              title: const Text('Email me helpful updates', style: TextStyle(color: textPrimary)),
                              value: _emailUpdates,
                              onChanged: (v) => setState(() => _emailUpdates = v),
                            ),
                            SwitchListTile(
                              title: const Text('Show my city on profile', style: TextStyle(color: textPrimary)),
                              value: _showCity,
                              onChanged: (v) => setState(() => _showCity = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ServiceEntry {
  final String name;
  final String category;
  final String level;
  _ServiceEntry({required this.name, required this.category, required this.level});
}

class _AccountTypeOption extends StatelessWidget {
  const _AccountTypeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? _EditProfilePageState.accentSoft
                : _EditProfilePageState.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _EditProfilePageState.accent
                  : _EditProfilePageState.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? const Color(0xFF9F67FF) : _EditProfilePageState.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _EditProfilePageState.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(HugeIcons.strokeRoundedCheckmarkCircle01, size: 18, color: const Color(0xFF9F67FF)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
