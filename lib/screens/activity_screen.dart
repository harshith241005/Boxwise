import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/activity_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final activities = provider.activities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              // Option to clear logs in future
            },
          ),
        ],
      ),
      body: activities.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final isLast = index == activities.length - 1;
                return _buildActivityTile(context, activity, isLast);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.withAlpha(51)),
          const SizedBox(height: 16),
          const Text('No recent activity', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, ActivityModel activity, bool isLast) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _getActivityColor(activity.type).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getActivityIcon(activity.type), color: _getActivityColor(activity.type), size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withAlpha(51),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          DateFormat('HH:mm').format(activity.timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(activity.subtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(activity.timestamp),
                      style: TextStyle(fontSize: 11, color: AppTheme.primaryColor.withAlpha(180), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'box_created': return Icons.add_box_rounded;
      case 'item_added': return Icons.post_add_rounded;
      case 'box_scanned': return Icons.qr_code_scanner_rounded;
      case 'item_updated': return Icons.edit_note_rounded;
      case 'item_lent': return Icons.front_hand_rounded;
      case 'item_returned': return Icons.assignment_turned_in_rounded;
      case 'collab_invited': return Icons.group_add_rounded;
      case 'data_export': return Icons.ios_share_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'box_created': return AppTheme.primaryColor;
      case 'item_added': return AppTheme.accentColor;
      case 'box_scanned': return Colors.orange;
      case 'item_updated': return Colors.blue;
      case 'item_lent': return Colors.amber;
      case 'item_returned': return Colors.green;
      case 'collab_invited': return Colors.indigo;
      case 'data_export': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
