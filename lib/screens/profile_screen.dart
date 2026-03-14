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

    setState(() => _isSaving = true);
    await DatabaseService.setSetting('profile_name', name);
    await DatabaseService.setSetting('profile_email', email);
    await DatabaseService.setSetting('profile_phone', phone);
    await DatabaseService.setSetting('profile_city', city);
    await DatabaseService.setSetting('profile_bio', bio);

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Profile updated successfully!'),
      behavior: SnackBarBehavior.floating,
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
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
               background: _buildProfileHeader(context, provider),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                children: [
                   _buildStatRow(provider),
                   const SizedBox(height: 32),
                   
                   _buildSectionTitle('ACCOUNT INFORMATION'),
                   _buildInfoCard([
                     _buildEditableField('Full Name', _nameController, Icons.person_rounded),
                     _buildDivider(),
                     _buildEditableField('Email Address', _emailController, Icons.email_rounded),
                     _buildDivider(),
                     _buildEditableField('Phone Number', _phoneController, Icons.phone_android_rounded),
                     _buildDivider(),
                     _buildEditableField('Location', _cityController, Icons.location_on_rounded),
                     _buildDivider(),
                     _buildEditableField('Biography', _bioController, Icons.description_rounded, maxLines: 3),
                   ]),
                   
                   const SizedBox(height: 40),
                   SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: ElevatedButton(
                       onPressed: _isSaving ? null : _saveProfile,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primaryColor,
                         foregroundColor: Colors.white,
                         elevation: 8,
                         shadowColor: AppTheme.primaryColor.withAlpha(100),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                       ),
                       child: _isSaving 
                         ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                         : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, InventoryProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(200),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, size: 60, color: AppTheme.primaryColor),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isEmpty ? 'Boxvisor User' : _nameController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          Text(
            _emailController.text.isEmpty ? 'Member since 2024' : _emailController.text,
            style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(200), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(InventoryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('BOXES', '${provider.totalBoxes}'),
          _buildStatDivider(),
          _buildStatItem('ITEMS', '${provider.totalItems}'),
          _buildStatDivider(),
          _buildStatItem('ACTIVITY', '${provider.activities.length}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.withAlpha(50));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (v) => setState(() {}),
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, IconData icon, Color color, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppTheme.primaryColor),
    );
  }

  Widget _buildOptionTile(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, color: Colors.grey.withAlpha(30));
  }
}
