import '../app_database.dart';
import '../enums.dart';
import '../models/customer.dart';
import 'rate_repository.dart';

class CustomerRepository {
  final RateRepository _rates = RateRepository();

  Future<List<Customer>> all({bool activeOnly = true}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'customer',
      where: activeOnly ? 'active = 1' : null,
      orderBy: 'route_order ASC, name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<List<Customer>> search(String query) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'customer',
      where: 'active = 1 AND (name LIKE ? OR phone LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'route_order ASC, name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> byId(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('customer', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  /// Insert a new customer, creating its initial fixed-order rows and, if a
  /// custom rate was given, a customer-specific rate row effective today.
  Future<int> insert(Customer c, String todayKey) async {
    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      final id = await txn.insert('customer', c.toMap()..remove('id'));

      await txn.insert('fixed_order', {
        'customer_id': id,
        'shift': Shift.morning.code,
        'quantity': c.morningQty,
        'start_date': todayKey,
        'end_date': null,
      });
      if (c.eveningQty > 0) {
        await txn.insert('fixed_order', {
          'customer_id': id,
          'shift': Shift.evening.code,
          'quantity': c.eveningQty,
          'start_date': todayKey,
          'end_date': null,
        });
      }
      if (c.rate != null) {
        await txn.insert('rate', {
          'customer_id': id,
          'unit': c.unit.code,
          'price': c.rate,
          'effective_from': todayKey,
        });
      }
      return id;
    });
  }

  /// Update an existing customer. If the rate changed, a new rate row is added
  /// effective today so past bills keep their old rate (rate history).
  Future<void> update(Customer c, String todayKey) async {
    final db = await AppDatabase.instance.database;
    final existing = await byId(c.id!);
    await db.update('customer', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);

    if (c.rate != null && existing?.rate != c.rate) {
      await _rates.setCustomerRate(c.id!, c.unit, c.rate!, todayKey);
    }
  }

  Future<void> setActive(int id, bool active) async {
    final db = await AppDatabase.instance.database;
    await db.update('customer', {'active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await AppDatabase.instance.database;
    final r = await db
        .rawQuery('SELECT COUNT(*) c FROM customer WHERE active = 1');
    return (r.first['c'] as int?) ?? 0;
  }
}
