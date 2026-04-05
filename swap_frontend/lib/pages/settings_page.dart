import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/b2c_auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/app_sidebar.dart';
import 'home_page.dart';
import 'landing_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _deleting = false;

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HomePage.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: HomePage.line),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: HomePage.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure? This will permanently delete your profile, all your skills, and associated data. This cannot be undone.',
          style: TextStyle(color: HomePage.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    final uid = B2CAuthService.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _deleting = true);
    try {
      await ProfileService().deleteProfile(uid);
      await B2CAuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSidebar(active: 'Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: HomePage.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your account settings',
                      style: TextStyle(color: HomePage.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Danger zone
                    Container(
                      decoration: BoxDecoration(
                        color: HomePage.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(HugeIcons.strokeRoundedAlert02, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Danger Zone',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Once you delete your account, there is no going back. All your skills, profile data, and search index entries will be permanently removed.',
                            style: TextStyle(color: HomePage.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 42,
                            child: FilledButton.icon(
                              onPressed: _deleting ? null : _confirmDeleteAccount,
                              icon: _deleting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(HugeIcons.strokeRoundedDelete01, size: 18),
                              label: Text(_deleting ? 'Deleting...' : 'Delete Account'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
