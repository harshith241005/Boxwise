import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'box_details_screen.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  
  // Filters
  final List<String> _selectedTags = [];
  final List<String> _selectedLocations = [];
  String? _selectedBoxId;
  String? _quantityCategory;
  String? _dateFilter;
  String _sortBy = 'name_asc';

  Widget _buildQuickChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, color: isSelected ? Colors.white : AppTheme.primaryColor)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.primaryColor.withAlpha(20),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      ),
    );
  }


  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
  }

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
        selectedBoxId: _selectedBoxId,
        quantityCategory: _quantityCategory,
        dateFilter: _dateFilter,
        sortBy: _sortBy,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedLocations.clear();
      _selectedBoxId = null;
      _quantityCategory = null;
      _dateFilter = null;
      _sortBy = 'name_asc';
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
    final isSearching = _searchCtrl.text.isNotEmpty || _selectedTags.isNotEmpty || _selectedLocations.isNotEmpty || _selectedBoxId != null || _quantityCategory != null || _dateFilter != null;

    return Scaffold(
      body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Search', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          actions: [
            IconButton(
              tooltip: 'Filter',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isSearching && _searchCtrl.text.isEmpty) ? AppTheme.primaryColor.withAlpha(20) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune_rounded, color: (isSearching && _searchCtrl.text.isEmpty) ? AppTheme.primaryColor : null),
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
        


        if (!isSearching && _searchCtrl.text.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 80, color: Colors.grey.withAlpha(50)),
                  const SizedBox(height: 24),
                  const Text(
                    'Find Anything',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Type or use filters',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else if (_results.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.withAlpha(80)),
                const SizedBox(height: 24),
                const Text('Nothing found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey)),
                const SizedBox(height: 12),
                const Text('Try different keywords', style: TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset All Filters'),
                ),
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
                  final box = r['box'] as BoxModel;
                  final item = r['item'] as ItemModel;
                  final color = Color(box.colorValue ?? 0xFF2563EB);

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
                      title: Text(item.name ?? 'Unnamed Item', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.move_to_inbox_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 4),
                              Flexible(child: Text(box.name ?? 'Unnamed Box', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 4),
                              Text(box.location ?? 'Home', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _results.length,
              ),
            ),
          ),
      ],
      ),
    );
  }



  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterModal(
        initialTags: _selectedTags,
        initialLocations: _selectedLocations,
        initialBoxId: _selectedBoxId,
        initialQuantity: _quantityCategory,
        initialDate: _dateFilter,
        initialSort: _sortBy,
        onApply: (tags, locations, boxId, qty, date, sort) {
          setState(() {
            _selectedTags.clear(); _selectedTags.addAll(tags);
            _selectedLocations.clear(); _selectedLocations.addAll(locations);
            _selectedBoxId = boxId;
            _quantityCategory = qty;
            _dateFilter = date;
            _sortBy = sort;
            _performSearch();
          });
        },
        onReset: _clearFilters,
      ),
    );
  }
}

class _FilterModal extends StatefulWidget {
  final List<String> initialTags;
  final List<String> initialLocations;
  final String? initialBoxId;
  final String? initialQuantity;
  final String? initialDate;
  final String initialSort;
  final Function(List<String>, List<String>, String?, String?, String?, String) onApply;
  final VoidCallback onReset;

