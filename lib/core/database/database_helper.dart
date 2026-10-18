import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/expense_item.dart';
import '../../models/expense_category.dart';

class DatabaseHelper {
  static const _dbName = 'vku_receipt_expenses.db';
  static const _dbVersion = 1;
  static const tableName = 'expenses';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // In-memory data store for Web platform
  final List<ExpenseItem> _webExpenses = [];
  int _nextWebId = 100;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Direct SQLite database access is not supported on web.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT,
        raw_ocr_text TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Insert
  Future<int> insertExpense(ExpenseItem item) async {
    if (kIsWeb) {
      final id = item.id ?? _nextWebId++;
      final newItem = ExpenseItem(
        id: id,
        merchant: item.merchant,
        amount: item.amount,
        date: item.date,
        category: item.category,
        imagePath: item.imagePath,
        rawOcrText: item.rawOcrText,
        createdAt: item.createdAt,
      );
      final existingIndex = _webExpenses.indexWhere((e) => e.id == id);
      if (existingIndex >= 0) {
        _webExpenses[existingIndex] = newItem;
      } else {
        _webExpenses.insert(0, newItem);
      }
      return id;
    }
    final db = await database;
    return await db.insert(
      tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update
  Future<int> updateExpense(ExpenseItem item) async {
    if (item.id == null) return -1;
    if (kIsWeb) {
      final index = _webExpenses.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        _webExpenses[index] = item;
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete
  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      final countBefore = _webExpenses.length;
      _webExpenses.removeWhere((item) => item.id == id);
      return countBefore - _webExpenses.length;
    }
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all expenses ordered by date descending
  Future<List<ExpenseItem>> getAllExpenses() async {
    if (kIsWeb) {
      final sorted = List<ExpenseItem>.from(_webExpenses);
      sorted.sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => ExpenseItem.fromMap(m)).toList();
  }

  // Get total expense amount
  Future<double> getTotalAmount() async {
    if (kIsWeb) {
      return _webExpenses.fold<double>(0.0, (sum, item) => sum + item.amount);
    }
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM $tableName');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Get total expense for specific month
  Future<double> getMonthTotal(int year, int month) async {
    if (kIsWeb) {
      return _webExpenses
          .where((item) => item.date.year == year && item.date.month == month)
          .fold<double>(0.0, (sum, item) => sum + item.amount);
    }
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $tableName WHERE date >= ? AND date <= ?',
      [start, end],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Category breakdown for charts
  Future<Map<String, double>> getCategoryTotals({int? year, int? month}) async {
    if (kIsWeb) {
      final Map<String, double> totals = {};
      final filtered = _webExpenses.where((item) {
        if (year != null && month != null) {
          return item.date.year == year && item.date.month == month;
        }
        return true;
      });
      for (final item in filtered) {
        totals[item.category] = (totals[item.category] ?? 0.0) + item.amount;
      }
      return totals;
    }
    final db = await database;
    List<Map<String, dynamic>> result;

    if (year != null && month != null) {
      final start = DateTime(year, month, 1).toIso8601String();
      final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
      result = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM $tableName WHERE date >= ? AND date <= ? GROUP BY category',
        [start, end],
      );
    } else {
      result = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM $tableName GROUP BY category',
      );
    }

    final Map<String, double> totals = {};
    for (final row in result) {
      final cat = row['category'] as String? ?? 'Khác';
      final sum = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[cat] = sum;
    }
    return totals;
  }

  // Daily totals for the last 7 days (for bar chart)
  Future<Map<DateTime, double>> getLast7DaysTotals() async {
    final now = DateTime.now();
    final Map<DateTime, double> dailyTotals = {};

    if (kIsWeb) {
      for (int i = 6; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final nextDay = day.add(const Duration(days: 1));
        final sum = _webExpenses
            .where((item) =>
                (item.date.isAfter(day) || item.date.isAtSameMomentAs(day)) &&
                item.date.isBefore(nextDay))
            .fold<double>(0.0, (prev, item) => prev + item.amount);
        dailyTotals[day] = sum;
      }
      return dailyTotals;
    }

    final db = await database;
    final Map<DateTime, double> dbDailyTotals = {};

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final start = day.toIso8601String();
      final end = day.add(const Duration(hours: 23, minutes: 59, seconds: 59)).toIso8601String();

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $tableName WHERE date >= ? AND date <= ?',
        [start, end],
      );
      final sum = (result.isNotEmpty && result.first['total'] != null)
          ? (result.first['total'] as num).toDouble()
          : 0.0;
      dbDailyTotals[day] = sum;
    }

    return dbDailyTotals;
  }

  // Seed sample initial data if empty (VKU club scenario)
  Future<void> seedInitialDataIfEmpty() async {
    final list = await getAllExpenses();
    if (list.isEmpty) {
      final now = DateTime.now();
      final sampleExpenses = [
        ExpenseItem(
          merchant: 'Nhà Sách FAHASA VKU',
          amount: 145000,
          date: now.subtract(const Duration(days: 1)),
          category: ExpenseCategoryType.stationery.label,
          rawOcrText: 'NHÀ SÁCH FAHASA\nGiấy A4 Double A: 95.000đ\nBút bi Thiên Long: 50.000đ\nTổng cộng: 145.000 VND',
        ),
        ExpenseItem(
          merchant: 'Highlands Coffee Hòa Quý',
          amount: 89000,
          date: now.subtract(const Duration(days: 2)),
          category: ExpenseCategoryType.foodAndBeverage.label,
          rawOcrText: 'HIGHLANDS COFFEE\n1 Freeze Trà Xanh L: 65.000\n1 Cà phê sữa đá M: 24.000\nTổng tiền: 89.000 đ',
        ),
        ExpenseItem(
          merchant: 'In Ấn & Photocopy Nam Kỳ',
          amount: 320000,
          date: now.subtract(const Duration(days: 3)),
          category: ExpenseCategoryType.clubEvent.label,
          rawOcrText: 'TIỆM IN ẤN NAM KỲ\nIn Backdrop sự kiện CLB: 250.000\nIn 50 Giấy mời: 70.000\nThành tiền: 320.000 VND',
        ),
        ExpenseItem(
          merchant: 'Grab - Đưa đón diễn giả CLB',
          amount: 68000,
          date: now.subtract(const Duration(days: 4)),
          category: ExpenseCategoryType.transportation.label,
          rawOcrText: 'GRAB VIETNAM\nChuyến đi: VKU -> Sân bay Đà Nẵng\nTổng cộng: 68.000 VND',
        ),
        ExpenseItem(
          merchant: 'Điện Máy Xanh Ngũ Hành Sơn',
          amount: 250000,
          date: now.subtract(const Duration(days: 5)),
          category: ExpenseCategoryType.equipment.label,
          rawOcrText: 'ĐIỆN MÁY XANH\nỔ cắm điện đa năng 5m: 150.000\nDây HDMI 5m: 100.000\nTổng tiền: 250.000 đ',
        ),
      ];

      for (final item in sampleExpenses) {
        await insertExpense(item);
      }
    }
  }
}
