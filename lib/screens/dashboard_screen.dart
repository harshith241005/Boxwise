import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'create_box_screen.dart';
import 'box_details_screen.dart';
import 'stats_screen.dart';
import 'qr_scanner_screen.dart';
import 'search_screen.dart';
import 'ai_vision_screen.dart';
import 'activity_screen.dart';
import 'boxes_screen.dart';
import 'settings_screen.dart';
import 'add_item_screen.dart';
import 'qr_code_screen.dart';
import 'qr_sheet_screen.dart';
import 'shopping_list_screen.dart';
import 'collaborators_screen.dart';
import 'profile_screen.dart';
import 'feature_center_screen.dart';
import 'planner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  int get activeIndex {
    if (_currentIndex == 0) return 0;
    if (_currentIndex == 1) return 1;
    if (_currentIndex == 2) return 0; // fallback although 2 opens dialog
    if (_currentIndex == 3) return 2;
    if (_currentIndex == 4) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _HomeTab(),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Quick Add', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _quickActionBtn(context, Icons.inventory_2_rounded, 'Add Box', AppTheme.primaryColor, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen()));
                  }),
                  _quickActionBtn(context, Icons.checklist_rounded, 'Add Item', Colors.indigo, () {
                    Navigator.pop(ctx);
                    final provider = context.read<InventoryProvider>();
                    _showAddItemListDialog(context, provider);
                  }),
                  _quickActionBtn(context, Icons.qr_code_scanner_rounded, 'Scan QR', AppTheme.accentColor, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                  }),
                  _quickActionBtn(context, Icons.psychology_outlined, 'AI Vision', Colors.indigo, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiVisionScreen()));
                  }),
                  _quickActionBtn(context, Icons.import_export_rounded, 'Import Data', AppTheme.warningColor, () async {
                    Navigator.pop(ctx);
                    final provider = context.read<InventoryProvider>();
                    _showExportDialog(context, provider);
                  }),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _quickActionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryColor);
              }
              return TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black54);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(size: 24, color: AppTheme.primaryColor);
              }
              return IconThemeData(size: 22, color: isDark ? Colors.white54 : Colors.black54);
            }),
          ),
          child: NavigationBar(
            height: 75,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (index == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
              } else {
                setState(() => _currentIndex = index);
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_rounded),
                selectedIcon: const Icon(Icons.dashboard_rounded),
                label: provider.translate('Dashboard'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.search_rounded),
                label: provider.translate('Search'),
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(6), 
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Colors.white),
                ),
                label: provider.translate('Scan'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.inventory_2_rounded),
                label: provider.translate('Boxes'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_rounded),
                label: provider.translate('Settings'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportDialog(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose format to export your inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.exportToCSV();
            },
            child: const Text('CSV'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.exportToPDF();
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }
}

