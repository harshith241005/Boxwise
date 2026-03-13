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
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    if (email.isNotEmpty && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }

    setState(() => _isSaving = true);
    await DatabaseService.setSetting('profile_name', name);
    await DatabaseService.setSetting('profile_email', email);
    await DatabaseService.setSetting('profile_phone', phone);
    await DatabaseService.setSetting('profile_city', city);
    await DatabaseService.setSetting('profile_bio', bio);

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully')));
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
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Profile Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 18),

            _buildInfoCard(
              title: 'Personal Details',
              children: [
                _buildTextField('Full Name *', _nameController, Icons.person_outline_rounded),
                const SizedBox(height: 16),
                _buildTextField('Email Address', _emailController, Icons.email_outlined_rounded),
                const SizedBox(height: 16),
                _buildTextField('Phone Number', _phoneController, Icons.phone_outlined),
                const SizedBox(height: 16),
                _buildTextField('City / Location', _cityController, Icons.location_on_outlined),
                const SizedBox(height: 16),
                _buildTextField('Short Bio', _bioController, Icons.notes_rounded, maxLines: 3),
              ],
            ),
            const SizedBox(height: 24),

            _buildInfoCard(
              title: 'Account Settings',
              children: [
                _buildToggleTile(
                  title: 'Dark Mode',
                  subtitle: 'Use low-light friendly appearance',
                  icon: Icons.dark_mode_rounded,
                  color: Colors.orange,
                  value: provider.isDarkMode,
                  onChanged: (_) => provider.toggleDarkMode(),
                ),
                _buildDivider(),
                _buildOptionTile(
                  'Security', 
                  'Configure app PIN in Settings', 
                  Icons.lock_person_rounded, 
                  Colors.teal,
                ),
                _buildDivider(),
                _buildOptionTile(
                  'Data Sync', 
                  'Cloud sync rollout in upcoming versions', 
                  Icons.cloud_sync_rounded, 
                  Colors.indigo,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildInfoCard(
              title: 'Support',
              children: [
                _buildOptionTile(
                  'Help Center',
                  'Get FAQs and setup guides',
                  Icons.help_outline_rounded, 
                  Colors.purple,
                ),
                _buildDivider(),
                _buildOptionTile(
                  'Privacy Policy',
                  'Understand how your data is used',
                  Icons.privacy_tip_outlined,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _nameController.clear();
                      _emailController.clear();
                      _phoneController.clear();
                      _cityController.clear();
                      _bioController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.grey.withAlpha(200),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: color),
      ],
    );
  }

  Widget _buildOptionTile(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withAlpha(25));
  }
}
