import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'scan_history_screen.dart';
import 'feature_center_screen.dart';
import 'planner_screen.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Settings',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionHeader('PROFILE'),
                   _buildSectionCard([
                    _buildSettingTile(
                      title: 'User Profile',
                      subtitle: '',
                      icon: Icons.person_rounded,
                      iconColor: AppTheme.primaryColor,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    ),
                   ]),

                   _buildSectionHeader('APPEARANCE'),
                   _buildSectionCard([
                    _buildSwitchTile(
                      title: 'Dark Mode',
                      subtitle: '',
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.amber,
                      value: provider.isDarkMode,
                      onChanged: (val) => provider.toggleDarkMode(),
                    ),
                    _buildDivider(),
                    _buildThemeColorTile(context, provider),
                   ]),


                   _buildSectionHeader('DATA & CLOUD'),
                   _buildSectionCard([
                    _buildSettingTile(
                      title: 'Export PDF',
                      subtitle: '',
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: Colors.redAccent,
                      onTap: () => provider.exportToPDF(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Import CSV',
                      subtitle: '',
                      icon: Icons.upload_file_rounded,
                      iconColor: Colors.orange,
                      onTap: () => _handleImport(context, provider),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Export CSV',
                      subtitle: '',
                      icon: Icons.table_chart_rounded,
                      iconColor: Colors.green,
                      onTap: () => provider.exportToCSV(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Backup Data',
                      subtitle: '',
                      icon: Icons.cloud_upload_rounded,
                      iconColor: Colors.indigo,
                      onTap: () {},
                    ),
                   ]),

                   _buildSectionHeader('HELP & SUPPORT'),
                   _buildSectionCard([
                    _buildSettingTile(
                      title: 'Help Guide',
                      subtitle: '',
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.teal,
                      onTap: () => _launchUrl('https://boxvise.app/help'),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'FAQ',
                      subtitle: 'Frequently asked questions',
                      icon: Icons.quiz_rounded,
                      iconColor: Colors.blue,
                      onTap: () => _launchUrl('https://boxvise.app/faq'),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Report Bug',
                      subtitle: 'Help us improve the app',
                      icon: Icons.bug_report_rounded,
                      iconColor: Colors.orange,
                      onTap: () => _launchUrl('mailto:bugs@bugs.boxvise.app'),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Share App',
                      subtitle: 'Spread the word about Boxvise',
                      icon: Icons.share_rounded,
                      iconColor: Colors.purple,
                      onTap: () => Share.share('Check out Boxvise! https://boxvise.app'),
                    ),
                   ]),

                   _buildSectionHeader('ABOUT'),
                   _buildSectionCard([
                    _buildSettingTile(
                      title: 'About App',
                      subtitle: 'Learn more about Boxvise',
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.indigo,
                      onTap: () => _launchUrl('https://boxvise.app/about'),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Rate Us',
                      subtitle: 'Rate us on the Play Store',
                      icon: Icons.star_rate_rounded,
                      iconColor: Colors.amber,
                      onTap: () => _launchUrl('https://play.google.com'),
                    ),
                   ]),

                   _buildSectionHeader('DANGER ZONE'),
                   _buildSectionCard([
                    _buildSettingTile(
                      title: 'Reset Data',
                      subtitle: 'Permanent factory reset of the app',
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      onTap: () => _showResetConfirmation(context, provider),
                    ),
                   ]),

                   const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10, top: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textColor)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, String subtitle, IconData icon, Color color) {
    return _buildSettingTile(title: title, subtitle: subtitle, icon: icon, iconColor: color, onTap: () {});
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
          Switch.adaptive(value: value, activeColor: AppTheme.primaryColor, onChanged: onChanged),
        ],
      ),
    );
  }


  Future<void> _handleImport(BuildContext context, InventoryProvider provider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      await provider.importFromCSV(result.files.single.path!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import complete!')));
    }
  }

  void _showResetConfirmation(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factory Reset?'),
        content: const Text('All data will be permanently erased.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { provider.resetAllData(); Navigator.pop(ctx); }, child: const Text('ERASE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildThemeColorTile(BuildContext context, InventoryProvider provider) {
    return _buildSettingTile(
      title: 'Theme', 
      subtitle: '', 
      icon: Icons.palette_rounded, 
      iconColor: provider.primaryColor, 
      onTap: () => _showThemeColorPicker(context, provider)
    );
  }

  void _showThemeColorPicker(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pick Global Accent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: AppTheme.boxColors.length,
              itemBuilder: (context, index) {
                final color = AppTheme.boxColors[index];
                final isSelected = provider.primaryColor.value == color.value;
                return GestureDetector(
                  onTap: () { provider.setPrimaryColor(color); Navigator.pop(ctx); },
                  child: Container(
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isSelected ? Border.all(color: Colors.white, width: 3) : null),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
