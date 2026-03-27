import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showEditProfileSheet(User user) async {
    final controller = TextEditingController(
      text: user.displayName?.trim().isNotEmpty == true
          ? user.displayName
          : (user.email?.split('@').first ?? ''),
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Display name',
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await user.updateDisplayName(controller.text.trim());
                    await user.reload();
                    if (!mounted) return;
                    Navigator.pop(sheetContext);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Delete Account?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will permanently delete your account and all data. This cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _showComingSoon('Coming soon');
    }
  }

  Widget _buildSectionHeader(String title, {Color color = Colors.purpleAccent}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? trailingText,
    Color iconColor = Colors.purpleAccent,
    Color textColor = Colors.white,
    bool showArrow = true,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailingText != null
            ? Text(
                trailingText,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              )
            : (showArrow
                  ? const Icon(Icons.chevron_right, color: Colors.white30)
                  : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Account', color: const Color(0xFFD4AF37)),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                iconColor: const Color(0xFFD4AF37),
                onTap: user == null
                    ? () => _showComingSoon('Sign in to edit your profile')
                    : () => _showEditProfileSheet(user),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                iconColor: const Color(0xFFD4AF37),
                onTap: () => _showComingSoon('Coming soon'),
              ),
              _buildSettingsTile(
                icon: Icons.shield_outlined,
                title: 'Privacy Settings',
                iconColor: const Color(0xFFD4AF37),
                onTap: () => _showComingSoon('Coming soon'),
              ),
              _buildSectionHeader('Preferences'),
              _buildSettingsTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () => _showComingSoon('Coming soon'),
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                onTap: () => _showComingSoon('Always on - Kino loves the dark'),
              ),
              _buildSettingsTile(
                icon: Icons.language_outlined,
                title: 'Language',
                onTap: () => _showComingSoon('Coming soon'),
              ),
              _buildSectionHeader('About Kino'),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'App Version',
                iconColor: const Color(0xFFD4AF37),
                trailingText: '1.0.0',
                showArrow: false,
              ),
              _buildSettingsTile(
                icon: Icons.star_border,
                title: 'Rate Kino',
                iconColor: const Color(0xFFD4AF37),
                onTap: () => _showComingSoon('Coming soon'),
              ),
              _buildSettingsTile(
                icon: Icons.share_outlined,
                title: 'Share Kino',
                iconColor: const Color(0xFFD4AF37),
                onTap: () {
                  Share.share(
                    'Check out Kino - the AI movie discovery app!',
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                iconColor: const Color(0xFFD4AF37),
                onTap: () => _showComingSoon('Coming soon'),
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                iconColor: const Color(0xFFD4AF37),
                onTap: () => _showComingSoon('Coming soon'),
              ),
              _buildSectionHeader('Danger Zone', color: Colors.redAccent),
              _buildSettingsTile(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                iconColor: Colors.redAccent,
                textColor: Colors.redAccent,
                onTap: _confirmDeleteAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