  const _FilterModal({
    required this.initialTags,
    required this.initialLocations,
    required this.initialBoxId,
    required this.initialQuantity,
    required this.initialDate,
    required this.initialSort,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  String _activeCategory = 'Box';
  late List<String> _tags;
  late List<String> _locations;
  String? _boxId;
  String? _quantity;
  String? _date;
  late String _sort;

  final TextEditingController _boxSearchCtrl = TextEditingController();
  final TextEditingController _tagSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
    _locations = List.from(widget.initialLocations);
    _boxId = widget.initialBoxId;
    _quantity = widget.initialQuantity;
    _date = widget.initialDate;
    _sort = widget.initialSort;
    
    _boxSearchCtrl.addListener(() => setState(() {}));
    _tagSearchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _boxSearchCtrl.dispose();
    _tagSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<InventoryProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                TextButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Body
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withAlpha(20) : Colors.grey.withAlpha(10),
                    border: Border(right: BorderSide(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5))),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildCategoryItem('Box', Icons.inventory_2_rounded),
                      _buildCategoryItem('Tags', Icons.sell_rounded),
                      _buildCategoryItem('Quantity', Icons.analytics_rounded),
                      _buildCategoryItem('Timeline', Icons.event_note_rounded),
                      _buildCategoryItem('Sort By', Icons.sort_rounded),
                    ],
                  ),
                ),
                
                // Right Panel
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildOptionsPanel(provider, isDark),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onApply(_tags, _locations, _boxId, _quantity, _date, _sort);
                  Navigator.pop(context);
                },
                child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    final isSelected = _activeCategory == title;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          border: isSelected ? Border(left: BorderSide(color: AppTheme.primaryColor, width: 4)) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppTheme.primaryColor : Colors.grey),
            const SizedBox(height: 4),
            Text(title, 
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsPanel(InventoryProvider provider, bool isDark) {
    switch (_activeCategory) {
      case 'Box':
        final filteredBoxes = provider.boxes.where((b) => 
          (b.name ?? '').toLowerCase().contains(_boxSearchCtrl.text.toLowerCase())).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchField(_boxSearchCtrl, 'Search boxes...'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredBoxes.length,
                itemBuilder: (ctx, i) {
                  final b = filteredBoxes[i];
                  final isSel = _boxId == b.id;
                  return _buildFilterRow(b.name ?? 'Unnamed', isSel, () {
                    setState(() => _boxId = isSel ? null : b.id);
                  });
                },
              ),
            ),
          ],
        );
      case 'Tags':
        final filteredTags = provider.allTags.where((t) => 
          t.toLowerCase().contains(_tagSearchCtrl.text.toLowerCase())).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchField(_tagSearchCtrl, 'Search tags...'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTags.length,
                itemBuilder: (ctx, i) {
                  final t = filteredTags[i];
                  final isSel = _tags.contains(t);
                  return _buildFilterRow('#$t', isSel, () {
                    setState(() {
                      if (isSel) _tags.remove(t);
                      else _tags.add(t);
                    });
                  });
                },
              ),
            ),
          ],
        );

      case 'Quantity':
         return Column(
          children: [
            _buildOptionTile('All Items', null, _quantity),
            _buildOptionTile('Low stock (≤1)', 'low', _quantity),
            _buildOptionTile('Out of stock', 'out', _quantity),
            _buildOptionTile('1-5 items', '1-5', _quantity),
            _buildOptionTile('5-20 items', '5-20', _quantity),
            _buildOptionTile('20+ items', '20+', _quantity),
          ],
        );
      case 'Timeline':
        return Column(
          children: [
            _buildOptionTile('All Time', null, _date),
            _buildOptionTile('Today', 'today', _date),
            _buildOptionTile('Last 7 days', '7days', _date),
            _buildOptionTile('Last 30 days', '30days', _date),
            _buildOptionTile('Older items', 'older', _date),
          ],
        );
      case 'Sort By':
        final sortOptions = {
          'name_asc': 'Name A-Z',
          'name_desc': 'Name Z-A',
          'newest': 'Recently Added',
          'oldest': 'Oldest First',
          'qty_high': 'Quantity High → Low',
          'qty_low': 'Quantity Low → High',
        };
        return Column(
          children: sortOptions.entries.map((e) => _buildOptionTile(e.value, e.key, _sort)).toList(),
        );
      default:
        return const Center(child: Text('Select a category'));
    }
  }

  Widget _buildSearchField(TextEditingController ctrl, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFilterRow(String label, bool isSelected, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20) : null,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildOptionTile(String label, String? value, String? groupValue) {
    final isSelected = value == groupValue;
    return _buildFilterRow(label, isSelected, () {
      setState(() {
        if (_activeCategory == 'Quantity') _quantity = value;
        else if (_activeCategory == 'Timeline') _date = value;
        else if (_activeCategory == 'Sort By') _sort = value ?? 'name_asc';
      });
    });
  }
}
