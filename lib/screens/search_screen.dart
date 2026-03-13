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
          floating: true, snap: true,
          title: const Text('Search', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list_rounded, color: (_lowStockOnly || _showTemplatesOnly) ? AppTheme.primaryColor : null),
              onPressed: () => _showFilterSheet(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find boxes, items, tags, and locations',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  SearchBarWidget(
                    controller: _searchCtrl,
                    hintText: 'Search by item or box name',
                    onChanged: (_) => _performSearch(),
                    onVoiceTap: _listen,
                    isListening: _isListening,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (provider.allLocations.isNotEmpty) ...[
              Text('Places', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: provider.allLocations.map((loc) {
                    final isSelected = _selectedLocations.contains(loc);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(loc, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (_) => _toggleLocation(loc),
                        selectedColor: AppTheme.primaryColor.withAlpha(38),
                        checkmarkColor: AppTheme.primaryColor,
                        backgroundColor: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(26),
                        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            if (provider.allTags.isNotEmpty) ...[
              Text('Categories & Tags', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: provider.allTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (_) => _toggleTag(tag),
                        selectedColor: AppTheme.accentColor.withAlpha(38),
                        checkmarkColor: AppTheme.accentColor,
                        backgroundColor: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(26),
                        side: BorderSide(color: isSelected ? AppTheme.accentColor : Colors.transparent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ])),
        ),

        if (!isSearching)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.search_rounded,
              title: 'Search your inventory',
              subtitle: 'Find items by name, apply tags, or select locations',
            ),
          )
        else if (_results.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'No results found',
              subtitle: 'Try different keywords or check spelling',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Text('${_results.length} result${_results.length != 1 ? "s" : ""}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(height: 12),
              ..._results.map((r) {
                final box = r['box'];
                final item = r['item'];
                final color = Color(box.colorValue);

                return GlassCard(
                  onTap: () {
                    context.read<InventoryProvider>().accessBox(box);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: box)));
                  },
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.category_rounded, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.inventory_2_outlined, size: 13, color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 4),
                        Text(box.name?.toString() ?? 'Unnamed Box', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined, size: 13, color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 2),
                        Text(box.location?.toString() ?? 'Unknown', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                      ]),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(spacing: 4, runSpacing: 4, children: (item.tags as List<String>?)?.where((t) => t != null).take(3).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                          child: Text(tag.toString(), style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                        )).toList() ?? []),
                      ],
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                      child: Text('×${item.quantity}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 80),
            ])),
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
