import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'auth/login_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const ProfileScreen({super.key, this.onNavigateToTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  int _watchedCount = 0;
  int _watchlistCount = 0;
  int _likedCount = 0;
  bool _nsfwEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final results = await Future.wait<dynamic>([
      _storageService.getWatched(),
      _storageService.getWatchlist(),
      _storageService.getLiked(),
      _storageService.getNsfwEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _watchedCount = (results[0] as List).length;
      _watchlistCount = (results[1] as List).length;
      _likedCount = (results[2] as List).length;
      _nsfwEnabled = results[3] as bool;
    });
  }

  String _memberSince(User user) {
    final created = user.metadata.creationTime;
    if (created == null) return 'Member since recently';
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
    return 'Member since ${months[created.month - 1]} ${created.day}, ${created.year}';
  }

  String _displayName(User user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    final email = user.email ?? 'Guest User';
    return email.split('@').first;
  }

  Future<void> _toggleNsfw(bool value) async {
    await _storageService.setNsfwEnabled(value);
    if (!mounted) return;
    setState(() => _nsfwEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'NSFW content enabled' : 'NSFW content disabled',
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to sign out?',
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
                'Sign Out',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) return;
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _buildStatsCard(String label, int value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color iconColor = Colors.white70,
    Color textColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white30),
      ),
    );
  }

  Widget _buildSettingsRow() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 24, bottom: 16),
          child: Divider(color: Colors.white10, height: 1),
        ),
        _buildListTile(
          icon: Icons.explicit_outlined,
          title: 'NSFW Content',
          iconColor: Colors.purpleAccent,
          trailing: Switch(
            value: _nsfwEnabled,
            onChanged: _toggleNsfw,
            activeColor: Colors.purpleAccent,
          ),
          onTap: () => _toggleNsfw(!_nsfwEnabled),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              await _loadStats();
              if (mounted) setState(() {});
            },
            leading: const Icon(
              Icons.settings_outlined,
              color: Color(0xFFD4AF37),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    final isGuest = user == null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade900,
                            Colors.indigo.shade900,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isGuest ? '?' : _authService.getUserInitials(user),
                        style: GoogleFonts.cinzelDecorative(
                          color: const Color(0xFFD4AF37),
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avatar customization coming soon!'),
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.black87,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      isGuest ? 'Guest User' : _displayName(user),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isGuest
                          ? 'Explore Kino without an account'
                          : (user.email ?? ''),
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isGuest
                          ? 'Sign in to unlock all features'
                          : _memberSince(user),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isGuest) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.purpleAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sign in to unlock all features',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatsCard(
                    'Watched',
                    _watchedCount,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LibraryScreen(initialTabIndex: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildStatsCard(
                    'Watchlist',
                    _watchlistCount,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LibraryScreen(initialTabIndex: 0),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildStatsCard(
                    'Liked',
                    _likedCount,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Liked movies tab coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              _buildSectionTitle('My Activity'),
              _buildListTile(
                icon: Icons.favorite_border,
                title: 'Watchlist',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LibraryScreen(initialTabIndex: 0),
                    ),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.check_circle_outline,
                title: 'Watched',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LibraryScreen(initialTabIndex: 1),
                    ),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.thumb_up_alt_outlined,
                title: 'Liked Movies',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Liked movies tab coming soon')),
                  );
                },
              ),
              _buildSettingsRow(),
              _buildSectionTitle(isGuest ? 'Sign In' : 'Sign Out'),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isGuest
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        }
                      : _confirmSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isGuest ? Colors.purpleAccent : Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isGuest ? 'Sign In' : 'Sign Out',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
