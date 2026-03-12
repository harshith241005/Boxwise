import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'scan_history_screen.dart';

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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            expandedHeight: 140,
            floating: false,
            pinned: true,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Appearance Section
                  _buildSectionHeader('APPEARANCE'),
                  _buildSectionCard([
                    _buildSwitchTile(
                      title: 'Dark Mode',
                      subtitle: 'Easier on the eyes in low light',
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.amber,
                      value: provider.isDarkMode,
                      onChanged: (val) => provider.toggleDarkMode(),
                    ),
                    _buildDivider(),
                    _buildLanguageTile(provider),
                  ]),

                  // Security Section
                  _buildSectionHeader('SECURITY'),
                  _buildSectionCard([
                    _buildSwitchTile(
                      title: 'App Lock',
                      subtitle: 'Secure your inventory with a PIN',
                      icon: Icons.lock_person_rounded,
                      iconColor: Colors.blueAccent,
                      value: provider.usePinLock,
                      onChanged: (val) => _handlePinToggle(context, provider, val),
                    ),
                  ]),

                  // Data Management Section
                  _buildSectionHeader('DATA MANAGEMENT'),
                  _buildSectionCard([
                    _buildSettingTile(
                      title: 'Export to CSV',
                      subtitle: 'Download spreadsheet data',
                      icon: Icons.table_chart_rounded,
                      iconColor: Colors.green,
                      onTap: () => provider.exportToCSV(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Export to PDF',
                      subtitle: 'Create a printable report',
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: Colors.redAccent,
                      onTap: () => provider.exportToPDF(),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Import CSV',
                      subtitle: 'Bulk add from external source',
                      icon: Icons.upload_file_rounded,
                      iconColor: Colors.orange,
                      onTap: () => _handleImport(context, provider),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Scan History',
                      subtitle: 'View previously scanned codes',
                      icon: Icons.history_rounded,
                      iconColor: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanHistoryScreen())),
                    ),
                  ]),

                  // Interaction Section
                  _buildSectionHeader('INTERACTION'),
                  _buildSectionCard([
                    _buildSettingTile(
                      title: 'Share the App',
                      subtitle: 'Recommend Boxwise to friends',
                      icon: Icons.share_rounded,
                      iconColor: AppTheme.primaryColor,
                      onTap: () => Share.share('Check out Boxwise - The smartest inventory manager! https://github.com/harshith241005/Boxwise'),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Rate on App Store',
                      subtitle: 'Your feedback helps us grow',
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      onTap: () => _launchUrl('https://github.com/harshith241005/Boxwise'),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      title: 'Help & Support',
                      subtitle: 'Contact our support team',
                      icon: Icons.support_agent_rounded,
                      iconColor: Colors.teal,
                      onTap: () => _launchUrl('mailto:support@boxwise.app'),
                    ),
                  ]),

                  // Roadmap Section
                  _buildSectionHeader('ROADMAP'),
                  _buildSectionCard([
                    _buildComingSoonTile(
                      title: 'Cloud Sync',
                      subtitle: 'Access across all your devices',
                      icon: Icons.cloud_sync_rounded,
                      status: 'Q3 2024',
                    ),
                    _buildDivider(),
                    _buildComingSoonTile(
                      title: 'Team Access',
                      subtitle: 'Collaborate with teammates',
                      icon: Icons.people_alt_rounded,
                      status: 'Dev Phase',
                    ),
                  ]),

                  // Danger Zone Section
                  _buildSectionHeader('DANGER ZONE'),
                  _buildSectionCard([
                    _buildSettingTile(
                      title: 'Factory Reset',
                      subtitle: 'Careful! Wipes everything',
                      icon: Icons.delete_forever_rounded,
                      iconColor: AppTheme.errorColor,
                      textColor: AppTheme.errorColor,
                      onTap: () => _showResetConfirmation(context, provider),
                    ),
                  ]),

                  const SizedBox(height: 48),
                  
                  // App Footer
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text('Boxwise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0)),
                        const SizedBox(height: 4),
                        Text('Version $_version ($_buildNumber)', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                        const SizedBox(height: 24),
                        Text('Built with ❤️ for better organization', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black26)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey.withAlpha(180),
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
        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
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
      color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5),
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
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
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
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.alpha153),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(InventoryProvider provider) {
    final languageNames = {
      'en': 'English',
      'hi': 'Hindi',
      'te': 'Telugu',
    };

    return InkWell(
      onTap: () => _showLanguagePicker(context, provider),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.translate_rounded, color: Colors.blue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Language', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(languageNames[provider.language] ?? 'English', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.unfold_more_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildLanguageOption(context, provider, 'en', 'English'),
            _buildLanguageOption(context, provider, 'hi', 'Hindi'),
            _buildLanguageOption(context, provider, 'te', 'Telugu'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, InventoryProvider provider, String code, String name) {
    final isSelected = provider.language == code;
    return ListTile(
      onTap: () {
        provider.setLanguage(code);
        Navigator.pop(context);
      },
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
    );
  }

  void _handlePinToggle(BuildContext context, InventoryProvider provider, bool value) {
    if (value) {
      _showSetPinDialog(context, provider);
    } else {
      provider.togglePinLock(false);
    }
  }

  void _showSetPinDialog(BuildContext context, InventoryProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Security PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a 4-digit PIN to lock your inventory data.'),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                fillColor: Colors.black.withAlpha(5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 4) {
                provider.setPin(controller.text);
                provider.togglePinLock(true);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lock App'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, InventoryProvider provider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      await provider.importFromCSV(result.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory Import Successful!')));
      }
    }
  }

  void _showResetConfirmation(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Everything?'),
        content: const Text('This will delete ALL your boxes, items, and settings. This action is permanent and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.resetAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App has been reset to factory state.')));
            },
            child: const Text('RESET ALL', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
