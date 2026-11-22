import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../util/date_util.dart';
import 'enums.dart';

/// Opens and migrates the local SQLite database, and seeds a little demo data
/// on first run so the app is explorable immediately.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'doodh_hisaab.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE customer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT NOT NULL DEFAULT 'house',
        address_note TEXT,
        route_order INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'kg',
        morning_qty REAL NOT NULL DEFAULT 0,
        evening_qty REAL NOT NULL DEFAULT 0,
        rate REAL,
        opening_balance REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fixed_order (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        shift TEXT NOT NULL,
        quantity REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE rate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        effective_from TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_entry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        shift TEXT NOT NULL,
        status TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        rate REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'kg',
        naga_reason TEXT,
        note TEXT,
        edited INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE (customer_id, date, shift),
        FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE loose_sale (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        shift TEXT NOT NULL,
        amount_rs REAL NOT NULL,
        rate_used REAL NOT NULL,
        quantity_calc REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'kg',
        customer_id INTEGER,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL DEFAULT 'cash',
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE setting (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_entry_date ON daily_entry (date, shift)');
    await db.execute(
        'CREATE INDEX idx_entry_customer ON daily_entry (customer_id, date)');
    await db.execute(
        'CREATE INDEX idx_payment_customer ON payment (customer_id, date)');
    await db.execute('CREATE INDEX idx_loose_date ON loose_sale (date)');
  }

  /// A handful of realistic customers so the app opens with something to see.
  Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();
    final today = DateUtil.toKey(DateUtil.today());

    // Default rate for everyone: Rs 220/kg, Rs 210/L.
    await db.insert('rate', {
      'customer_id': null,
      'unit': MilkUnit.kg.code,
      'price': 220,
      'effective_from': '2000-01-01',
    });
    await db.insert('rate', {
      'customer_id': null,
      'unit': MilkUnit.litre.code,
      'price': 210,
      'effective_from': '2000-01-01',
    });

    Future<void> addCustomer({
      required String name,
      String? phone,
      CustomerType type = CustomerType.house,
      String? addressNote,
      required int order,
      MilkUnit unit = MilkUnit.kg,
      double morning = 0,
      double evening = 0,
      double? rate,
      double opening = 0,
    }) async {
      final id = await db.insert('customer', {
        'name': name,
        'phone': phone,
        'type': type.code,
        'address_note': addressNote,
        'route_order': order,
        'unit': unit.code,
        'morning_qty': morning,
        'evening_qty': evening,
        'rate': rate,
        'opening_balance': opening,
        'active': 1,
        'created_at': now,
      });
      await db.insert('fixed_order', {
        'customer_id': id,
        'shift': Shift.morning.code,
        'quantity': morning,
        'start_date': today,
        'end_date': null,
      });
      if (evening > 0) {
        await db.insert('fixed_order', {
          'customer_id': id,
          'shift': Shift.evening.code,
          'quantity': evening,
          'start_date': today,
          'end_date': null,
        });
      }
      if (rate != null) {
        await db.insert('rate', {
          'customer_id': id,
          'unit': unit.code,
          'price': rate,
          'effective_from': today,
        });
      }
    }

    await addCustomer(
      name: 'Rashid Sahab',
      phone: '03001234567',
      addressNote: 'House 12, Gali 4',
      order: 1,
      morning: 2,
      opening: 500,
    );
    await addCustomer(
      name: 'Bilal Chacha',
      addressNote: 'Corner house, blue gate',
      order: 2,
      morning: 1,
      evening: 1,
    );
    await addCustomer(
      name: 'Tea Stall (Adda)',
      phone: '03111234567',
      type: CustomerType.shop,
      addressNote: 'Main road tea stall',
      order: 3,
      morning: 10,
      rate: 215,
    );
    await addCustomer(
      name: 'Ayesha Baji',
      order: 4,
      unit: MilkUnit.litre,
      morning: 1.5,
    );
    await addCustomer(
      name: 'Imran Shop',
      type: CustomerType.shop,
      addressNote: 'General store',
      order: 5,
      morning: 5,
      evening: 3,
      opening: 1200,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
