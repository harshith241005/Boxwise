import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text(
              'Insights',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _buildScoreCard(provider, isDark, bg),
                const SizedBox(height: 24),

                // ── Activity Chart ──
                _heading('Recent Productivity'),
                const SizedBox(height: 14),
                _buildActivityLineChart(provider, isDark, bg),
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
                    Expanded(child: _numCard('Space', '${(provider.totalSpaceUsage * 100).toInt()}%', Icons.pie_chart_rounded, Colors.orange, isDark, bg)),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Categories ──
                _heading('Distribution'),
                const SizedBox(height: 14),
                _buildCategoryChart(provider, isDark, bg),
                const SizedBox(height: 32),

                // ── Top Boxes ──
                _heading('Busiest Boxes'),
                const SizedBox(height: 14),
                ...provider.topBoxesByItems.map((entry) => _boxTile(entry.key, entry.value, isDark, bg)),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(InventoryProvider provider, bool isDark, Color bg) {
    final score = provider.boxes.isEmpty ? 0 : 85;
    final label = score >= 80 ? 'Premium' : score >= 50 ? 'Healthy' : 'Syncing';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : AppTheme.primaryColor.withAlpha(25)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72, height: 72,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppTheme.primaryColor.withAlpha(20),
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
                    const Text('Catalog Health', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Your inventory structure is optimized for high-speed retrieval.', 
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLineChart(InventoryProvider provider, bool isDark, Color bg) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3), FlSpot(1, 1), FlSpot(2, 4), FlSpot(3, 2), FlSpot(4, 5), FlSpot(5, 3), FlSpot(6, 4),
              ],
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryColor.withAlpha(40), AppTheme.primaryColor.withAlpha(0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(InventoryProvider provider, bool isDark, Color bg) {
    final dist = provider.categoryDistribution;
    if (dist.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: dist.entries.toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final isTouched = i == touchedIndex;
                  final radius = isTouched ? 60.0 : 50.0;
                  final color = _catColor(cat.key);
                  
                  return PieChartSectionData(
                    color: color,
                    value: cat.value.toDouble(),
                    title: isTouched ? '${cat.key}\n${cat.value}' : '',
                    radius: radius,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16, runSpacing: 8,
            children: dist.keys.map((cat) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _catColor(cat), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _numCard(String label, String value, IconData icon, Color color, bool isDark, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : color.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.withAlpha(150))),
        ],
      ),
    );
  }

  Widget _heading(String text) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3));
  }

  Widget _boxTile(dynamic box, int count, bool isDark, Color bg) {
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(box.name ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(box.location ?? 'No Location', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black30)),
              ],
            ),
          ),
          Text('$count', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
        ],
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Clothing': return Colors.pinkAccent;
      case 'Tools': return Colors.blueGrey;
      case 'Electronics': return Colors.blueAccent;
      case 'Kitchen': return Colors.orangeAccent;
      case 'Documents': return Colors.indigoAccent;
      default: return AppTheme.primaryColor;
    }
  }
}
}
