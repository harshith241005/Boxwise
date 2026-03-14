import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'box_details_screen.dart';
import 'create_box_screen.dart';
import 'qr_code_screen.dart';
import '../models/box_model.dart';

class BoxesScreen extends StatefulWidget {
  const BoxesScreen({super.key});

  @override
  State<BoxesScreen> createState() => _BoxesScreenState();
}

class _BoxesScreenState extends State<BoxesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  
  String _selectedLocation = 'All';
  String _sortBy = 'Recently Added';
  int _loadedCount = 10;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<InventoryProvider>();
      if (_loadedCount < provider.boxes.length) {
        setState(() {
          _loadedCount += 10;
        });
      }
    }
  }

  List<BoxModel> _getFilteredBoxes(InventoryProvider provider) {
    List<BoxModel> boxes = List.from(provider.boxes);

    // Search
    if (_isSearching && _searchCtrl.text.isNotEmpty) {
      final query = _searchCtrl.text.toLowerCase();
      boxes = boxes.where((b) {
        final matchesBox = (b.name ?? '').toLowerCase().contains(query);
        final matchesLoc = (b.location ?? '').toLowerCase().contains(query);
        final matchesItem = b.items.any((i) => (i.name ?? '').toLowerCase().contains(query));
        return matchesBox || matchesLoc || matchesItem;
      }).toList();
    }

    // Location Filter
    if (_selectedLocation != 'All') {
      boxes = boxes.where((b) => b.location == _selectedLocation).toList();
    }

    // Sorting
    switch (_sortBy) {
      case 'Recently Added':
        boxes.sort((a, b) => (b.createdDate).compareTo(a.createdDate));
        break;
      case 'Oldest First':
        boxes.sort((a, b) => (a.createdDate).compareTo(b.createdDate));
        break;
      case 'Name A-Z':
        boxes.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'Name Z-A':
        boxes.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
        break;
      case 'Item Count (High)':
        boxes.sort((a, b) => b.items.length.compareTo(a.items.length));
        break;
      case 'Item Count (Low)':
        boxes.sort((a, b) => a.items.length.compareTo(b.items.length));
        break;
    }

    return boxes;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final allFiltered = _getFilteredBoxes(provider);
        final visibleBoxes = allFiltered.take(_loadedCount).toList();

        return Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: _isSearching 
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search boxes, items, locations...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (_) => setState(() {}),
                    )
                  : const Text('Boxes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
                    onPressed: () => setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) _searchCtrl.clear();
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () {
                      // Optionally open a more detailed filter sheet, 
                      // but we have quick filters below. Let's just scroll to the filters for now.
                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Filter',
                              value: _selectedLocation,
                              items: ['All', ...provider.allLocations],
                              onChanged: (val) => setState(() => _selectedLocation = val!),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Sort',
                              value: _sortBy,
                              items: [
                                'Recently Added', 
                                'Oldest First', 
                                'Name A-Z', 
                                'Name Z-A', 
                                'Item Count (High)', 
                                'Item Count (Low)'
                              ],
                              onChanged: (val) => setState(() => _sortBy = val!),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.layers_rounded, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Showing 1–${visibleBoxes.length} of ${allFiltered.length} boxes',
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.w800, 
                                color: AppTheme.primaryColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (allFiltered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No boxes found',
                    subtitle: 'Try changing your filters or create a new box.',
                    action: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Box'),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final box = visibleBoxes[index];
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
                      childCount: visibleBoxes.length,
                    ),
                  ),
                ),
                
                // Pagination Info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          'Showing ${visibleBoxes.length} of ${allFiltered.length} boxes',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38),
                        ),
                        if (visibleBoxes.length < allFiltered.length) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() => _loadedCount += 10),
                            child: const Text('Load More'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen())),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.primaryColor),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }
}
