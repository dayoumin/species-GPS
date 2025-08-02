import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/fishing_record.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'fishing_records.db';
  static const String _tableName = 'records';
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        species TEXT NOT NULL,
        count INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        photoPath TEXT,
        notes TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');
  }
  
  static Future<int> insertRecord(FishingRecord record) async {
    final db = await database;
    return await db.insert(
      _tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  static Future<List<FishingRecord>> getRecords({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'timestamp BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    } else if (startDate != null) {
      whereClause = 'timestamp >= ?';
      whereArgs = [startDate.millisecondsSinceEpoch];
    } else if (endDate != null) {
      whereClause = 'timestamp <= ?';
      whereArgs = [endDate.millisecondsSinceEpoch];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    
    return List.generate(maps.length, (i) {
      return FishingRecord.fromMap(maps[i]);
    });
  }
  
  static Future<FishingRecord?> getRecord(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return FishingRecord.fromMap(maps.first);
    }
    return null;
  }
  
  static Future<int> updateRecord(FishingRecord record) async {
    final db = await database;
    return await db.update(
      _tableName,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }
  
  static Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  static Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  static Future<Map<String, int>> getSpeciesCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT species, SUM(count) as total FROM $_tableName GROUP BY species'
    );
    
    Map<String, int> speciesCount = {};
    for (var row in result) {
      speciesCount[row['species']] = row['total'] as int;
    }
    return speciesCount;
  }
}