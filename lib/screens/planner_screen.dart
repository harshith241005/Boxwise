import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDueDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addTask(InventoryProvider provider) async {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    await provider.addPlannerTask(
      title: title,
      subtitle: 'Manual Task',
      dueDate: _selectedDueDate,
    );

    if (!mounted) return;
    setState(() {
      _taskController.clear();
      _selectedDueDate = null;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<InventoryProvider>();
    final pendingTasks = provider.plannerTasks.where((t) => t['isCompleted'] != true).toList();
    final completedTasks = provider.plannerTasks.where((t) => t['isCompleted'] == true).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text('Intelligence', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withAlpha(20), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => provider.generateSmartPlannerTasks(),
                icon: const Icon(Icons.auto_awesome_rounded),
                tooltip: 'Refresh Intelligence',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Intelligence Hub Carousel ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: PageView(
                controller: PageController(viewportFraction: 0.9),
                children: [
                   _hubCard(
                    'Restock Assistant',
                    'Automatically detects items with low stock.',
                    Icons.inventory_2_rounded,
                    Colors.orange,
                    '${provider.lowStockItems.length} items to shop',
                  ),
                  _hubCard(
                    'Expiry Monitor',
                    'Tracking perishables and expiring boxes.',
                    Icons.history_toggle_off_rounded,
                    Colors.redAccent,
                    '${provider.expiringItems.length} items expiring',
                  ),
                  _hubCard(
                    'Lending Radar',
                    'Keeping track of everything you lent.',
                    Icons.handshake_rounded,
                    Colors.indigo,
                    'Check lending history',
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Bar Section ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                tabs: [
                  Tab(text: 'ONGOING (${pendingTasks.length})'),
                  Tab(text: 'COMPLETED (${completedTasks.length})'),
                ],
              ),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ),
          ),

          // ── Task List ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(pendingTasks, provider, isDark),
                  _buildTaskList(completedTasks, provider, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context, provider),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Action', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _hubCard(String title, String desc, IconData icon, Color color, String footer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withAlpha(40)),
        boxShadow: [
          BoxShadow(color: color.withAlpha(isDark ? 5 : 10), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
          const Spacer(),
          Text(footer, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks, InventoryProvider provider, bool isDark) {
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment_turned_in_rounded,
        title: 'All caught up!',
        subtitle: 'No pending actions in the Intelligence Hub.',
        lottieUrl: 'https://assets9.lottiefiles.com/packages/lf20_yupe9pda.json',
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final type = task['type'] ?? 'custom';
        final isCompleted = task['isCompleted'] == true;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(5) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => provider.togglePlannerTask(task['id'].toString(), !isCompleted),
            leading: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isCompleted ? AppTheme.primaryColor : Colors.grey,
                size: 28,
              ),
              onPressed: () => provider.togglePlannerTask(task['id'].toString(), !isCompleted),
            ),
            title: Text(
              task['title'] ?? 'Action',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  _typeTag(type),
                  if (task['dueDate'] != null) ...[
                    const SizedBox(width: 8),
                    Text(
                       DateFormat('MMM d').format(DateTime.parse(task['dueDate'].toString())),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
              onPressed: () => provider.removePlannerTask(task['id'].toString()),
            ),
          ),
        );
      },
    );
  }

  Widget _typeTag(String type) {
    Color color;
    String label;
    switch (type) {
      case 'restock': color = Colors.orange; label = 'SHOP'; break;
      case 'expiry': color = Colors.redAccent; label = 'EXPIRY'; break;
      case 'lending': color = Colors.indigo; label = 'LENT'; break;
      default: color = AppTheme.primaryColor; label = 'ACTION';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }

  void _showAddTaskSheet(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Action', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              TextField(
                controller: _taskController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
                title: Text(_selectedDueDate == null ? 'Set Due Date' : DateFormat('EEE, MMM d, yyyy').format(_selectedDueDate!)),
                trailing: _selectedDueDate != null 
                  ? IconButton(icon: const Icon(Icons.close), onPressed: () => setSheetState(() => _selectedDueDate = null))
                  : const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (p != null) setSheetState(() => _selectedDueDate = p);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _addTask(provider),
                  child: const Text('Add to Planner', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);
  final TabBar _tabBar;
  final Color backgroundColor;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
