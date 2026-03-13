import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareShoppingList(context),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final lowStockItems = provider.lowStockItems;

          if (lowStockItems.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.shopping_cart_outlined,
                title: 'All stocked up!',
                subtitle: 'Items with quantity of 1 or less will appear here.',
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have ${lowStockItems.length} items that need replenishment.',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lowStockItems.length,
                  itemBuilder: (context, index) {
                    final data = lowStockItems[index];
                    final item = data['item'];
                    final box = data['box'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1E293B) 
                          : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orangeAccent.withAlpha(50)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_basket_rounded, color: Colors.orangeAccent, size: 20),
                        ),
                        title: Text(item.name ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('In: ${box.name} • Room: ${box.location}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Qty: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
                              onPressed: () {
                                provider.incrementQuantity(box, item);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _shareShoppingList(context),
            icon: const Icon(Icons.local_shipping_rounded),
            label: const Text('Export to Shopping App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  void _shareShoppingList(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final items = provider.lowStockItems;
    if (items.isEmpty) return;

    String list = "📦 Boxwise Shopping List:\n\n";
    for (var i in items) {
      list += "• ${i['item'].name} (Low: ${i['item'].quantity})\n";
    }
    
    Share.share(list);
  }
}
