import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../models/activity_model.dart';
import '../models/travel_model.dart';

class DatabaseService {
  static Database? _db;
  static const _uuid = Uuid();

  static Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'Boxvise_inventory.db');

    _db = await openDatabase(
      path,
      version: 8,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE boxes ADD COLUMN uuid TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE items ADD COLUMN price REAL');
          await db.execute('ALTER TABLE items ADD COLUMN expiryDate TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE lending_logs (
              id TEXT PRIMARY KEY,
              item_id TEXT,
              item_name TEXT,
              borrower_name TEXT,
              lend_date TEXT,
              return_date TEXT,
              actual_return_date TEXT,
              status TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE travel_logs (
              id TEXT PRIMARY KEY,
              name TEXT,
              fromLocation TEXT,
              toLocation TEXT,
              timestamp TEXT,
              itemStatuses TEXT,
              isCompleted INTEGER
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE travel_sessions (
              id TEXT PRIMARY KEY,
              trip_name TEXT,
              from_location TEXT,
              to_location TEXT,
              start_time TEXT,
              end_time TEXT,
              status TEXT,
              notes TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE travel_boxes (
              session_id TEXT,
              box_id TEXT,
              status TEXT,
              FOREIGN KEY(session_id) REFERENCES travel_sessions(id) ON DELETE CASCADE,
              FOREIGN KEY(box_id) REFERENCES boxes(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE travel_items (
              session_id TEXT,
              box_id TEXT,
              item_id TEXT,
              status TEXT,
              FOREIGN KEY(session_id) REFERENCES travel_sessions(id) ON DELETE CASCADE,
              FOREIGN KEY(box_id) REFERENCES travel_boxes(box_id) ON DELETE CASCADE,
              FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE travel_items ADD COLUMN item_name TEXT');
        }
      },
      onCreate: (db, version) async {
        // Boxes Table
        await db.execute('''
          CREATE TABLE boxes (
            id TEXT PRIMARY KEY,
            uuid TEXT,
            name TEXT,
            location TEXT,
            colorValue INTEGER,
            createdDate TEXT,
            lastAccessedDate TEXT,
            capacity INTEGER,
            orderIndex INTEGER,
            category TEXT,
            imagePath TEXT,
            isFavorite INTEGER
          )
        ''');

        // Items Table
        await db.execute('''
          CREATE TABLE items (
            id TEXT PRIMARY KEY,
            box_id TEXT,
            name TEXT,
            description TEXT,
            quantity INTEGER,
            createdDate TEXT,
            reminderDate TEXT,
            isTemplate INTEGER,
            imagePath TEXT,
            price REAL,
            expiryDate TEXT,
            FOREIGN KEY(box_id) REFERENCES boxes(id) ON DELETE CASCADE
          )
        ''');

        // Tags Table
        await db.execute('''
          CREATE TABLE tags (
            id TEXT PRIMARY KEY,
            name TEXT UNIQUE
          )
        ''');

        // Item Tags Association Table
        await db.execute('''
          CREATE TABLE item_tags (
            item_id TEXT,
            tag_id TEXT,
            PRIMARY KEY (item_id, tag_id),
            FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE,
            FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE
          )
        ''');

        // Scan History Table
        await db.execute('''
          CREATE TABLE scan_history (
            id TEXT PRIMARY KEY,
            box_id TEXT,
            box_name TEXT,
            scan_time TEXT,
            FOREIGN KEY(box_id) REFERENCES boxes(id) ON DELETE CASCADE
          )
        ''');

        // Activity Logs Table
        await db.execute('''
          CREATE TABLE activity_logs (
            id TEXT PRIMARY KEY,
            type TEXT,
            title TEXT,
            subtitle TEXT,
            timestamp TEXT,
            related_id TEXT
          )
        ''');

        // Settings Table (Key-Value)
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        // Lending Logs Table
        await db.execute('''
          CREATE TABLE lending_logs (
            id TEXT PRIMARY KEY,
            item_id TEXT,
            item_name TEXT,
            borrower_name TEXT,
            lend_date TEXT,
            return_date TEXT,
            actual_return_date TEXT,
            status TEXT
          )
        ''');

        // Travel Sessions Table
        await db.execute('''
          CREATE TABLE travel_sessions (
            id TEXT PRIMARY KEY,
            trip_name TEXT,
            from_location TEXT,
            to_location TEXT,
            start_time TEXT,
            end_time TEXT,
            status TEXT,
            notes TEXT
          )
        ''');

        // Travel Boxes Table
        await db.execute('''
          CREATE TABLE travel_boxes (
            session_id TEXT,
            box_id TEXT,
            status TEXT,
            FOREIGN KEY(session_id) REFERENCES travel_sessions(id) ON DELETE CASCADE,
            FOREIGN KEY(box_id) REFERENCES boxes(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  static Database get db {
    if (_db == null) throw Exception("Database not initialized");
    return _db!;
  }

  // --- Boxes ---
  static Future<List<BoxModel>> getAllBoxes() async {
    final List<Map<String, dynamic>> maps = await db.query('boxes');
    final List<BoxModel> boxes = [];
    
    for (var map in maps) {
      final items = await getItemsForBox(map['id']);
      boxes.add(BoxModel.fromMap(map, items: items));
    }
    return boxes;
  }

  static Future<BoxModel?> getBoxByUuid(String uuid) async {
    final List<Map<String, dynamic>> maps = await db.query('boxes', where: 'uuid = ?', whereArgs: [uuid]);
    if (maps.isEmpty) return null;
    final items = await getItemsForBox(maps.first['id']);
    return BoxModel.fromMap(maps.first, items: items);
  }

  static Future<void> addBox(BoxModel box) async {
    await db.insert('boxes', box.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateBox(BoxModel box) async {
    await db.update('boxes', box.toMap(), where: 'id = ?', whereArgs: [box.id]);
  }

  static Future<void> deleteBox(String id) async {
    await db.delete('items', where: 'box_id = ?', whereArgs: [id]);
    await db.delete('boxes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Items ---
  static Future<List<ItemModel>> getItemsForBox(String boxId) async {
    final List<Map<String, dynamic>> maps = await db.query('items', where: 'box_id = ?', whereArgs: [boxId]);
    final List<ItemModel> items = [];

    for (var map in maps) {
      final tags = await getTagsForItem(map['id']);
      items.add(ItemModel.fromMap(map, tags: tags));
    }
    return items;
  }

  static Future<void> addItem(ItemModel item, String boxId) async {
    await db.insert('items', item.toMap(boxId), conflictAlgorithm: ConflictAlgorithm.replace);
    await _updateItemTags(item.id, item.tags);
  }

  static Future<void> updateItem(ItemModel item, String boxId) async {
    await db.update('items', item.toMap(boxId), where: 'id = ?', whereArgs: [item.id]);
    await _updateItemTags(item.id, item.tags);
  }

  static Future<void> deleteItem(String itemId) async {
    await db.delete('item_tags', where: 'item_id = ?', whereArgs: [itemId]);
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  // --- Tags ---
  static Future<List<String>> getTagsForItem(String itemId) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT tags.name FROM tags
      JOIN item_tags ON tags.id = item_tags.tag_id
      WHERE item_tags.item_id = ?
    ''', [itemId]);
    return maps.map((e) => e['name'] as String).toList();
  }

  static Future<void> _updateItemTags(String itemId, List<String> tags) async {
    await db.delete('item_tags', where: 'item_id = ?', whereArgs: [itemId]);
    for (var tag in tags) {
      var tagRows = await db.query('tags', where: 'name = ?', whereArgs: [tag]);
      String tagId;
      if (tagRows.isEmpty) {
        tagId = _uuid.v4();
        await db.insert('tags', {'id': tagId, 'name': tag});
      } else {
        tagId = tagRows.first['id'] as String;
      }
      
      await db.insert('item_tags', {
        'item_id': itemId,
        'tag_id': tagId,
      });
    }
  }

  static Future<List<String>> getAllTags() async {
    final maps = await db.query('tags', columns: ['name']);
    return maps.map((e) => e['name'] as String).toList();
  }

  // --- Activity Logs ---
  static Future<List<ActivityModel>> getActivities() async {
    final maps = await db.query('activity_logs', orderBy: 'timestamp DESC');
    return maps.map((e) => ActivityModel.fromMap(e)).toList();
  }

  static Future<void> addActivity(ActivityModel activity) async {
    await db.insert('activity_logs', activity.toMap());
  }

  // --- Scan History ---
  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    return await db.query('scan_history', orderBy: 'scan_time DESC');
  }

  static Future<void> addScanHistory(String boxId, String boxName) async {
    await db.insert('scan_history', {
      'id': _uuid.v4(),
      'box_id': boxId,
      'box_name': boxName,
      'scan_time': DateTime.now().toIso8601String(),
    });
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM scan_history')) ?? 0;
    if (count > 50) {
      await db.rawQuery('''
        DELETE FROM scan_history 
        WHERE id IN (
          SELECT id FROM scan_history 
          ORDER BY scan_time DESC 
          LIMIT -1 OFFSET 50
        )
      ''');
    }
  }

  static Future<void> clearScanHistory() async {
    await db.delete('scan_history');
  }

  // --- Settings ---
  static Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return defaultValue;
    try {
      return jsonDecode(maps.first['value'] as String);
    } catch (_) {
      return maps.first['value'];
    }
  }

  static Future<void> setSetting(String key, dynamic value) async {
    final strValue = jsonEncode(value);
    await db.insert('settings', {'key': key, 'value': strValue}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Lending ---
  static Future<List<Map<String, dynamic>>> getAllLendingLogs() async {
    return await db.query('lending_logs', orderBy: 'lend_date DESC');
  }

  static Future<void> addLendingLog(Map<String, dynamic> log) async {
    await db.insert('lending_logs', log, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateLendingLog(String id, Map<String, dynamic> log) async {
    await db.update('lending_logs', log, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteLendingLog(String id) async {
    await db.delete('lending_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Travel Logs ---
  static Future<List<TravelModel>> getAllTravelLogs() async {
    final sessions = await db.query('travel_sessions', orderBy: 'start_time DESC');
    final List<TravelModel> models = [];

    for (var session in sessions) {
      final sessionId = session['id'] as String;
      final boxesMap = await db.rawQuery('''
        SELECT tb.box_id, tb.status, b.name as boxName, b.location as location
        FROM travel_boxes tb
        LEFT JOIN boxes b ON tb.box_id = b.id
        WHERE tb.session_id = ?
      ''', [sessionId]);

      final itemsMap = await db.rawQuery('''
        SELECT box_id, item_id, item_name, status
        FROM travel_items
        WHERE session_id = ?
      ''', [sessionId]);

      final items = boxesMap.map((b) {
        final boxId = b['box_id'] as String;
        final boxItems = itemsMap.where((i) => i['box_id'] == boxId);
        
        final List<TravelItemDetail> itemStatuses = [];
        for (var i in boxItems) {
            final tStat = TravelStatus.values.firstWhere(
                (e) => e.name == (i['status'] ?? 'pending'),
                orElse: () => TravelStatus.pending,
            );
            itemStatuses.add(TravelItemDetail(
                id: i['item_id'] as String,
                name: (i['item_name'] as String?) ?? 'Unnamed',
                status: tStat,
            ));
        }

        return TravelItemStatus.fromMap(
          b, 
          boxName: b['boxName'] as String?, 
          location: b['location'] as String?,
          items: itemStatuses,
        );
      }).toList();
      
      models.add(TravelModel.fromSessionMap(session, items));
    }

    return models;
  }

  static Future<void> addTravelLog(TravelModel log) async {
    await db.insert('travel_sessions', log.toSessionMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (var item in log.itemStatuses) {
      await db.insert('travel_boxes', item.toMap(log.id), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var detail in item.itemStatuses) {
        await db.insert('travel_items', {
          'session_id': log.id,
          'box_id': item.boxId,
          'item_id': detail.id,
          'item_name': detail.name,
          'status': detail.status.name,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  static Future<void> updateTravelLog(TravelModel log) async {
    await db.update('travel_sessions', log.toSessionMap(), where: 'id = ?', whereArgs: [log.id]);
    await db.delete('travel_boxes', where: 'session_id = ?', whereArgs: [log.id]);
    await db.delete('travel_items', where: 'session_id = ?', whereArgs: [log.id]);
    for (var item in log.itemStatuses) {
      await db.insert('travel_boxes', item.toMap(log.id), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var detail in item.itemStatuses) {
        await db.insert('travel_items', {
          'session_id': log.id,
          'box_id': item.boxId,
          'item_id': detail.id,
          'item_name': detail.name,
          'status': detail.status.name,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  static Future<void> deleteTravelLog(String id) async {
    await db.delete('travel_items', where: 'session_id = ?', whereArgs: [id]);
    await db.delete('travel_boxes', where: 'session_id = ?', whereArgs: [id]);
    await db.delete('travel_sessions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> resetAllData() async {
    await db.delete('items');
    await db.delete('boxes');
    await db.delete('tags');
    await db.delete('item_tags');
    await db.delete('scan_history');
    await db.delete('activity_logs');
    await db.delete('settings');
    await db.delete('lending_logs');
    await db.delete('travel_sessions');
    await db.delete('travel_boxes');
    await db.delete('travel_items');
  }
}
