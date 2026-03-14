import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await DatabaseService.getSetting('profile_name', defaultValue: '');
    final email = await DatabaseService.getSetting('profile_email', defaultValue: '');
    final phone = await DatabaseService.getSetting('profile_phone', defaultValue: '');
    final city = await DatabaseService.getSetting('profile_city', defaultValue: '');
    final bio = await DatabaseService.getSetting('profile_bio', defaultValue: '');

    if (!mounted) return;
    setState(() {
      _nameController.text = name;
      _emailController.text = email;
      _phoneController.text = phone;
      _cityController.text = city;
      _bioController.text = bio;
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    setState(() => _isSaving = true);
    await DatabaseService.setSetting('profile_name', name);
    await DatabaseService.setSetting('profile_email', _emailController.text.trim());
    await DatabaseService.setSetting('profile_phone', _phoneController.text.trim());
    await DatabaseService.setSetting('profile_city', _cityController.text.trim());
    await DatabaseService.setSetting('profile_bio', _bioController.text.trim());

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Saved'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 1),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        child: Column(
          children: [
            // ── Avatar + Name ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withAlpha(20),
                          border: Border.all(color: AppTheme.primaryColor.withAlpha(40), width: 3),
                        ),
                        child: const Icon(Icons.person_rounded, size: 48, color: AppTheme.primaryColor),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: bg, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  if (_cityController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          _cityController.text,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Personal Details ──
            _sectionLabel('PERSONAL'),
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
              ),
              child: Column(
                children: [
                  _field('Name', _nameController, Icons.person_rounded),
                  _divider(isDark),
                  _field('Email', _emailController, Icons.email_rounded),
                  _divider(isDark),
                  _field('Phone', _phoneController, Icons.phone_rounded),
                  _divider(isDark),
                  _field('Location', _cityController, Icons.location_on_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── About ──
            _sectionLabel('ABOUT'),
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
              ),
              child: _field('Bio', _bioController, Icons.edit_rounded, maxLines: 3),
            ),
            const SizedBox(height: 32),

            // ── Save ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey.withAlpha(150),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor.withAlpha(150)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (v) => setState(() {}),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(height: 1, indent: 56, color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6));
  }
}
