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
                expandedHeight: 70,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: const Text('Boxes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                actions: const [
                  SizedBox(width: 8),
                ],
              ),

              // Professional Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isSearching = true);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _isSearching 
                            ? AppTheme.primaryColor.withAlpha(100) 
                            : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10))),
                        boxShadow: [
                          BoxShadow(
                            color: _isSearching 
                                ? AppTheme.primaryColor.withAlpha(15) 
                                : Colors.black.withAlpha(isDark ? 15 : 5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 22, color: _isSearching ? AppTheme.primaryColor : (isDark ? Colors.white38 : Colors.black38)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isSearching
                                ? TextField(
                                    controller: _searchCtrl,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'Search boxes, items, locations...',
                                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontWeight: FontWeight.w400),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Text(
                                      'Search boxes, items, locations...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: isDark ? Colors.white30 : Colors.black26,
                                      ),
                                    ),
                                  ),
                          ),
                          if (_isSearching && _searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() { _searchCtrl.clear(); }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                              ),
                            ),
                          if (_isSearching && _searchCtrl.text.isEmpty)
                            GestureDetector(
                              onTap: () => setState(() { _isSearching = false; _searchCtrl.clear(); }),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Compact Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      // Location filter pill
                      GestureDetector(
                        onTap: () => _showLocationPicker(context, provider, isDark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedLocation != 'All'
                                ? AppTheme.primaryColor
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _selectedLocation != 'All'
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10))),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded, size: 14,
                                color: _selectedLocation != 'All' ? Colors.white : (isDark ? Colors.white54 : Colors.black45)),
                              const SizedBox(width: 6),
                              Text(
                                _selectedLocation == 'All' ? 'Location' : _selectedLocation,
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: _selectedLocation != 'All' ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16,
                                color: _selectedLocation != 'All' ? Colors.white70 : (isDark ? Colors.white30 : Colors.black26)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sort pill
                      GestureDetector(
                        onTap: () => _showSortPicker(context, isDark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                              const SizedBox(width: 6),
                              Text(
                                _sortBy.length > 12 ? '${_sortBy.substring(0, 12)}…' : _sortBy,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black54),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? Colors.white30 : Colors.black26),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active filter tag (dismissible)
              if (_selectedLocation != 'All' || _searchCtrl.text.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_selectedLocation != 'All')
                          _activeFilterTag(_selectedLocation, () => setState(() => _selectedLocation = 'All'), isDark),
                        if (_searchCtrl.text.isNotEmpty)
                          _activeFilterTag('"${_searchCtrl.text}"', () => setState(() => _searchCtrl.clear()), isDark),
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
                if (visibleBoxes.length < allFiltered.length)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: TextButton(
                        onPressed: () => setState(() => _loadedCount += 10),
                        child: const Text('Load More', style: TextStyle(fontWeight: FontWeight.w700)),
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

  void _showLocationPicker(BuildContext context, InventoryProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black38),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _locationItem('All', 'All', ctx, isDark),
                  ...provider.allLocations.map((loc) => _locationItem(loc, loc, ctx, isDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationItem(String label, String value, BuildContext ctx, bool isDark) {
    final isSelected = _selectedLocation == value;
    return ListTile(
      onTap: () {
        setState(() => _selectedLocation = value);
        Navigator.pop(ctx);
      },
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(
        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        size: 20,
        color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white30 : Colors.black26),
      ),
      title: Text(label, style: TextStyle(
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        color: isSelected ? AppTheme.primaryColor : null,
      )),
    );
  }

  void _showSortPicker(BuildContext context, bool isDark) {
    final sorts = ['Recently Added', 'Oldest First', 'Name A-Z', 'Name Z-A', 'Item Count (High)', 'Item Count (Low)'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sort by', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black38),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)),
            ...sorts.map((s) {
              final isSelected = _sortBy == s;
              return ListTile(
                onTap: () {
                  setState(() => _sortBy = s);
                  Navigator.pop(ctx);
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                leading: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white30 : Colors.black26),
                ),
                title: Text(s, style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : null,
                )),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _activeFilterTag(String label, VoidCallback onRemove, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
