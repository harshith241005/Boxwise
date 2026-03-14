import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/inventory_provider.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final lowStockItems = provider.lowStockItems;
    final manualItems = provider.manualShoppingList;
    final totalItems = lowStockItems.length + manualItems.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Shopping List', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (manualItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Manual List',
              onPressed: () => _confirmClear(context, provider),
            ),
        ],
      ),
      body: totalItems == 0
          ? _buildEmptyState()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$totalItems items needed',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  'Ready for your next supply run',
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (manualItems.isNotEmpty) ...[
                  _buildSectionHeader('MANUAL LIST'),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = manualItems[index];
                          return _buildItemCard(context, provider, entry, true);
                        },
                        childCount: manualItems.length,
                      ),
                    ),
                  ),
                ],
                if (lowStockItems.isNotEmpty) ...[
                  _buildSectionHeader('LOW STOCK ALERTS'),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = lowStockItems[index];
                          return _buildItemCard(context, provider, entry, false);
                        },
                        childCount: lowStockItems.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, provider),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add to List', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: totalItems > 0 ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyStateWidget(
        icon: Icons.shopping_basket_outlined,
        title: 'Your list is empty',
        subtitle: 'Add items manually or let low-stock alerts fill this up.',
        lottieUrl: 'https://assets5.lottiefiles.com/packages/lf20_m6cuL6.json',
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, InventoryProvider provider, Map<String, dynamic> entry, bool isManual) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String title = '';
    String subtitle = '';
    IconData icon = Icons.inventory_2_rounded;
    Color iconColor = isManual ? AppTheme.primaryColor : Colors.orangeAccent;

    if (entry['type'] == 'custom') {
      title = entry['name'] ?? 'Custom Item';
      subtitle = 'Personal Note';
      icon = Icons.edit_note_rounded;
    } else {
      final box = entry['box'] as BoxModel?;
      final item = entry['item'] as ItemModel?;
      title = item?.name ?? box?.name ?? 'Unknown';
      subtitle = item != null 
          ? 'In: ${box?.name} • ${box?.location}' 
          : 'Box Location: ${box?.location}';
      icon = item != null ? Icons.category_rounded : Icons.inventory_2_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
        trailing: isManual
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => provider.removeFromShoppingListById(entry['id']),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Qty: ${entry['item']?.quantity ?? 0}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.orangeAccent),
                ),
              ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _shareShoppingList(context),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share List', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: AppTheme.primaryColor.withAlpha(100),
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddItemsSheet(provider: provider),
    );
  }

  void _confirmClear(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Manual List?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will remove all items you manually added.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.clearShoppingList();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _shareShoppingList(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final lowStock = provider.lowStockItems;
    final manual = provider.manualShoppingList;
    
    if (lowStock.isEmpty && manual.isEmpty) return;

    String list = "🛒 Boxvise Shopping List\n";
    list += "─────────────────────\n\n";
    
    if (manual.isNotEmpty) {
      list += "📌 MANUAL LIST\n";
      for (var entry in manual) {
        if (entry['type'] == 'custom') {
          list += "• ${entry['name']}\n";
        } else {
          final box = entry['box'] as BoxModel?;
          final item = entry['item'] as ItemModel?;
          list += "• ${item?.name ?? box?.name} (${box?.location})\n";
        }
      }
      list += "\n";
    }

    if (lowStock.isNotEmpty) {
      list += "⚠️ LOW STOCK ALERTS\n";
      for (var entry in lowStock) {
        final box = entry['box'] as BoxModel?;
        final item = entry['item'] as ItemModel?;
        list += "• ${item?.name} (Qty: ${item?.quantity} in ${box?.name})\n";
      }
    }
    
    list += "\nShared from Boxvise 📦";
    Share.share(list);
  }
}

class _AddItemsSheet extends StatefulWidget {
  final InventoryProvider provider;
  const _AddItemsSheet({required this.provider});

  @override
  State<_AddItemsSheet> createState() => _AddItemsSheetState();
}

class _AddItemsSheetState extends State<_AddItemsSheet> {

  String _mode = 'main'; // main, boxes, items
  BoxModel? _selectedBox;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          if (_mode == 'main') _buildMainOptions(),
          if (_mode == 'boxes') _buildBoxPicker(),
          if (_mode == 'items') _buildItemPicker(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMainOptions() {
    return Column(
      children: [
        const Text('Add to Shopping List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        _optionTile(Icons.inventory_2_rounded, 'Add a Box', 'Add an entire box to shop for', () => setState(() => _mode = 'boxes')),
        _optionTile(Icons.category_rounded, 'Add specific Item', 'Pick an individual item from any box', () => setState(() => _mode = 'boxes')),

      ],
    );
  }

  Widget _buildBoxPicker() {
    return Column(
      children: [
        _sheetHeader('Select Box', () => setState(() => _mode = 'main')),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: widget.provider.boxes.length,
            itemBuilder: (context, index) {
              final box = widget.provider.boxes[index];
              return ListTile(
                leading: Icon(Icons.inventory_2_rounded, color: Color(box.colorValue ?? AppTheme.primaryColor.value)),
                title: Text(box.name ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(box.location ?? 'Unknown'),
                onTap: () {
                  if (_mode == 'boxes') {
                    widget.provider.addToShoppingList(box);
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _selectedBox = box;
                      _mode = 'items';
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemPicker() {
    if (_selectedBox == null) return const SizedBox();
    return Column(
      children: [
        _sheetHeader('Select Item in ${_selectedBox!.name}', () => setState(() => _mode = 'boxes')),
        SizedBox(
          height: 300,
          child: _selectedBox!.items.isEmpty
              ? const Center(child: Text('This box has no items'))
              : ListView.builder(
                  itemCount: _selectedBox!.items.length,
                  itemBuilder: (context, index) {
                    final item = _selectedBox!.items[index];
                    return ListTile(
                      leading: const Icon(Icons.category_rounded),
                      title: Text(item.name ?? 'Unnamed Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.add_rounded, color: AppTheme.primaryColor),
                      onTap: () {
                        widget.provider.addToShoppingList(_selectedBox!, item);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sheetHeader(String title, VoidCallback onBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
