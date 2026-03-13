import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../models/lending_model.dart';
import '../widgets/common_widgets.dart';

class LendingManagerScreen extends StatelessWidget {
  const LendingManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lending Library', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final logs = provider.lendingLogs;
          if (logs.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.front_hand_outlined,
                title: 'Nothing lent out',
                subtitle: 'Track items you lend to family and friends.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _LendingCard(log: log);
            },
          );
        },
      ),
    );
  }
}

class _LendingCard extends StatelessWidget {
  final LendingModel log;
  const _LendingCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = log.status == 'active';
    final color = isActive ? AppTheme.primaryColor : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.itemName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Borrowed by: ${log.borrowerName}',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withAlpha(50)),
                  ),
                  child: Text(
                    log.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              children: [
                _infoTile(Icons.calendar_today_rounded, 'Lent On', DateFormat('MMM dd, yyyy').format(log.lendDate)),
                const Spacer(),
                if (log.returnDate != null)
                  _infoTile(Icons.event_repeat_rounded, 'Due Date', DateFormat('MMM dd, yyyy').format(log.returnDate!))
                else if (log.actualReturnDate != null)
                  _infoTile(Icons.assignment_turned_in_rounded, 'Returned On', DateFormat('MMM dd, yyyy').format(log.actualReturnDate!)),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<InventoryProvider>().returnItem(log),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Mark as Returned'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
