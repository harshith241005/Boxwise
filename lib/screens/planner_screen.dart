import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDueDate;
  String _filter = 'open';

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> tasks) {
    if (_filter == 'all') return tasks;
    if (_filter == 'completed') {
      return tasks.where((task) => task['isCompleted'] == true).toList();
    }
    return tasks.where((task) => task['isCompleted'] != true).toList();
  }

  Future<void> _addTask(InventoryProvider provider) async {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    await provider.addPlannerTask(
      title: title,
      subtitle: 'Custom task',
      dueDate: _selectedDueDate,
    );

    if (!mounted) return;
    setState(() {
      _taskController.clear();
      _selectedDueDate = null;
    });
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'restock':
        return Colors.orange;
      case 'expiry':
        return Colors.redAccent;
      case 'lending':
        return Colors.indigo;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _prettyType(String type) {
    switch (type) {
      case 'restock':
        return 'Restock';
      case 'expiry':
        return 'Expiry';
      case 'lending':
        return 'Lending';
      default:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Planner', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Refresh smart tasks',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => context.read<InventoryProvider>().generateSmartPlannerTasks(),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final tasks = _applyFilter(provider.plannerTasks);
          final completedCount = provider.plannerTasks.where((task) => task['isCompleted'] == true).length;

          return RefreshIndicator(
            onRefresh: provider.generateSmartPlannerTasks,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today\'s Focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        '${provider.plannerTasks.length - completedCount} pending • $completedCount completed',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _taskController,
                        decoration: InputDecoration(
                          hintText: 'Add a custom task',
                          prefixIcon: const Icon(Icons.add_task_rounded),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDueDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (picked != null && mounted) {
                                setState(() => _selectedDueDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_month_rounded),
                          ),
                        ),
                        onSubmitted: (_) => _addTask(provider),
                      ),
                      if (_selectedDueDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Due: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addTask(provider),
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Add Task'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Open'),
                      selected: _filter == 'open',
                      onSelected: (_) => setState(() => _filter = 'open'),
                    ),
                    ChoiceChip(
                      label: const Text('Completed'),
                      selected: _filter == 'completed',
                      onSelected: (_) => setState(() => _filter = 'completed'),
                    ),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == 'all',
                      onSelected: (_) => setState(() => _filter = 'all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.task_alt_rounded, size: 42, color: AppTheme.primaryColor),
                        SizedBox(height: 10),
                        Text('No tasks in this filter', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )
                else
                  ...tasks.map((task) {
                    final dueDate = DateTime.tryParse((task['dueDate'] ?? '').toString());
                    final isCompleted = task['isCompleted'] == true;
                    final type = (task['type'] ?? 'custom').toString();
                    final color = _typeColor(type);

                    return Dismissible(
                      key: ValueKey(task['id']),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => provider.removePlannerTask(task['id'].toString()),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                        ),
                        child: CheckboxListTile(
                          value: isCompleted,
                          onChanged: (value) => provider.togglePlannerTask(task['id'].toString(), value ?? false),
                          title: Text(
                            task['title']?.toString() ?? 'Task',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((task['subtitle'] ?? '').toString().isNotEmpty)
                                Text(task['subtitle'].toString()),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _prettyType(type),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                                    ),
                                  ),
                                  if (dueDate != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Due ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}
