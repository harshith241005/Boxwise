import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nfc_service.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'add_item_screen.dart';
import 'qr_code_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
class BoxDetailsScreen extends StatefulWidget {
  final BoxModel box;

  const BoxDetailsScreen({super.key, required this.box});

  @override
  State<BoxDetailsScreen> createState() => _BoxDetailsScreenState();
}

class _BoxDetailsScreenState extends State<BoxDetailsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  void _writeNfcTag(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NfcSheet(isWriting: true, dataToWrite: widget.box.id),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Gradient App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'box_${box.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withAlpha(179),
                            color.withAlpha(77),
                            isDark
                                ? const Color(0xFF0F0F23)
                                : const Color(0xFFF5F5FA),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          box.name?.toString() ?? 'Unnamed Box',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              box.location?.toString() ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.category_outlined,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              box.category?.toString() ?? 'Other',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(provider.selectedItemIds.isNotEmpty ? Icons.close_rounded : Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    if (provider.selectedItemIds.isNotEmpty) {
                      provider.clearSelection();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: provider.selectedItemIds.isNotEmpty 
                  ? Text('${provider.selectedItemIds.length} Selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
                actions: provider.selectedItemIds.isNotEmpty
                ? [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.move_up_rounded, color: Colors.white, size: 20),
                      ),
                      onPressed: () => _showMoveSelectionDialog(context, provider),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor, size: 20),
                      ),
                      onPressed: () => _showBulkItemDeleteConfirm(context, provider),
                    ),
                    const SizedBox(width: 8),
                  ]
                : [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_rounded,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrCodeScreen(box: box),
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    ),
                    onSelected: (val) {
                      if (val == 'pdf') _shareBoxPdf();
                      if (val == 'text') _shareBoxText();
                      if (val == 'label') provider.shareQrLabelPdf(box);
                      if (val == 'nfc') _writeNfcTag(context);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'pdf', child: Text('Share PDF Report')),
                      const PopupMenuItem(value: 'text', child: Text('Share as Text List')),
                      const PopupMenuItem(value: 'label', child: Text('Share Printable QR Label')),
                      const PopupMenuItem(value: 'nfc', child: Text('Write to NFC Tag')),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: () =>
                        _showEditBoxDialog(context, provider),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Item count + stats
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        StatCard(
                          title: 'Items',
                          value: '${box.items.length}',
                          icon: Icons.category_rounded,
                          color: color,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: 'Total Qty',
                          value: '${box.totalQuantity}',
                          icon: Icons.numbers_rounded,
                          color: AppTheme.accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildVolumeVisualizer(context, box, color),
                    const SizedBox(height: 24),

                    // Items header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${box.items.length} total',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withAlpha(102)
                                : Colors.black.withAlpha(102),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Item Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // Items list
              Builder(
                builder: (context) {
                  final filteredItems = widget.box.items.where((i) {
                    if (i == null) return false;
                    final q = _searchQuery.toLowerCase();
                    final nameMatch = (i.name ?? '').toLowerCase().contains(q);
                    final tagsMatch = (i.tags ?? []).any((t) => (t ?? '').toString().toLowerCase().contains(q));
                    return nameMatch || tagsMatch;
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.category_outlined,
                        title: _searchQuery.isNotEmpty ? 'No matches found' : 'No items in this box',
                        subtitle: _searchQuery.isNotEmpty ? 'Try a different search term' : 'Add items to organize inventory',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _ItemCard(
                            item: filteredItems[index],
                            box: box,
                            color: color,
                          );
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverPadding(
                  padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddItemScreen(box: box),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add Item',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: color,
          ),
        );
      },
    );
  }

  void _showMoveSelectionDialog(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Move items to...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.boxes.length,
              itemBuilder: (c, i) {
                final box = provider.boxes[i];
                if (box.id == widget.box.id) return const SizedBox.shrink();
                return ListTile(
                  leading: Icon(Icons.inventory_2_rounded, color: Color(box.colorValue ?? AppTheme.primaryColor.value)),
                  title: Text(box.name ?? 'Unnamed Box'),
                  onTap: () {
                    provider.moveSelectedItems(widget.box.id, box.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Items moved to ${box.name}')));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkItemDeleteConfirm(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${provider.selectedItemIds.length} items from this box?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteSelectedItems(widget.box);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareBoxPdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Box: ${widget.box.name ?? "Unnamed"}'),
              pw.Text('Location: ${widget.box.location ?? "Unknown"}'),
              pw.Text('Category: ${widget.box.category ?? "Other"}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Item Name', 'Quantity', 'Tags'],
                  ...widget.box.items.map((i) => [
                    i.name ?? '',
                    (i.quantity ?? 1).toString(),
                    (i.tags ?? []).join(', ')
                  ])
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${widget.box.name ?? 'inventory'}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Inventory for ${widget.box.name}');
  }

  void _shareBoxText() {
    final box = widget.box;
    final buffer = StringBuffer();
    buffer.writeln('Box: ${box.name ?? "Unnamed"}');
    buffer.writeln('Location: ${box.location ?? "Unknown"}');
    buffer.writeln('--- Items ---');
    for (var item in box.items) {
      buffer.writeln('- ${item.name} (${item.quantity}x)');
    }
    Share.share(buffer.toString(), subject: 'Inventory List');
  }

  void _showEditBoxDialog(
      BuildContext context, InventoryProvider provider) {
    final nameCtrl = TextEditingController(text: widget.box.name ?? '');
    final locationCtrl = TextEditingController(text: widget.box.location ?? '');
    String selectedCategory = widget.box.category ?? 'Other';
    final categories = ['Clothing', 'Tools', 'Documents', 'Kitchen', 'Electronics', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Box'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Box Name',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categories.contains(selectedCategory) ? selectedCategory : 'Other',
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedCategory = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateBox(
                  widget.box,
                  name: nameCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  category: selectedCategory,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildVolumeVisualizer(BuildContext context, BoxModel box, Color color) {
    double fillPercent = (box.capacity ?? 0) > 0 ? (box.items.length / box.capacity!).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 3D Box Mockup
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              children: [
                Transform(
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(-0.5)..rotateY(0.5),
                  alignment: Alignment.center,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      border: Border.all(color: color, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        height: 60 * fillPercent,
                        decoration: BoxDecoration(
                          color: color.withAlpha(128),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Text('${(fillPercent * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Spatial Utilization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  (box.capacity ?? 0) > 0 
                    ? 'Using ${box.items.length} out of ${box.capacity} capacity units.'
                    : 'Total capacity not set for this box.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillPercent,
                    backgroundColor: color.withAlpha(26),
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
  }
}


class _ItemCard extends StatelessWidget {
  final ItemModel item;
  final BoxModel box;
  final Color color;

  const _ItemCard({
    required this.item,
    required this.box,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: AppTheme.errorColor,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content:
                Text('Are you sure you want to delete "${item.name ?? 'this item'}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        final itemName = item.name ?? 'Item';
        provider.deleteItem(box, item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$itemName" deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => provider.undoDeleteItem(),
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          if (provider.selectedItemIds.isNotEmpty) {
            provider.toggleItemSelection(item.id);
          }
        },
        onLongPress: () => provider.toggleItemSelection(item.id),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          color: provider.selectedItemIds.contains(item.id) 
            ? AppTheme.primaryColor.withAlpha(26) 
            : null,
          child: Stack(
            children: [
              Row(
                children: [
                  // Item image or icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? Image.file(
                            File(item.imagePath!),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: color.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.category_rounded,
                              color: color,
                              size: 22,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),

                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name?.toString() ?? 'Unnamed Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((item.quantity ?? 0) <= 1) ...[
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.errorColor),
                              SizedBox(width: 4),
                              Text(
                                'Low Stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (item.description != null && item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 6),
                        if (item.tags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 0,
                            children: item.tags
                                .take(3)
                                .map((tag) => Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),

                  // Quantity and Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Qty',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white.withAlpha(102) : Colors.black.withAlpha(102),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QuantityButton(icon: Icons.remove_rounded, onTap: () => provider.decrementQuantity(box, item)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('${item.quantity}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                            ),
                            _QuantityButton(icon: Icons.add_rounded, onTap: () => provider.incrementQuantity(box, item)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.front_hand_rounded, size: 20),
                            onPressed: () => _showLendDialog(context, provider, item),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Lend Item',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => AddItemScreen(box: box, editItem: item)));
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, size: 20, color: AppTheme.errorColor),
                            onPressed: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   title: const Text('Delete Item'),
                                   content: Text('Delete "${item.name}"?'),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                     TextButton(
                                       onPressed: () {
                                         provider.deleteItem(box, item);
                                         Navigator.pop(context);
                                       },
                                       style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                                       child: const Text('Delete'),
                                     ),
                                   ],
                                 ),
                               );
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (provider.selectedItemIds.contains(item.id))
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withAlpha(26)
            : Colors.black.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}

void _showLendDialog(BuildContext context, InventoryProvider provider, ItemModel item) {
  final nameCtrl = TextEditingController();
  DateTime? selectedDate;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Lend ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Borrower Name',
                hintText: 'Who is borrowing this?',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(selectedDate == null 
                ? 'No Return Date Set' 
                : 'Return By: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              provider.lendItem(
                itemId: item.id,
                itemName: item.name ?? 'Item',
                borrowerName: nameCtrl.text.trim(),
                returnDate: selectedDate,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Marked as lent to ${nameCtrl.text}')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}
