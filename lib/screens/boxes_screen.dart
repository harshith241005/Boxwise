import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'box_details_screen.dart';
import 'create_box_screen.dart';
import 'qr_code_screen.dart';

class BoxesScreen extends StatefulWidget {
  const BoxesScreen({super.key});

  @override
  State<BoxesScreen> createState() => _BoxesScreenState();
}

class _BoxesScreenState extends State<BoxesScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) { // Actually we also need to get categories, locations, tags dynamically. Let's keep it simple for now, filter just visual buttons
        final boxes = provider.boxes.where((box) {
          if (_selectedFilter == 'All') return true;
          final cat = box.category?.toString() ?? '';
          final loc = box.location?.toString() ?? '';
          final itemsMatch = box.items?.any((i) => i.tags?.any((t) => t.toString() == _selectedFilter) ?? false) ?? false;
          return cat == _selectedFilter || loc == _selectedFilter || itemsMatch;
        }).toList();

        final filterOptions = <String>{
          'All', 
          ...provider.allLocations, 
          ...provider.categoryDistribution.keys
        }.toList();

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                title: provider.isMultiSelectMode 
                  ? Text('${provider.selectedBoxIds.length} selected')
                  : const Text(
                      'All Boxes',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                actions: [
                  if (provider.isMultiSelectMode)
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
                      onPressed: () => _showBulkDeleteConfirm(context, provider),
                    ),
                  if (provider.isMultiSelectMode)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => provider.clearSelection(),
                    ),
                ],
              ),
              // Filter Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: filterOptions.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              if (boxes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No boxes found',
                    subtitle: 'Try changing your filter or add a box.',
                    action: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Box'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverReorderableGrid(
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderBoxes(oldIndex, newIndex);
                    },
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: boxes.length,
                    itemBuilder: (context, index) {
                      final box = boxes[index];
                      return BoxCard(
                        key: ValueKey(box.id),
                        name: box.name?.toString() ?? 'Unnamed Box',
                        location: box.location?.toString() ?? 'Unknown',
                        itemCount: box.items.length,
                        capacity: box.capacity ?? 0,
                        color: Color(box.colorValue ?? AppTheme.primaryColor.value),
                        isSelected: provider.selectedBoxIds.contains(box.id),
                        imagePath: box.imagePath,
                        isFavorite: box.isFavorite,
                        onFavoriteTap: () => provider.toggleFavoriteBox(box),
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
                      );
                    },
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'boxes_add',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen())),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  void _showBulkDeleteConfirm(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${provider.selectedBoxIds.length} boxes and all their items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteSelectedBoxes();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boxes deleted')));
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
