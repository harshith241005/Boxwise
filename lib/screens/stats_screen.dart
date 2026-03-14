import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final subtle = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Clean AppBar ──
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text(
              'Insights',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Score Card ──
                const SizedBox(height: 8),
                _buildScoreCard(provider, isDark, bg),
                const SizedBox(height: 24),

                // ── Quick Numbers ──
                Row(
                  children: [
                    Expanded(child: _numCard('Boxes', '${provider.totalBoxes}', Icons.inventory_2_rounded, AppTheme.primaryColor, isDark, bg)),
                    const SizedBox(width: 12),
                    Expanded(child: _numCard('Items', '${provider.totalItems}', Icons.category_rounded, Colors.indigo, isDark, bg)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numCard('Value', '₹${provider.totalInventoryValue.toStringAsFixed(0)}', Icons.payments_rounded, Colors.green, isDark, bg)),
                    const SizedBox(width: 12),
                    Expanded(child: _numCard('Storage', '${(provider.totalSpaceUsage * 100).toInt()}%', Icons.pie_chart_rounded, Colors.orange, isDark, bg)),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Categories ──
                _heading('Categories'),
                const SizedBox(height: 14),
                _buildCategories(context, provider, isDark, bg),
                const SizedBox(height: 32),

                // ── Top Boxes ──
                _heading('Busiest Boxes'),
                const SizedBox(height: 14),
                ...provider.topBoxesByItems.map((entry) => _boxTile(entry.key, entry.value, isDark, bg)),
                const SizedBox(height: 32),

                // ── Alerts ──
                _heading('Alerts'),
                const SizedBox(height: 14),
                _alertsCard(provider, isDark, bg),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Score Card ──
  Widget _buildScoreCard(InventoryProvider provider, bool isDark, Color bg) {
    final score = provider.boxes.isEmpty ? 0 : 85;
    final label = score >= 80 ? 'Great' : score >= 50 ? 'Good' : 'Needs work';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : AppTheme.primaryColor.withAlpha(25)),
        boxShadow: [
          if (!isDark) BoxShadow(color: AppTheme.primaryColor.withAlpha(12), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          // Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppTheme.primaryColor.withAlpha(25),
                  color: AppTheme.primaryColor,
                ),
              ),
              Text('$score%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Organization', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tag your items to improve this score.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Number Card ──
  Widget _numCard(String label, String value, IconData icon, Color color, bool isDark, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : color.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }

  // ── Heading ──
  Widget _heading(String text) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3));
  }

  // ── Categories ──
  Widget _buildCategories(BuildContext context, InventoryProvider provider, bool isDark, Color bg) {
    final dist = provider.categoryDistribution;
    final total = provider.totalBoxes;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
        child: Center(child: Text('No data yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
      ),
      child: Column(
        children: dist.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final pct = cat.value / total;
          final color = _catColor(cat.key);
          final isLast = i == dist.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('${(pct * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: color.withAlpha(18),
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Box Tile ──
  Widget _boxTile(dynamic box, int count, bool isDark, Color bg) {
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.inventory_2_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(box.name ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(box.location ?? 'No location', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Alerts ──
  Widget _alertsCard(InventoryProvider provider, bool isDark, Color bg) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
      ),
      child: Column(
        children: [
          _alertRow('Low stock', '${provider.lowStockItems.length}', Icons.arrow_downward_rounded, Colors.orange, isDark),
          Divider(height: 1, indent: 52, color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
          _alertRow('Expiring soon', '${provider.expiringItems.length}', Icons.schedule_rounded, Colors.redAccent, isDark),
          Divider(height: 1, indent: 52, color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
          _alertRow('Top box', provider.boxes.isEmpty ? '—' : _topBox(provider), Icons.star_rounded, Colors.amber, isDark),
        ],
      ),
    );
  }

  Widget _alertRow(String label, String value, IconData icon, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  String _topBox(InventoryProvider provider) {
    double maxVal = -1;
    String name = '—';
    for (var box in provider.boxes) {
      double val = box.items.fold(0.0, (sum, item) => sum + ((item.price ?? 0) * (item.quantity ?? 1)));
      if (val > maxVal) { maxVal = val; name = box.name ?? 'Unnamed'; }
    }
    return name;
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Clothing': return Colors.pink;
      case 'Tools': return Colors.blueGrey;
      case 'Electronics': return Colors.blue;
      case 'Kitchen': return Colors.orange;
      case 'Documents': return Colors.indigo;
      default: return AppTheme.primaryColor;
    }
  }
}
