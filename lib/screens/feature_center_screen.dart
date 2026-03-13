import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'activity_screen.dart';
import 'ai_vision_screen.dart';
import 'collaborators_screen.dart';
import 'lending_manager_screen.dart';
import 'location_manager_screen.dart';
import 'planner_screen.dart';
import 'qr_scanner_screen.dart';
import 'qr_sheet_screen.dart';
import 'scan_history_screen.dart';
import 'shopping_list_screen.dart';
import 'stats_screen.dart';

class FeatureCenterScreen extends StatelessWidget {
  const FeatureCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Center', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Everything in one place', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Use this center for analytics, automation, collaboration, and advanced tools.'),
                  ],
                ),
              ),
            ),
          ),
          _section(
            context,
            title: 'Operations',
            items: [
              _FeatureItem(
                title: 'Smart Planner',
                subtitle: 'Actionable tasks from low stock, expiry, and lending',
                icon: Icons.task_alt_rounded,
                color: AppTheme.primaryColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen())),
              ),
              _FeatureItem(
                title: 'Scan QR',
                subtitle: 'Instantly open boxes by scanning labels',
                icon: Icons.qr_code_scanner_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
              ),
              _FeatureItem(
                title: 'Scan History',
                subtitle: 'Review previously scanned boxes',
                icon: Icons.history_rounded,
                color: Colors.deepPurple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanHistoryScreen())),
              ),
            ],
          ),
          _section(
            context,
            title: 'Insights',
            items: [
              _FeatureItem(
                title: 'Inventory Analytics',
                subtitle: 'Track capacity, categories, and inventory performance',
                icon: Icons.analytics_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
              ),
              _FeatureItem(
                title: 'Activity Timeline',
                subtitle: 'Complete audit trail of changes in your inventory',
                icon: Icons.timeline_rounded,
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())),
              ),
              _FeatureItem(
                title: 'Shopping List',
                subtitle: 'Auto-generated restock list from low stock items',
                icon: Icons.shopping_cart_rounded,
                color: Colors.pink,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
              ),
            ],
          ),
          _section(
            context,
            title: 'Organize & Share',
            items: [
              _FeatureItem(
                title: 'Locations',
                subtitle: 'Room-wise grouping and navigation of stored boxes',
                icon: Icons.room_rounded,
                color: Colors.indigo,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationManagerScreen())),
              ),
              _FeatureItem(
                title: 'Lending Library',
                subtitle: 'Track borrowed items and return schedules',
                icon: Icons.front_hand_rounded,
                color: Colors.amber,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LendingManagerScreen())),
              ),
              _FeatureItem(
                title: 'Family & Team',
                subtitle: 'Invite and collaborate with members',
                icon: Icons.group_rounded,
                color: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollaboratorsScreen())),
              ),
            ],
          ),
          _section(
            context,
            title: 'Automation',
            items: [
              _FeatureItem(
                title: 'Vision AI',
                subtitle: 'Camera-powered recognition for fast item entry',
                icon: Icons.psychology_rounded,
                color: Colors.redAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiVisionScreen())),
              ),
              _FeatureItem(
                title: 'QR Sheet',
                subtitle: 'Batch-generate printable labels',
                icon: Icons.grid_view_rounded,
                color: Colors.cyan,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrSheetScreen())),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required List<_FeatureItem> items}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                ),
                child: ListTile(
                  onTap: item.onTap,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withAlpha(22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(item.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