void _showAddItemListDialog(BuildContext context, InventoryProvider provider) {
  if (provider.boxes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please create a box first.')));
    return;
  }
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Select a box to add item to', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.boxes.length,
            itemBuilder: (c, i) {
              final box = provider.boxes[i];
              return ListTile(
                leading: Icon(Icons.inventory_2_rounded, color: Color(box.colorValue ?? AppTheme.primaryColor.value)),
                title: Text(box.name?.toString() ?? 'Unnamed Box'),
                subtitle: Text(box.location?.toString() ?? 'Unknown'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddItemScreen(box: box)));
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

// ===== HOME TAB =====
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  void _showGeneratedQRs(BuildContext context, InventoryProvider provider) {
    if (provider.boxes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No boxes available.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Generated Box QRs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.boxes.length,
              itemBuilder: (c, i) {
                final box = provider.boxes[i];
                return ListTile(
                  leading: Icon(Icons.qr_code_2_rounded, color: Color(box.colorValue ?? AppTheme.primaryColor.value)),
                  title: Text(box.name?.toString() ?? 'Unnamed Box'),
                  subtitle: Text(box.uuid ?? 'No UUID'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => QrCodeScreen(box: box)));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildAlertCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMapping(BuildContext context, InventoryProvider provider) {
    final heatmap = provider.locationHeatmap;
    final locations = provider.allLocations;
    if (locations.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context, 
          'Rooms & Locations',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            primary: false,
            padding: const EdgeInsets.symmetric(vertical: 12),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locations.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5)),
            itemBuilder: (context, index) {
              final loc = locations[index];
              final boxCount = provider.boxes.where((b) => (b.location ?? '').trim() == loc).length;
              final itemCount = heatmap[loc] ?? 0;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.room_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(loc, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                subtitle: Text('$boxCount boxes • $itemCount items', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BoxesScreen()));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              toolbarHeight: 70,
              title: const Text('Boxvise', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Profile'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const Text(
                      'Welcome Home',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: isDark ? AppTheme.primaryColor.withAlpha(200) : AppTheme.primaryColor),
                            const SizedBox(width: 16),
                            Text('Search your inventory...', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Icon(Icons.tune_rounded, size: 20, color: isDark ? Colors.white24 : Colors.black26),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _sectionHeader(
                      context, 
                      'Inventory Overview', 
                      trailing: 'View More',
                      onTrailingTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        children: [
                          _buildHorizontalStatCard(context, 'Total Quantity', '${provider.totalQuantity}', Icons.stacked_bar_chart_rounded, Colors.green),
                          const SizedBox(width: 12),
                          _buildHorizontalStatCard(context, 'Space Index', '${(provider.totalSpaceUsage * 100).toInt()}%', Icons.donut_large_rounded, Colors.orange),
                          const SizedBox(width: 12),
                          _buildHorizontalStatCard(context, 'Boxes', '${provider.totalBoxes}', Icons.inventory_2_rounded, AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          _buildHorizontalStatCard(context, 'Items', '${provider.totalItems}', Icons.category_rounded, AppTheme.accentColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildCategoryCloud(context, provider),
                    const SizedBox(height: 12),

                    if (provider.expiringItems.isNotEmpty || provider.lowStockItems.isNotEmpty) ...[
                      _sectionHeader(context, 'Attention Required'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            ...provider.expiringItems.map((e) => _buildAlertCard(
                                  context,
                                  'Expiring Soon',
                                  '${e['item'].name} (${e['days']}d)',
                                  Icons.timer_rounded,
                                  Colors.redAccent,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: e['box']))),
                                )),
                            ...provider.lowStockItems.map((s) => _buildAlertCard(
                                  context,
                                  'Low Stock',
                                  '${s['item'].name} in ${s['box'].name}',
                                  Icons.warning_amber_rounded,
                                  Colors.orangeAccent,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    _buildLocationMapping(context, provider),
                    const SizedBox(height: 32),

                    const Text('Quick Hub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.3,
                      children: [
                        _buildactionTile(context, 'Create Box', Icons.inventory_2_rounded, AppTheme.primaryColor, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen()));
                        }),
                        _buildactionTile(context, 'Add Item', Icons.checklist_rounded, AppTheme.accentColor, () {
                          _showAddItemListDialog(context, provider);
                        }),
                        _buildactionTile(context, 'Scan QR', Icons.qr_code_scanner_rounded, Colors.teal, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                        }),
                        _buildactionTile(context, 'Generate QR', Icons.qr_code_2_rounded, Colors.deepOrange, () {
                          _showGeneratedQRs(context, provider);
                        }),
                        _buildactionTile(context, 'View All QRs', Icons.grid_view_rounded, Colors.purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const QrSheetScreen()));
                        }),
                        _buildactionTile(context, 'Shop List', Icons.shopping_cart_rounded, Colors.orange, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
                        }),
                        _buildactionTile(context, 'Family', Icons.group_rounded, Colors.indigo, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CollaboratorsScreen()));
                        }),
                        _buildactionTile(context, 'Analyze AI', Icons.psychology_rounded, Colors.pink, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiVisionScreen()));
                        }),
                        _buildactionTile(context, 'Planner', Icons.task_alt_rounded, Colors.blue, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen()));
                        }),
                        _buildactionTile(context, 'All Features', Icons.widgets_rounded, Colors.green, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FeatureCenterScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _activityTimeline(context, provider),
                    const SizedBox(height: 24),

                    _sectionHeader(context, 'Box Overview', trailing: '${provider.totalBoxes} boxes'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            if (provider.boxes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'No boxes yet',
                  subtitle: 'Tap + to create your first storage box',
                  action: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Box'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final box = provider.boxes[index];
                      return Hero(
                        tag: 'box_${box.id}',
                        child: BoxCard(
                          name: box.name?.toString() ?? 'Unnamed Box',
                          location: box.location?.toString() ?? 'Unknown',
                          itemCount: box.items.length,
                          capacity: box.capacity ?? 0,
                          color: Color(box.colorValue ?? AppTheme.primaryColor.value),
                          isSelected: provider.selectedBoxIds.contains(box.id),
                          onTap: () {
                            if (provider.isMultiSelectMode) {
                              provider.toggleBoxSelection(box.id);
                            } else {
                              provider.accessBox(box);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: box)));
                            }
                          },
                          onQrTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrCodeScreen(box: box))),
                          onLongPress: () => provider.toggleBoxSelection(box.id),
                        ),
                      );
                    },
                    childCount: provider.boxes.length,
                  ),
                ),
              ),
            ],

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(40), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 30 : 20),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildactionTile(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 40 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, {String? trailing, VoidCallback? onTrailingTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing, 
              style: TextStyle(
                fontSize: 13, 
                color: AppTheme.primaryColor, 
                fontWeight: FontWeight.w600
              )
            ),
          ),
      ],
    );
  }

  Widget _activityTimeline(BuildContext context, InventoryProvider provider) {
    final activities = provider.activities.take(5).toList();
    if (activities.isEmpty) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context, 
          'Recent Activity', 
          trailing: 'View All',
          onTrailingTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(isDark ? 51 : 13), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: activities.asMap().entries.map((entry) {
              final activity = entry.value;
              final isLast = entry.key == activities.length - 1;
              return Column(
                children: [
                  ListTile(
                    onTap: () {},
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getActivityColor(activity.type).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getActivityIcon(activity.type), color: _getActivityColor(activity.type), size: 18),
                    ),
                    title: Text(activity.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    subtitle: Text(activity.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                    trailing: Text(_timeAgo(activity.timestamp), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                  ),
                  if (!isLast) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10))),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'box_created': return Icons.add_box_rounded;
      case 'item_added': return Icons.add_circle_outline_rounded;
      case 'item_moved': return Icons.move_up_rounded;
      case 'box_deleted':
      case 'item_deleted': return Icons.delete_outline_rounded;
      case 'box_scanned': return Icons.qr_code_scanner_rounded;
      default: return Icons.history_rounded;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'box_created':
      case 'item_added': return Colors.green;
      case 'item_moved': return Colors.blue;
      case 'box_deleted':
      case 'item_deleted': return AppTheme.errorColor;
      case 'box_scanned': return Colors.purple;
      default: return AppTheme.primaryColor;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _showDeleteDialog(BuildContext context, InventoryProvider provider, dynamic box) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Box'),
        content: Text('Are you sure you want to delete "${box.name}" and all its items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final boxName = box.name ?? 'Box';
                await provider.deleteBox(box);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$boxName" deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => provider.undoDeleteBox(),
                      ),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCloud(BuildContext context, InventoryProvider provider) {
    final categories = provider.topCategories;
    if (categories.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = categories.first.value == 0 ? 1 : categories.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Top Categories'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
          ),
          child: Column(
            children: categories.asMap().entries.map((entry) {
              final cat = entry.value;
              final index = entry.key;
              final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal];
              final color = colors[index % colors.length];
              final percentage = (cat.value / maxValue).clamp(0.0, 1.0);
              final isLast = index == categories.length - 1;
              
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoxesScreen())),
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withAlpha(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: color.withAlpha(36), shape: BoxShape.circle),
                            child: Center(
                              child: Text('${index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(cat.key, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(8)),
                            child: Text('${cat.value}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6,
                          color: color,
                          backgroundColor: color.withAlpha(28),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ===== RECENT BOX CHIP =====
class _RecentBoxChip extends StatelessWidget {
  final dynamic box;

  const _RecentBoxChip({required this.box});

  @override
  Widget build(BuildContext context) {
    final color = Color(box.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.read<InventoryProvider>().accessBox(box);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoxDetailsScreen(box: box),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withAlpha(isDark ? 64 : 51),
              color.withAlpha(isDark ? 26 : 20),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withAlpha(51),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: color,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  box.name?.toString() ?? 'Unnamed Box',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${box.items.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withAlpha(128)
                        : Colors.black.withAlpha(128),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
