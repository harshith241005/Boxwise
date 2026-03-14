import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../models/activity_model.dart';
import '../models/lending_model.dart';
import '../models/travel_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class InventoryProvider extends ChangeNotifier {
  List<BoxModel> _boxes = [];
  String _searchQuery = '';
  bool _isDarkMode = true;
  String _language = 'en';
  bool _usePinLock = false;
  String _appPin = '';
  Color _primaryColor = AppTheme.primaryColor;
  bool _showOnboarding = false;

  BoxModel? _lastDeletedBox;
  int? _lastDeletedBoxIndex;
  ItemModel? _lastDeletedItem;
  int? _lastDeletedItemIndex;
  BoxModel? _lastDeletedItemBox;

  final Set<String> _selectedItemIds = {};
  final Set<String> _selectedBoxIds = {};

  final Uuid _uuid = const Uuid();
  List<ActivityModel> _activities = [];
  List<LendingModel> _lendingLogs = [];
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, String>> _collaborators = [];
  List<Map<String, dynamic>> _plannerTasks = [];
  List<Map<String, dynamic>> _manualShoppingList = [];
  List<TravelModel> _travelLogs = [];
  TravelModel? _activeTravel;

  List<ActivityModel> get activities => _activities;
  List<LendingModel> get lendingLogs => _lendingLogs;
  List<Map<String, dynamic>> get scanHistory => _scanHistory;
  List<Map<String, String>> get collaborators => _collaborators;
  List<Map<String, dynamic>> get plannerTasks => _plannerTasks;
  List<Map<String, dynamic>> get manualShoppingList => _manualShoppingList;
  List<TravelModel> get travelLogs => _travelLogs;
  TravelModel? get activeTravel => _activeTravel;

  Future<void> _loadActivities() async {
    _activities = await DatabaseService.getActivities();
    notifyListeners();
  }

  Future<void> _loadScanHistory() async {
    _scanHistory = await DatabaseService.getScanHistory();
    notifyListeners();
  }

  Future<void> _loadPlannerTasks() async {
    final raw = await DatabaseService.getSetting('planner_tasks', defaultValue: []);
    if (raw is List) {
      _plannerTasks = raw
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _plannerTasks = decoded
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
        }
      } catch (_) {
        _plannerTasks = [];
      }
    } else {
      _plannerTasks = [];
    }
    notifyListeners();
  }

  Future<void> _persistPlannerTasks() async {
    await DatabaseService.setSetting('planner_tasks', _plannerTasks);
  }

  Future<void> logActivity(String type, String title, String subtitle, {String? relatedId}) async {
    final activity = ActivityModel(
      id: _uuid.v4(),
      type: type,
      title: title,
      subtitle: subtitle,
      timestamp: DateTime.now(),
      relatedId: relatedId,
    );
    await DatabaseService.addActivity(activity);
    await _loadActivities();
  }

  List<BoxModel> get boxes => _boxes;
  String get searchQuery => _searchQuery;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get usePinLock => _usePinLock;
  Color get primaryColor => _primaryColor;
  bool get showOnboarding => _showOnboarding;

  // Selection
  Set<String> get selectedItemIds => _selectedItemIds;
  Set<String> get selectedBoxIds => _selectedBoxIds;
  bool get isMultiSelectMode => _selectedItemIds.isNotEmpty || _selectedBoxIds.isNotEmpty;

  void toggleItemSelection(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
    } else {
      _selectedItemIds.add(id);
    }
    notifyListeners();
  }

  void toggleBoxSelection(String id) {
    if (_selectedBoxIds.contains(id)) {
      _selectedBoxIds.remove(id);
    } else {
      _selectedBoxIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedItemIds.clear();
    _selectedBoxIds.clear();
    notifyListeners();
  }

  int get totalBoxes => _boxes.length;
  int get totalItems =>
      _boxes.fold(0, (sum, box) => sum + box.items.length);
  int get totalQuantity =>
      _boxes.fold(0, (sum, box) => sum + box.totalQuantity);

  void addToShoppingList(BoxModel box, [ItemModel? item]) {
    final exists = _manualShoppingList.any((e) => 
      e['type'] == 'inventory' && 
      e['box'].id == box.id && 
      (item == null || e['item']?.id == item.id)
    );
    if (!exists) {
      _manualShoppingList.add({
        'id': _uuid.v4(),
        'type': 'inventory',
        'box': box,
        'item': item,
        'timestamp': DateTime.now(),
      });
      _persistShoppingList();
      notifyListeners();
    }
  }

  void addCustomToShoppingList(String name) {
    if (name.trim().isEmpty) return;
    _manualShoppingList.add({
      'id': _uuid.v4(),
      'type': 'custom',
      'name': name.trim(),
      'timestamp': DateTime.now(),
    });
    _persistShoppingList();
    notifyListeners();
  }

  void removeFromShoppingListById(String id) {
    _manualShoppingList.removeWhere((e) => e['id'] == id);
    _persistShoppingList();
    notifyListeners();
  }

  void removeFromShoppingList(String boxId, [String? itemId]) {
    _manualShoppingList.removeWhere((e) => 
      e['type'] == 'inventory' && 
      e['box'].id == boxId && 
      (itemId == null || e['item']?.id == itemId)
    );
    _persistShoppingList();
    notifyListeners();
  }

  void clearShoppingList() {
    _manualShoppingList.clear();
    _persistShoppingList();
    notifyListeners();
  }

  Future<void> _persistShoppingList() async {
    // We store minimal info to recreate the entries
    final data = _manualShoppingList.map((e) {
      if (e['type'] == 'inventory') {
        return {
          'type': 'inventory',
          'boxId': e['box'].id,
          'itemId': e['item']?.id,
          'timestamp': e['timestamp']?.toIso8601String(),
        };
      } else {
        return {
          'type': 'custom',
          'name': e['name'],
          'timestamp': e['timestamp']?.toIso8601String(),
        };
      }
    }).toList();
    await DatabaseService.setSetting('manual_shopping_list', data);
  }

  Future<void> _loadShoppingList() async {
    final raw = await DatabaseService.getSetting('manual_shopping_list', defaultValue: []);
    if (raw is List) {
      final List<Map<String, dynamic>> list = [];
      for (final entry in raw) {
        if (entry is Map) {
          if (entry['type'] == 'inventory') {
            final boxId = entry['boxId'];
            final itemId = entry['itemId'];
            final box = findBoxById(boxId);
            if (box != null) {
              final item = itemId != null ? box.items.firstWhereOrNull((i) => i.id == itemId) : null;
              list.add({
                'id': _uuid.v4(),
                'type': 'inventory',
                'box': box,
                'item': item,
                'timestamp': entry['timestamp'] != null ? DateTime.tryParse(entry['timestamp']) : null,
              });
            }
          } else if (entry['type'] == 'custom') {
            list.add({
              'id': _uuid.v4(),
              'type': 'custom',
              'name': entry['name'],
              'timestamp': entry['timestamp'] != null ? DateTime.tryParse(entry['timestamp']) : null,
            });
          }
        }
      }
      _manualShoppingList = list;
      notifyListeners();
    }
  }


  int get totalCategories =>
      _boxes.map((b) => b.category?.toString() ?? 'Other').toSet().length;

  double get totalInventoryValue =>
      _boxes.fold(0.0, (sum, box) => sum + box.items.fold(0.0, (iSum, item) => iSum + ((item.price ?? 0.0) * (item.quantity ?? 1))));

  double get totalSpaceUsage {
    int totalCap = _boxes.fold(0, (sum, box) => sum + (box.capacity ?? 0));
    if (totalCap == 0) return 0.0;
    return totalItems / totalCap;
  }

  List<Map<String, dynamic>> get expiringItems {
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (final box in _boxes) {
      for (final item in box.items) {
        if (item.expiryDate != null) {
          final diff = item.expiryDate!.difference(now).inDays;
          if (diff <= 7 && diff >= 0) {
            results.add({'box': box, 'item': item, 'days': diff});
          }
        }
      }
    }
    return results;
  }

  List<BoxModel> get recentBoxes {
    final sorted = List<BoxModel>.from(_boxes);
    sorted.sort(
        (a, b) => (b.lastAccessedDate ?? DateTime(2000)).compareTo(a.lastAccessedDate ?? DateTime(2000)));
    return sorted.take(5).toList();
  }

  List<MapEntry<BoxModel, int>> get topBoxesByItems {
    final sortedList = List<BoxModel>.from(_boxes);
    sortedList.sort((a, b) => b.items.length.compareTo(a.items.length));
    return sortedList
        .take(5)
        .map((b) => MapEntry(b, b.items.length))
        .toList();
  }

  Map<String, int> get categoryDistribution {
    final Map<String, int> dist = {};
    for (final box in _boxes) {
      final cat = box.category?.toString() ?? 'Other';
      dist[cat] = (dist[cat] ?? 0) + 1;
    }
    return dist;
  }

  List<MapEntry<String, int>> get topCategories {
    final dist = categoryDistribution;
    final sorted = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).toList();
  }

  List<Map<String, dynamic>> get lowStockItems {
    final results = <Map<String, dynamic>>[];
    for (final box in _boxes) {
      for (final item in box.items) {
        if ((item.quantity ?? 0) <= 1) {
          results.add({'box': box, 'item': item});
        }
      }
    }
    return results;
  }

  List<BoxModel> get favoriteBoxes => _boxes.where((b) => b.isFavorite).toList();

  Map<String, int> get locationHeatmap {
    final Map<String, int> heatmap = {};
    for (var box in _boxes) {
      if (box.location != null && box.location!.isNotEmpty) {
        heatmap[box.location!] = (heatmap[box.location!] ?? 0) + box.items.length;
      }
    }
    return heatmap;
  }

  Future<void> loadBoxes() async {
    _boxes = await DatabaseService.getAllBoxes();
    
    // Database Migration: Generate UUID for boxes that don't have one
    bool migrated = false;
    for (var box in _boxes) {
      if (box.uuid == null || box.uuid!.isEmpty) {
        String newUuid;
        while (true) {
          newUuid = _uuid.v4();
          final existingBox = await DatabaseService.getBoxByUuid(newUuid);
          if (existingBox == null) break;
        }
        box.uuid = newUuid;
        await box.save();
        migrated = true;
      }
    }
    
    if (migrated) {
      _boxes = await DatabaseService.getAllBoxes();
    }
    
    _boxes.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
    
    // Load persisted settings
    _isDarkMode = await DatabaseService.getSetting('dark_mode', defaultValue: true);
    _language = await DatabaseService.getSetting('language', defaultValue: 'en');
    _usePinLock = await DatabaseService.getSetting('use_pin_lock', defaultValue: false);
    _appPin = await DatabaseService.getSetting('app_pin', defaultValue: '');
    final colorVal = await DatabaseService.getSetting('primary_color', defaultValue: AppTheme.primaryColor.value);
    _primaryColor = Color(colorVal);

    _showOnboarding = await DatabaseService.getSetting('show_onboarding', defaultValue: true);

    final isFirstLaunch = await DatabaseService.getSetting('is_first_launch', defaultValue: true);
    if (isFirstLaunch) {
      await _generateDummyData();
      await DatabaseService.setSetting('is_first_launch', false);
    }

    await _loadActivities();
    await _loadScanHistory();
    await _loadLendingLogs();
    await _loadCollaborators();
    await _loadPlannerTasks();
    await generateSmartPlannerTasks();
    await loadTravelLogs();
    await _loadShoppingList();
    notifyListeners();
  }

  Future<void> _loadCollaborators() async {
    // Mocking collaborators for now (Advanced feature)
    _collaborators = [
      {'name': 'Harsh (You)', 'role': 'Admin', 'email': 'harsh@example.com'},
      {'name': 'Tanvi', 'role': 'Editor', 'email': 'tanvi@example.com'},
    ];
  }

  Future<void> inviteCollaborator(String email, String role) async {
    // In a real app, this would call Firebase
    _collaborators.add({'name': email.split('@')[0], 'role': role, 'email': email});
    await logActivity('collab_invited', 'Collaborator Invited', '$email was invited as $role');
    notifyListeners();
  }

  Future<void> _generateDummyData() async {
    // Box 1: Festival Clothes
    final box1 = BoxModel(
      id: "BOX_${_uuid.v4()}",
      uuid: _uuid.v4(),
      name: 'Festival Clothes',
      category: 'Clothing',
      location: 'Wardrobe',
      colorValue: const Color(0xFFE91E63).toARGB32(),
      createdDate: DateTime.now(),
    );
    await DatabaseService.addBox(box1);
    await DatabaseService.addItem(ItemModel(id: _uuid.v4(), name: 'Saree', quantity: 3), box1.id);
    await DatabaseService.addItem(ItemModel(id: _uuid.v4(), name: 'Kurta', quantity: 2), box1.id);

    // Box 2: Garage Tools
    final box2 = BoxModel(
      id: "BOX_${_uuid.v4()}",
      uuid: _uuid.v4(),
      name: 'Garage Tools',
      category: 'Tools',
      location: 'Garage',
      colorValue: const Color(0xFF607D8B).toARGB32(),
      createdDate: DateTime.now(),
    );
    await DatabaseService.addBox(box2);
    await DatabaseService.addItem(ItemModel(id: _uuid.v4(), name: 'Hammer', quantity: 1), box2.id);
    await DatabaseService.addItem(ItemModel(id: _uuid.v4(), name: 'Screwdriver', quantity: 2), box2.id);

    // Box 3: Documents Box
    final box3 = BoxModel(
      id: "BOX_${_uuid.v4()}",
      uuid: _uuid.v4(),
      name: 'Documents Box',
      category: 'Documents',
      location: 'Study Table',
      colorValue: const Color(0xFF3F51B5).toARGB32(),
      createdDate: DateTime.now(),
    );
    await DatabaseService.addBox(box3);
    await DatabaseService.addItem(ItemModel(id: _uuid.v4(), name: 'Passport', quantity: 2), box3.id);
    await DatabaseService.addItem(ItemModel(id: _uuid.v4(), name: 'Certificates', quantity: 10), box3.id);

    // Reload Data
    _boxes = await DatabaseService.getAllBoxes();
    _boxes.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
  }

  // --- Box CRUD ---
  Future<void> addBox({
    required String name,
    required String location,
    required String category,
    required int colorValue,
    int capacity = 0,
  }) async {
    String newUuid;
    while (true) {
      newUuid = _uuid.v4();
      final existingBox = await DatabaseService.getBoxByUuid(newUuid);
      if (existingBox == null) break;
    }

    final newBox = BoxModel(
      id: "BOX_${_uuid.v4()}",
      uuid: newUuid,
      name: name,
      location: location,
      category: category,
      colorValue: colorValue,
      capacity: capacity,
      createdDate: DateTime.now(),
    );
    await DatabaseService.addBox(newBox);
    _boxes.add(newBox);
    await logActivity('box_created', 'New Box Created', 'Box "${newBox.name}" was added to ${newBox.location}', relatedId: newBox.id);
    notifyListeners();
  }

  Future<void> updateBox(
    BoxModel box, {
    String? name,
    String? location,
    String? category,
    int? colorValue,
    int? capacity,
  }) async {
    String changes = '';
    if (name != null && box.name != name) {
      changes += 'Name changed from "${box.name}" to "$name". ';
      box.name = name;
    }
    if (location != null && box.location != location) {
      changes += 'Location changed from "${box.location}" to "$location". ';
      box.location = location;
    }
    if (category != null && box.category != category) {
      changes += 'Category changed from "${box.category}" to "$category". ';
      box.category = category;
    }
    if (colorValue != null && box.colorValue != colorValue) {
      changes += 'Color updated. ';
      box.colorValue = colorValue;
    }
    if (capacity != null && box.capacity != capacity) {
      changes += 'Capacity changed from "${box.capacity}" to "$capacity". ';
      box.capacity = capacity;
    }

    await box.save();
    if (changes.isNotEmpty) {
      await logActivity('box_updated', 'Box Updated', 'Box "${box.name}" details were updated: $changes', relatedId: box.id);
    } else {
      await logActivity('box_updated', 'Box Updated', 'Box "${box.name}" details were updated', relatedId: box.id);
    }
    notifyListeners();
  }

  Future<void> deleteBox(BoxModel box) async {
    _lastDeletedBox = box;
    _lastDeletedBoxIndex = _boxes.indexOf(box);
    await box.delete();
    _boxes.remove(box);
    await logActivity('box_deleted', 'Box Deleted', 'Box "${box.name}" was removed');
    notifyListeners();
  }

  Future<void> reorderBoxes(int oldIndex, int newIndex) async {
    final item = _boxes.removeAt(oldIndex);
    _boxes.insert(newIndex, item);
    
    // Update orderIndex for persistent storage
    for (int i = 0; i < _boxes.length; i++) {
      _boxes[i].orderIndex = i;
      await _boxes[i].save();
    }
    await logActivity('boxes_reordered', 'Boxes Reordered', 'The sorting order of boxes was updated');
    notifyListeners();
  }

  Future<void> toggleFavoriteBox(BoxModel box) async {
    box.isFavorite = !box.isFavorite;
    await box.save();
    notifyListeners();
  }

  Future<void> undoDeleteBox() async {
    if (_lastDeletedBox != null && _lastDeletedBoxIndex != null) {
      await DatabaseService.addBox(_lastDeletedBox!);
      for (var item in _lastDeletedBox!.items) {
        await DatabaseService.addItem(item, _lastDeletedBox!.id);
      }
      _boxes.insert(_lastDeletedBoxIndex!, _lastDeletedBox!);
      _lastDeletedBox = null;
      _lastDeletedBoxIndex = null;
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    DatabaseService.setSetting('dark_mode', _isDarkMode);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    DatabaseService.setSetting('language', lang);
    notifyListeners();
  }

  void togglePinLock(bool value) {
    _usePinLock = value;
    DatabaseService.setSetting('use_pin_lock', value);
    notifyListeners();
  }

  void setPin(String pin) {
    _appPin = pin;
    DatabaseService.setSetting('app_pin', pin);
    notifyListeners();
  }

  bool checkPin(String pin) => pin == _appPin;

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    DatabaseService.setSetting('primary_color', color.value);
    notifyListeners();
  }

  void finishOnboarding() {
    _showOnboarding = false;
    DatabaseService.setSetting('show_onboarding', false);
    notifyListeners();
  }

  // --- Scan History ---
  Future<void> logScan(String boxId, String boxName) async {
    await logActivity('box_scanned', 'Scanned Box', 'Scanned → $boxName', relatedId: boxId);
    await DatabaseService.addScanHistory(boxId, boxName);
    await _loadScanHistory();
  }

  // --- Lending ---
  Future<void> _loadLendingLogs() async {
    final maps = await DatabaseService.getAllLendingLogs();
    _lendingLogs = maps.map((e) => LendingModel.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> lendItem({
    required String itemId,
    required String itemName,
    required String borrowerName,
    DateTime? returnDate,
  }) async {
    final log = LendingModel(
      id: _uuid.v4(),
      itemId: itemId,
      itemName: itemName,
      borrowerName: borrowerName,
      lendDate: DateTime.now(),
      returnDate: returnDate,
      status: 'active',
    );
    await DatabaseService.addLendingLog(log.toMap());
    await _loadLendingLogs();
    await logActivity('item_lent', 'Item Lent', '$itemName was lent to $borrowerName', relatedId: itemId);
  }

  Future<void> returnItem(LendingModel log) async {
    final updatedLog = LendingModel(
      id: log.id,
      itemId: log.itemId,
      itemName: log.itemName,
      borrowerName: log.borrowerName,
      lendDate: log.lendDate,
      returnDate: log.returnDate,
      actualReturnDate: DateTime.now(),
      status: 'returned',
    );
    await DatabaseService.updateLendingLog(log.id, updatedLog.toMap());
    await _loadLendingLogs();
    await logActivity('item_returned', 'Item Returned', '${log.itemName} was returned by ${log.borrowerName}', relatedId: log.itemId);
  }

  Future<void> deleteLendingLog(String id) async {
    await DatabaseService.deleteLendingLog(id);
    await _loadLendingLogs();
  }

  Future<void> clearScanHistory() async {
    await DatabaseService.clearScanHistory();
    await _loadScanHistory();
  }

  Future<void> addPlannerTask({
    required String title,
    String type = 'custom',
    String? subtitle,
    DateTime? dueDate,
    String? relatedId,
  }) async {
    final task = <String, dynamic>{
      'id': _uuid.v4(),
      'title': title,
      'subtitle': subtitle ?? '',
      'type': type,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': false,
      'relatedId': relatedId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _plannerTasks.insert(0, task);
    await _persistPlannerTasks();
    notifyListeners();
  }

  Future<void> togglePlannerTask(String id, bool isCompleted) async {
    final index = _plannerTasks.indexWhere((task) => task['id'] == id);
    if (index == -1) return;
    _plannerTasks[index]['isCompleted'] = isCompleted;
    await _persistPlannerTasks();
    notifyListeners();
  }

  Future<void> removePlannerTask(String id) async {
    _plannerTasks.removeWhere((task) => task['id'] == id);
    await _persistPlannerTasks();
    notifyListeners();
  }

  Future<void> generateSmartPlannerTasks() async {
    final existingSignatures = _plannerTasks
        .map((task) => '${task['type']}::${task['title']}')
        .toSet();

    for (final low in lowStockItems.take(6)) {
      final item = low['item'];
      final box = low['box'];
      final title = 'Restock ${item.name ?? 'Item'}';
      final signature = 'restock::$title';
      if (!existingSignatures.contains(signature)) {
        _plannerTasks.add({
          'id': _uuid.v4(),
          'title': title,
          'subtitle': 'Low stock in ${box.name ?? 'Unknown Box'}',
          'type': 'restock',
          'dueDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'isCompleted': false,
          'relatedId': item.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
        existingSignatures.add(signature);
      }
    }

    for (final expiring in expiringItems.take(6)) {
      final item = expiring['item'];
      final days = expiring['days'];
      final title = 'Review expiry: ${item.name ?? 'Item'}';
      final signature = 'expiry::$title';
      if (!existingSignatures.contains(signature)) {
        _plannerTasks.add({
          'id': _uuid.v4(),
          'title': title,
          'subtitle': 'Expires in $days day(s)',
          'type': 'expiry',
          'dueDate': DateTime.now().add(Duration(days: days is int && days >= 0 ? days : 1)).toIso8601String(),
          'isCompleted': false,
          'relatedId': item.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
        existingSignatures.add(signature);
      }
    }

    for (final log in lendingLogs.where((entry) => entry.status == 'active').take(4)) {
      final title = 'Follow up: ${log.itemName}';
      final signature = 'lending::$title';
      if (!existingSignatures.contains(signature)) {
        _plannerTasks.add({
          'id': _uuid.v4(),
          'title': title,
          'subtitle': 'Borrowed by ${log.borrowerName}',
          'type': 'lending',
          'dueDate': (log.returnDate ?? DateTime.now().add(const Duration(days: 3))).toIso8601String(),
          'isCompleted': false,
          'relatedId': log.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
        existingSignatures.add(signature);
      }
    }

    _plannerTasks.sort((a, b) {
      final aDue = DateTime.tryParse((a['dueDate'] ?? '').toString()) ?? DateTime.now().add(const Duration(days: 3650));
      final bDue = DateTime.tryParse((b['dueDate'] ?? '').toString()) ?? DateTime.now().add(const Duration(days: 3650));
      return aDue.compareTo(bDue);
    });
    await _persistPlannerTasks();
    notifyListeners();
  }

  // --- Localization ---
  String translate(String key) {
    final Map<String, Map<String, String>> localizedStrings = {
      'en': {
        'dashboard': 'Dashboard',
        'boxes': 'Boxes',
        'search': 'Search',
        'scan': 'Scan',
        'settings': 'Settings',
        'total_boxes': 'Total Boxes',
        'low_stock': 'Low Stock Items',
        'add_box': 'Add Box',
      },
      'hi': {
        'dashboard': 'डैशबोर्ड',
        'boxes': 'बक्से',
        'search': 'खोज',
        'scan': 'स्कैन',
        'settings': 'सेटिंग्स',
        'total_boxes': 'कुल बक्से',
        'low_stock': 'कम स्टॉक वाली चीज़ें',
        'add_box': 'बॉक्स जोड़ें',
      },
       'te': {
        'dashboard': 'డాష్‌బోర్డ్',
        'boxes': 'పెట్టెలు',
        'search': 'శోధన',
        'scan': 'స్కాన్',
        'settings': 'సెట్టింగ్లు',
        'total_boxes': 'మొత్తం పెట్టెలు',
        'low_stock': 'తక్కువ స్టాక్ అంశాలు',
        'add_box': 'పెట్టెను జోడించండి',
      }
    };
    return localizedStrings[_language]?[key] ?? key;
  }

  Future<void> accessItem(BoxModel box, ItemModel item) async {
    box.lastAccessedDate = DateTime.now();
    await box.save();
    notifyListeners();
  }

  Future<void> accessBox(BoxModel box) async {
    box.lastAccessedDate = DateTime.now();
    await box.save();
    notifyListeners();
  }

  // --- Multi-Selection ---
  Future<void> deleteSelectedBoxes() async {
    final idsToDelete = _selectedBoxIds.toList();
    for (final id in idsToDelete) {
      try {
        final box = _boxes.firstWhere((b) => b.id == id);
        await deleteBox(box);
      } catch (e) {
        // Box might have been deleted already or not found
      }
    }
    _selectedBoxIds.clear();
    notifyListeners();
  }

  // --- Find by ID (for QR scanning) ---
  BoxModel? findBoxById(String id) {
    try {
      return _boxes.firstWhere((box) => box.id == id);
    } catch (_) {
      return null;
    }
  }

  BoxModel? findBoxByUuid(String uuid) {
    try {
      return _boxes.firstWhere((box) => box.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

  // --- Item CRUD ---

  Future<void> addItem(
    BoxModel box, {
    required String name,
    String description = '',
    int quantity = 1,
    List<String> tags = const [],
    String? imagePath,
    bool isTemplate = false,
    DateTime? reminderDate,
    double? price,
    DateTime? expiryDate,
  }) async {
    final item = ItemModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      quantity: quantity,
      tags: tags,
      imagePath: imagePath,
      isTemplate: isTemplate,
      reminderDate: reminderDate,
      price: price,
      expiryDate: expiryDate,
    );
    box.items.add(item);
    await DatabaseService.addItem(item, box.id);
    
    box.lastAccessedDate = DateTime.now();
    await box.save();
    await logActivity('item_added', 'Item Added', 'Item "${item.name}" added to ${box.name}', relatedId: item.id);
    notifyListeners();
  }

  Future<void> updateItem(
    BoxModel box,
    ItemModel item, {
    String? name,
    String? description,
    int? quantity,
    List<String>? tags,
    String? imagePath,
    bool? isTemplate,
    DateTime? reminderDate,
    double? price,
    DateTime? expiryDate,
  }) async {
    if (name != null) item.name = name;
    if (description != null) item.description = description;
    if (quantity != null) item.quantity = quantity;
    if (tags != null) item.tags = tags;
    if (imagePath != null) item.imagePath = imagePath;
    if (isTemplate != null) item.isTemplate = isTemplate;
    if (reminderDate != null) item.reminderDate = reminderDate;
    if (price != null) item.price = price;
    if (expiryDate != null) item.expiryDate = expiryDate;
    
    await DatabaseService.updateItem(item, box.id);
    await box.save();
    await logActivity('item_updated', 'Item Updated', 'Item "${item.name}" updated', relatedId: item.id);
    notifyListeners();
  }

  Future<void> updateBoxCategory(BoxModel box, String category) async {
    box.category = category;
    await box.save();
    notifyListeners();
  }

  String? suggestBoxCategory(BoxModel box) {
    if (box.items.isEmpty) return null;
    
    int tools = 0;
    int clothing = 0;
    int documents = 0;
    int electronics = 0;
    int kitchen = 0;

    for (var item in box.items) {
      final text = '${item.name} ${item.description} ${(item.tags).join(' ')}'.toLowerCase();
      if (text.contains('hammer') || text.contains('screwdriver') || text.contains('tape') || text.contains('tool') || text.contains('wrench')) tools++;
      if (text.contains('shirt') || text.contains('jeans') || text.contains('clothing') || text.contains('sock') || text.contains('jacket')) clothing++;
      if (text.contains('passport') || text.contains('document') || text.contains('id') || text.contains('file') || text.contains('certificate')) documents++;
      if (text.contains('laptop') || text.contains('phone') || text.contains('charger') || text.contains('cable') || text.contains('electronic')) electronics++;
      if (text.contains('plate') || text.contains('spoon') || text.contains('fork') || text.contains('kitchen') || text.contains('pan')) kitchen++;
    }

    final Map<String, int> counts = {
      'Tools': tools,
      'Clothing': clothing,
      'Documents': documents,
      'Electronics': electronics,
      'Kitchen': kitchen,
    };

    var maxCategory = 'Other';
    var maxCount = 0;
    
    counts.forEach((cat, count) {
      if (count > maxCount) {
        maxCount = count;
        maxCategory = cat;
      }
    });

    if (maxCount >= 1 && box.category != maxCategory) {
      return maxCategory;
    }
    
    return null;
  }

  Future<void> deleteItem(BoxModel box, ItemModel item) async {
    _lastDeletedItem = item;
    _lastDeletedItemIndex = box.items.indexOf(item);
    _lastDeletedItemBox = box;
    box.items.remove(item);
    await DatabaseService.deleteItem(item.id);
    await box.save();
    await logActivity('item_deleted', 'Item Deleted', 'Item "${item.name}" removed from ${box.name}', relatedId: item.id);
    notifyListeners();
  }

  Future<void> deleteSelectedItems(BoxModel box) async {
    final count = _selectedItemIds.length;
    final toDelete = box.items.where((i) => _selectedItemIds.contains(i.id)).toList();
    for(var item in toDelete) {
      await DatabaseService.deleteItem(item.id);
      box.items.remove(item);
    }
    await box.save();
    await logActivity('batch_action', 'Items Deleted', 'Removed $count items from ${box.name}');
    clearSelection();
  }

  Future<void> moveSelectedItems(String fromBoxId, String toBoxId) async {
    final fromBox = _boxes.firstWhere((b) => b.id == fromBoxId);
    final toBox = _boxes.firstWhere((b) => b.id == toBoxId);
    
    final itemsToMove = fromBox.items.where((i) => _selectedItemIds.contains(i.id)).toList();
    
    for (final item in itemsToMove) {
      fromBox.items.remove(item);
      toBox.items.add(item);
      await DatabaseService.updateItem(item, toBox.id);
    }
    
    await fromBox.save();
    await toBox.save();
    
    await logActivity('batch_action', 'Items Moved', 'Moved ${itemsToMove.length} items from ${fromBox.name} to ${toBox.name}');
    clearSelection();
  }

  Future<void> undoDeleteItem() async {
    if (_lastDeletedItem != null && _lastDeletedItemIndex != null && _lastDeletedItemBox != null) {
      _lastDeletedItemBox!.items.insert(_lastDeletedItemIndex!, _lastDeletedItem!);
      await DatabaseService.addItem(_lastDeletedItem!, _lastDeletedItemBox!.id);
      await _lastDeletedItemBox!.save();
      _lastDeletedItem = null;
      _lastDeletedItemIndex = null;
      _lastDeletedItemBox = null;
      notifyListeners();
    }
  }

  Future<void> incrementQuantity(BoxModel box, ItemModel item) async {
    item.quantity = (item.quantity ?? 0) + 1;
    await DatabaseService.updateItem(item, box.id);
    await box.save();
    notifyListeners();
  }

  Future<void> decrementQuantity(BoxModel box, ItemModel item) async {
    if ((item.quantity ?? 0) > 0) {
      item.quantity = (item.quantity ?? 0) - 1;
      await DatabaseService.updateItem(item, box.id);
      await box.save();
      notifyListeners();
    }
  }

  // --- Travel ---
  Future<void> loadTravelLogs() async {
    _travelLogs = await DatabaseService.getAllTravelLogs();
    final actives = _travelLogs.where((t) => !t.isCompleted).toList();
    if (actives.isNotEmpty) _activeTravel = actives.first;
    notifyListeners();
  }

  Future<void> startTravel({
    required String name,
    required String from,
    required String to,
    required List<BoxModel> selectedBoxes,
    String? notes,
  }) async {
    final newTravel = TravelModel(
      id: _uuid.v4(),
      tripName: name,
      fromLocation: from,
      toLocation: to,
      startTime: DateTime.now(),
      status: 'active',
      notes: notes,
      itemStatuses: selectedBoxes.map((box) => TravelItemStatus(
        boxId: box.id,
        boxName: box.name ?? 'Unnamed Box',
        location: box.location ?? 'Unknown',
        status: TravelStatus.pending,
        itemStatuses: box.items.map((item) => 
          TravelItemDetail(id: item.id, name: item.name ?? 'Unnamed', status: TravelStatus.pending)
        ).toList(),
      )).toList(),
    );

    _activeTravel = newTravel;
    _travelLogs.insert(0, newTravel);
    await DatabaseService.addTravelLog(newTravel);
    
    // We are NOT adding these boxes to DatabaseService.addBox because they are temporary for the trip.
    
    logActivity(
      'travel_started',
      'Travel Started: $name',
      'Moving ${selectedBoxes.length} boxes from $from to $to',
    );
    notifyListeners();
  }

  Future<void> updateTravelStatus(String travelId, String boxId, TravelStatus status) async {
    final travelIndex = _travelLogs.indexWhere((t) => t.id == travelId);
    if (travelIndex == -1) return;
    
    final itemStatus = _travelLogs[travelIndex].itemStatuses.firstWhere((isSet) => isSet.boxId == boxId);
    itemStatus.status = status;
    await DatabaseService.updateTravelLog(_travelLogs[travelIndex]);
    notifyListeners();
  }

  Future<void> updateTravelItemStatus(String travelId, String boxId, String itemId, TravelStatus status) async {
    final travelIndex = _travelLogs.indexWhere((t) => t.id == travelId);
    if (travelIndex == -1) return;
    
    final itemStatus = _travelLogs[travelIndex].itemStatuses.firstWhere((isSet) => isSet.boxId == boxId);
    final detailIndex = itemStatus.itemStatuses.indexWhere((i) => i.id == itemId);
    if (detailIndex != -1) {
        itemStatus.itemStatuses[detailIndex].status = status;
        await DatabaseService.updateTravelLog(_travelLogs[travelIndex]);
        notifyListeners();
    }
  }

  Future<void> endTravel(String travelId) async {
    final travelIndex = _travelLogs.indexWhere((t) => t.id == travelId);
    if (travelIndex == -1) return;
    
    final travel = _travelLogs[travelIndex];
    final updatedTravel = TravelModel(
      id: travel.id,
      tripName: travel.tripName,
      fromLocation: travel.fromLocation,
      toLocation: travel.toLocation,
      startTime: travel.startTime,
      endTime: DateTime.now(),
      status: 'completed',
      itemStatuses: travel.itemStatuses,
      notes: travel.notes,
    );
    _travelLogs[travelIndex] = updatedTravel;
    
    // TEMPORARY BOXES ONLY: We deliberately do NOT update _boxes locations 
    // because these boxes and items were created dynamically just for this trip 
    // and aren't in the main static inventory list.

    await DatabaseService.updateTravelLog(updatedTravel);
    if (_activeTravel?.id == travelId) _activeTravel = null;
    
    logActivity(
      'travel_completed',
      'Travel Completed: ${updatedTravel.tripName}',
      '${updatedTravel.fromLocation} → ${updatedTravel.toLocation}',
    );
    notifyListeners();
  }

  Future<void> removeFromTravel(String travelId, String boxId) async {
    final travelIndex = _travelLogs.indexWhere((t) => t.id == travelId);
    if (travelIndex == -1) return;
    
    _travelLogs[travelIndex].itemStatuses.removeWhere((s) => s.boxId == boxId);
    await DatabaseService.updateTravelLog(_travelLogs[travelIndex]);
    notifyListeners();
  }
  // --- Search ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Map<String, dynamic>> searchItems(
    String query, {
    List<String>? selectedTags,
    List<String>? selectedLocations,
    String? selectedBoxId,
    String? quantityCategory, // 'low', 'out', '1-5', '5-20', '20+'
    String? dateFilter, // 'today', '7days', '30days', 'older'
    String sortBy = 'name_asc', // 'name_asc', 'name_desc', 'newest', 'oldest', 'qty_high', 'qty_low'
    bool showTemplatesOnly = false,
  }) {
    final lowerQuery = query.toLowerCase().trim();
    List<Map<String, dynamic>> results = [];

    final now = DateTime.now();

    for (final box in _boxes) {
      if (selectedLocations != null && selectedLocations.isNotEmpty) {
        if (!selectedLocations.contains(box.location)) continue;
      }
      if (selectedBoxId != null && box.id != selectedBoxId) continue;

      for (final item in box.items) {
        if (showTemplatesOnly && !item.isTemplate) continue;

        // Quantity Filter
        if (quantityCategory != null) {
          final qty = item.quantity ?? 0;
          bool matchesQty = false;
          switch (quantityCategory) {
            case 'low': matchesQty = qty <= 1 && qty > 0; break;
            case 'out': matchesQty = qty == 0; break;
            case '1-5': matchesQty = qty >= 1 && qty <= 5; break;
            case '5-20': matchesQty = qty > 5 && qty <= 20; break;
            case '20+': matchesQty = qty > 20; break;
            default: matchesQty = true;
          }
          if (!matchesQty) continue;
        }

        // Date Filter
        if (dateFilter != null) {
          final created = box.createdDate ?? DateTime(2000);
          final diff = now.difference(created).inDays;
          bool matchesDate = false;
          switch (dateFilter) {
            case 'today': matchesDate = diff == 0; break;
            case '7days': matchesDate = diff <= 7; break;
            case '30days': matchesDate = diff <= 30; break;
            case 'older': matchesDate = diff > 30; break;
            default: matchesDate = true;
          }
          if (!matchesDate) continue;
        }

        // Tag Filter
        if (selectedTags != null && selectedTags.isNotEmpty) {
          if (!item.tags.any((t) => selectedTags.contains(t))) continue;
        }

        // Query Filter
        if (lowerQuery.isNotEmpty) {
          final matchesName = (item.name ?? '').toLowerCase().contains(lowerQuery);
          final matchesTags = (item.tags).any((tag) => tag.toLowerCase().contains(lowerQuery));
          final matchesBox = (box.name ?? '').toLowerCase().contains(lowerQuery);
          final matchesDesc = (item.description ?? '').toLowerCase().contains(lowerQuery);

          if (!(matchesName || matchesTags || matchesBox || matchesDesc)) continue;
        }

        results.add({
          'box': box,
          'item': item,
        });
      }
    }

    // Sorting
    results.sort((a, b) {
      final itemA = a['item'] as ItemModel;
      final itemB = b['item'] as ItemModel;
      final boxA = a['box'] as BoxModel;
      final boxB = b['box'] as BoxModel;

      switch (sortBy) {
        case 'name_asc': return (itemA.name ?? '').compareTo(itemB.name ?? '');
        case 'name_desc': return (itemB.name ?? '').compareTo(itemA.name ?? '');
        case 'newest': return (boxB.createdDate ?? DateTime(2000)).compareTo(boxA.createdDate ?? DateTime(2000));
        case 'oldest': return (boxA.createdDate ?? DateTime(2000)).compareTo(boxB.createdDate ?? DateTime(2000));
        case 'qty_high': return (itemB.quantity ?? 0).compareTo(itemA.quantity ?? 0);
        case 'qty_low': return (itemA.quantity ?? 0).compareTo(itemB.quantity ?? 0);
        default: return 0;
      }
    });

    return results;
  }

  // --- Locations ---
  List<String> get allLocations {
    final locs = _boxes.map((b) => b.location?.toString() ?? 'Unknown').toSet();
    final sorted = locs.toList()..sort();
    return sorted;
  }

  // --- Tags ---
  List<String> get allTags {
    final tagsArr = <String>{};
    for (final box in _boxes) {
      for (final item in box.items) {
        for (final tag in item.tags) {
           tagsArr.add(tag.toString());
        }
      }
    }
    final sorted = tagsArr.toList()..sort();
    return sorted;
  }

  // --- Export Data ---
  Future<void> exportToCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(['Box Name', 'Box Location', 'Box Category', 'Item Name', 'Quantity', 'Description', 'Tags']);

    for (var box in _boxes) {
      if (box.items.isEmpty) {
        rows.add([box.name, box.location, box.category, '', 0, '', '']);
      } else {
        for (var item in box.items) {
          rows.add([box.name, box.location, box.category, item.name, item.quantity, item.description, item.tags.join(', ')]);
        }
      }
    }

    String csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Boxvise_inventory.csv';
    final file = File(path);
    await file.writeAsString(csv);
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path)], text: 'Boxvise Inventory Export');
  }

  Future<void> exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Boxvise Inventory Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Generated on ${DateTime.now().toString().split(".")[0]}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Box', 'Location', 'Item', 'Qty', 'Tags'],
              data: _boxes.expand((b) => (b.items.isEmpty) ? [[b.name?.toString() ?? '', b.location?.toString() ?? '', '', '0', '']] : b.items.where((i) => i != null).map((i) => [b.name?.toString() ?? '', b.location?.toString() ?? '', i.name?.toString() ?? '', (i.quantity ?? 0).toString(), (i.tags).where((t) => t != null).join(', ')])).toList(),
              border: pw.TableBorder.all(width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Boxvise_inventory.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path)], text: 'Boxvise Inventory Export');
  }

  Future<void> importFromCSV(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    
    final input = await file.readAsString();
    final fields = const CsvToListConverter().convert(input);
    if (fields.length < 2) return;
    
    // Skip header row
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 3) continue;

      final boxName = row[0].toString();
      final boxLoc = row[1].toString();
      final boxCat = row[2].toString();
      
      var box = _boxes.where((b) => b.name == boxName).firstOrNull;
      if (box == null) {
        box = BoxModel(
          id: "BOX_${_uuid.v4()}",
          name: boxName,
          location: boxLoc,
          category: boxCat,
          colorValue: AppTheme.primaryColor.value,
          createdDate: DateTime.now(),
          items: [],
        );
        _boxes.add(box);
        await DatabaseService.addBox(box);
      }

      if (row.length >= 5 && row[3].toString().isNotEmpty) {
        final itemName = row[3].toString();
        final itemQty = int.tryParse(row[4].toString()) ?? 1;
        final itemDesc = row.length >= 6 ? row[5].toString() : '';
        final List<String> itemTags = (row.length >= 7 ? row[6].toString().split(',') : [])
            .map((t) => t.trim())
            .toList()
            .cast<String>();
        
        final item = ItemModel(
          id: _uuid.v4(),
          name: itemName,
          quantity: itemQty,
          description: itemDesc,
          tags: itemTags,
        );
        box.items.add(item);
        await DatabaseService.addItem(item, box.id);
        await box.save();
      }
    }
    notifyListeners();
  }

  Future<void> shareQrLabelPdf(BoxModel box) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Small label format
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(box.name ?? 'Unnamed', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: box.id,
                  width: 100,
                  height: 100,
                ),
                pw.SizedBox(height: 10),
                pw.Text(box.location ?? 'Unknown', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${box.id}_label.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'QR Label for ${box.name}');
  }

  Future<void> resetAllData() async {
    await DatabaseService.resetAllData();
    await loadBoxes();
    notifyListeners();
  }
}
