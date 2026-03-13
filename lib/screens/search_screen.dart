import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'box_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  final List<String> _selectedTags = [];
  final List<String> _selectedLocations = [];

  bool _lowStockOnly = false;
  bool _showTemplatesOnly = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch() {
    final provider = context.read<InventoryProvider>();
    setState(() {
      _results = provider.searchItems(
        _searchCtrl.text,
        selectedTags: _selectedTags,
        selectedLocations: _selectedLocations,
        lowStockOnly: _lowStockOnly,
        showTemplatesOnly: _showTemplatesOnly,
      );
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _performSearch();
    });
  }

  void _toggleLocation(String loc) {
    setState(() {
      if (_selectedLocations.contains(loc)) {
        _selectedLocations.remove(loc);
      } else {
        _selectedLocations.add(loc);
      }
      _performSearch();
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _searchCtrl.text = val.recognizedWords;
            _performSearch();
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<InventoryProvider>();
    final isSearching = _searchCtrl.text.isNotEmpty || _selectedTags.isNotEmpty || _selectedLocations.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Search', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          actions: [
            IconButton(
              tooltip: 'Advanced Filters',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (_lowStockOnly || _showTemplatesOnly) ? AppTheme.primaryColor.withAlpha(20) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune_rounded, color: (_lowStockOnly || _showTemplatesOnly) ? AppTheme.primaryColor : null),
              ),
              onPressed: () => _showFilterSheet(context),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SearchBarWidget(
                controller: _searchCtrl,
                hintText: 'Search boxes, items, or tags...',
                onChanged: (_) => _performSearch(),
                onVoiceTap: _listen,
                isListening: _isListening,
              ),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.allLocations.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.room_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 6),
                      Text('LOCATION FILTERS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: provider.allLocations.map((loc) {
                        final isSelected = _selectedLocations.contains(loc);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(loc),
                            selected: isSelected,
                            onSelected: (_) => _toggleLocation(loc),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            selectedColor: AppTheme.primaryColor.withAlpha(40),
                            checkmarkColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              fontSize: 13, 
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white70 : Colors.black87)
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5))),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                if (provider.allTags.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.tag_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 6),
                      Text('CATEGORY FILTERS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: provider.allTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (_) => _toggleTag(tag),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            selectedColor: AppTheme.accentColor.withAlpha(40),
                            checkmarkColor: AppTheme.accentColor,
                            labelStyle: TextStyle(
                              fontSize: 13, 
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppTheme.accentColor : (isDark ? Colors.white70 : Colors.black87)
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: isSelected ? AppTheme.accentColor : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5))),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (!isSearching)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(15), shape: BoxShape.circle),
                  child: Icon(Icons.search_rounded, size: 64, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 24),
                const Text('Search Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('What are you looking for today?', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          )
        else if (_results.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withAlpha(100)),
                const SizedBox(height: 24),
                const Text('No Items Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Try different keywords or filters', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final r = _results[index];
                  final box = r['box'];
                  final item = r['item'];
                  final color = Color(box.colorValue);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      onTap: () {
                        context.read<InventoryProvider>().accessBox(box);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: box)));
                      },
                      leading: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(Icons.inventory_2_rounded, color: color, size: 28),
                        ),
                      ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.move_to_inbox_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 4),
                              Text(box.name?.toString() ?? 'Unnamed Box', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 4),
                              Text(box.location?.toString() ?? 'Home', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                            ],
                          ),
                          if (item.tags != null && (item.tags as List).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: (item.tags as List).take(3).map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(6)),
                                child: Text('#$t', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withAlpha(isSelected ? 255 : 30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _results.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Low Stock Items Only'),
                subtitle: const Text('Items with quantity 1 or less'),
                value: _lowStockOnly,
                onChanged: (v) {
                  setModalState(() => _lowStockOnly = v);
                  setState(() => _lowStockOnly = v);
                  _performSearch();
                },
              ),
              SwitchListTile(
                title: const Text('Show Templates Only'),
                subtitle: const Text('Only items saved as templates'),
                value: _showTemplatesOnly,
                onChanged: (v) {
                  setModalState(() => _showTemplatesOnly = v);
                  setState(() => _showTemplatesOnly = v);
                  _performSearch();
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setModalState(() { _lowStockOnly = false; _showTemplatesOnly = false; });
                  setState(() { _lowStockOnly = false; _showTemplatesOnly = false; });
                  _performSearch();
                  Navigator.pop(ctx);
                },
                child: const Center(child: Text('Reset All')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
