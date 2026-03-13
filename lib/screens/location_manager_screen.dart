import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LocationManagerScreen extends StatelessWidget {
  const LocationManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms & Locations', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final heatmap = provider.locationHeatmap;
          final locations = provider.allLocations;

          if (locations.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.map_outlined,
                title: 'No locations yet',
                subtitle: 'Add boxes and specify their location to see rooms here.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              final itemCount = heatmap[loc] ?? 0;
              final boxCount = provider.boxes.where((b) => b.location == loc).length;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withAlpha(20),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(51)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.room_rounded, color: AppTheme.primaryColor),
                  ),
                  title: Text(loc, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('$boxCount Boxes • $itemCount Items'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    // Navigate to a filtered view of boxes
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
