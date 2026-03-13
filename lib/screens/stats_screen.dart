import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Overview Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Items',
                        '${provider.totalItems}',
                        Icons.inventory_2_rounded,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Value',
                        '$currencySymbol${provider.totalInventoryValue.toStringAsFixed(0)}',
                        Icons.payments_rounded,
                        AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Space Index',
                        '${(provider.totalSpaceUsage * 100).toInt()}%',
                        Icons.pie_chart_rounded,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Categories',
                        '${provider.totalCategories}',
                        Icons.grid_view_rounded,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Category Breakdown
                const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildCategoryChart(context, provider),
                const SizedBox(height: 32),

                // 3. Top Boxes
                const Text('Top Boxes (by items)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...provider.topBoxesByItems.map((entry) => _buildBoxRankTile(context, entry.key, entry.value)),
                const SizedBox(height: 32),

                // 4. Value Distribution (Mockup / Simple representation)
                const Text('Value Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildValueInsights(context, provider),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static const String currencySymbol = '₹';

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, InventoryProvider provider) {
    final distribution = provider.categoryDistribution;
    final total = provider.totalBoxes;
    if (total == 0) return const Center(child: Text('No data available'));

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: distribution.entries.map((entry) {
          final percentage = entry.value / total;
          final color = _getCategoryColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${(percentage * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: color.withAlpha(26),
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoxRankTile(BuildContext context, dynamic box, int count) {
    final color = Color(box.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.inventory_2_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(box.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(box.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text('$count items', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildValueInsights(BuildContext context, InventoryProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInsightRow('Highest Value Box', provider.boxes.isEmpty ? 'N/A' : _getHighestValueBox(provider)),
          const Divider(height: 24),
          _buildInsightRow('Low Stock Items', '${provider.lowStockItems.length} items'),
          const Divider(height: 24),
          _buildInsightRow('Items Expiring Soon', '${provider.expiringItems.length} items'),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _getHighestValueBox(InventoryProvider provider) {
    double maxVal = -1;
    String name = 'N/A';
    for (var box in provider.boxes) {
      double val = box.items.fold(0.0, (sum, item) => sum + ((item.price ?? 0) * (item.quantity ?? 1)));
      if (val > maxVal) {
        maxVal = val;
        name = box.name ?? 'Unnamed Box';
      }
    }
    return name;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Clothing': return Colors.pink;
      case 'Tools': return Colors.blueGrey;
      case 'Electronics': return Colors.blue;
      case 'Kitchen': return Colors.orange;
      case 'Documents': return Colors.indigo;
      default: return AppTheme.primaryColor;
    }
  }
}
