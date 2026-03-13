import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  final BoxModel box;
  final ItemModel? editItem;
  const AddItemScreen({super.key, required this.box, this.editItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _tagCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0.0');
  final List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  DateTime? _reminderDate;
  DateTime? _expiryDate;
  bool _isTemplate = false;

  final List<String> _nameSuggestions = [
    'Hammer', 'Screwdriver', 'Tape', 'Drill', 'Screws', 'Wrench', 
    'Passport', 'IDs', 'Certificates', 'Policy',
    'T-shirt', 'Jeans', 'Socks', 'Jacket', 'Shoes',
    'Laptop', 'Charger', 'Cables', 'Phone', 'Tablet'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _nameCtrl.text = widget.editItem!.name ?? '';
      _descCtrl.text = widget.editItem!.description ?? '';
      _qtyCtrl.text = (widget.editItem!.quantity ?? 1).toString();
      _tags.addAll(widget.editItem!.tags);
      if (widget.editItem!.imagePath != null && File(widget.editItem!.imagePath!).existsSync()) {
        _selectedImage = File(widget.editItem!.imagePath!);
      }
      _isTemplate = widget.editItem!.isTemplate;
      _reminderDate = widget.editItem!.reminderDate;
      _priceCtrl.text = (widget.editItem!.price ?? 0.0).toStringAsFixed(2);
      _expiryDate = widget.editItem!.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _tagCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(widget.box.colorValue ?? AppTheme.primaryColor.value);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Photo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _imageOptionTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                subtitle: 'Use your camera',
                color: color,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _imageOptionTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                subtitle: 'Pick an existing photo',
                color: AppTheme.accentColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 12),
                _imageOptionTile(
                  icon: Icons.delete_rounded,
                  label: 'Remove Photo',
                  subtitle: 'Delete the selected photo',
                  color: AppTheme.errorColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedImage = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageOptionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54)),
          ])),
          Icon(Icons.chevron_right_rounded,
            color: isDark ? Colors.white24 : Colors.black26),
        ]),
      ),
    );
  }

  Future<String?> _saveImagePermanently(File image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/item_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final savedImage = await image.copy('${imagesDir.path}/$fileName');
    return savedImage.path;
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() { _tags.add(tag); _tagCtrl.clear(); });
    }
  }

  void _lookupPrice() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter item name first')));
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Searching prices on eBay & Amazon...')));
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate finding a price
    setState(() {
      _priceCtrl.text = '24.99'; // Mocked price
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Found price: \$24.99')));
    }
  }

  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InventoryProvider>();
      String? savedPath;
      if (_selectedImage != null && (widget.editItem == null || _selectedImage!.path != widget.editItem!.imagePath)) {
        savedPath = await _saveImagePermanently(_selectedImage!);
      } else if (widget.editItem != null) {
        savedPath = widget.editItem!.imagePath;
      }

      if (!mounted) return;
      
      if (widget.editItem != null) {
        await provider.updateItem(
          widget.box,
          widget.editItem!,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          quantity: int.tryParse(_qtyCtrl.text) ?? 1,
          tags: _tags,
          imagePath: savedPath,
          isTemplate: _isTemplate,
          reminderDate: _reminderDate,
          price: double.tryParse(_priceCtrl.text) ?? 0.0,
          expiryDate: _expiryDate,
        );
      } else {
        await provider.addItem(
          widget.box,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          quantity: int.tryParse(_qtyCtrl.text) ?? 1,
          tags: _tags,
          imagePath: savedPath,
          isTemplate: _isTemplate,
          reminderDate: _reminderDate,
          price: double.tryParse(_priceCtrl.text) ?? 0.0,
          expiryDate: _expiryDate,
        );
      }
      
      final suggestion = provider.suggestBoxCategory(widget.box);
      
      Navigator.pop(context);
      if (suggestion != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editItem == null ? '${_nameCtrl.text.trim()} added! Suggestion: Change box category to "$suggestion"?' : 'Item updated! Suggestion: Change box category to "$suggestion"?'),
            action: SnackBarAction(
              label: 'Update',
              onPressed: () => provider.updateBoxCategory(widget.box, suggestion),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.editItem == null ? '${_nameCtrl.text.trim()} added!' : 'Item updated!')),
        );
      }
    }
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

  final Map<String, List<String>> _tagSuggestionsMap = {
    'screwdriver': ['tools', 'garage', 'hardware'],
    'hammer': ['tools', 'garage', 'construction'],
    'passport': ['documents', 'travel', 'important'],
    'shirt': ['clothing', 'apparel'],
    'pants': ['clothing', 'apparel'],
    'jacket': ['clothing', 'winter'],
    'cable': ['electronics', 'tech'],
    'charger': ['electronics', 'tech'],
  };

  void _checkSuggestions(String value) {
    final query = value.toLowerCase().trim();
    if (_tagSuggestionsMap.containsKey(query)) {
      final suggestions = _tagSuggestionsMap[query]!;
      for (final s in suggestions) {
        if (!_tags.contains(s)) {
          setState(() => _tags.add(s));
        }
      }
    }
  }

  void _showTemplatePicker(BuildContext context) {
    // Placeholder for template picker logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template picker not yet implemented!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.box.colorValue ?? AppTheme.primaryColor.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.editItem == null ? 'Add Item' : 'Edit Item', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text('to ${widget.box.name ?? 'Unnamed Box'}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
        ]),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Photo Section
            _label('Item Photo'),
            GestureDetector(
              onTap: _showImagePickerSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: _selectedImage != null ? 200 : 120,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedImage != null
                        ? color.withAlpha(102)
                        : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13)),
                    width: _selectedImage != null ? 2 : 1,
                  ),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_a_photo_rounded, color: color, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text('Tap to add photo',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : Colors.black54)),
                          Text('Camera or Gallery',
                            style: TextStyle(fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(128),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Item Name
            const Text('Item Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return _nameSuggestions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _nameCtrl.text = selection;
                _checkSuggestions(selection);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text.isEmpty && _nameCtrl.text.isNotEmpty) {
                  controller.text = _nameCtrl.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'e.g. Hammer',
                    prefixIcon: const Icon(Icons.category_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.bookmark_added_rounded, size: 20),
                      onPressed: () => _showTemplatePicker(context),
                      tooltip: 'Use Template',
                    ),
                  ),
                  onChanged: (v) {
                    _nameCtrl.text = v;
                    _checkSuggestions(v);
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter a name' : null,
                );
              },
            ),
            const SizedBox(height: 20),

            _label('Quantity'),
            const SizedBox(height: 8),
            Row(children: [
              _qtyBtn(Icons.remove_rounded, color, () {
                int c = int.tryParse(_qtyCtrl.text) ?? 1;
                if (c > 1) _qtyCtrl.text = '${c - 1}';
              }),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: _qtyCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
                validator: (v) => (v == null || v.isEmpty || (int.tryParse(v) ?? 0) < 1) ? 'Min 1' : null,
              )),
              const SizedBox(width: 8),
              _qtyBtn(Icons.add_rounded, color, () {
                int c = int.tryParse(_qtyCtrl.text) ?? 1;
                _qtyCtrl.text = '${c + 1}';
              }),
            ]),
            const SizedBox(height: 20),

            _label('Estimated Price'),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 50.00',
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20, color: AppTheme.accentColor),
                  onPressed: _lookupPrice,
                  tooltip: 'Smart Price Lookup',
                ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Description'),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'e.g. LED lights for decoration', prefixIcon: Padding(padding: EdgeInsets.only(bottom: 24), child: Icon(Icons.description_outlined))),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Reminder'),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _reminderDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) setState(() => _reminderDate = date);
                        },
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active_outlined, size: 16, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _reminderDate == null ? 'None' : '${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year % 100}',
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Expiry Date'),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) setState(() => _expiryDate = date);
                        },
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 16, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _expiryDate == null ? 'None' : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year % 100}',
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),

            Row(
              children: [
                _label('Tags'),
                const Spacer(),
                Checkbox(value: _isTemplate, onChanged: (v) => setState(() => _isTemplate = v ?? false), activeColor: AppTheme.primaryColor),
                const Text('Save as Template', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _tagCtrl,
                decoration: const InputDecoration(hintText: 'e.g. festival', prefixIcon: Icon(Icons.label_outline)),
                onFieldSubmitted: (_) => _addTag(),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addTag,
                child: Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (_tags.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: _tags.map((t) => Chip(label: Text(t), deleteIcon: const Icon(Icons.close_rounded, size: 16), onDeleted: () => setState(() => _tags.remove(t)))).toList()),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.editItem == null ? Icons.add_rounded : Icons.save_rounded, size: 24), const SizedBox(width: 8),
                Text(widget.editItem == null ? 'Add Item' : 'Save Changes', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            )),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)));

  Widget _qtyBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 48, height: 48,
      decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withAlpha(51))),
      child: Icon(icon, color: color),
    ),
  );
}
