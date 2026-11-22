import '../app_database.dart';
import '../enums.dart';
import '../models/rate.dart';

class RateRepository {
  Future<Rate?> _resolve(
      int customerId, MilkUnit unit, String dateKey) async {
    final db = await AppDatabase.instance.database;

    // Prefer a customer-specific rate effective on/before the date...
    final specific = await db.query(
      'rate',
      where: 'customer_id = ? AND unit = ? AND effective_from <= ?',
      whereArgs: [customerId, unit.code, dateKey],
      orderBy: 'effective_from DESC',
      limit: 1,
    );
    if (specific.isNotEmpty) return Rate.fromMap(specific.first);

    // ...otherwise the default rate for that unit.
    final def = await db.query(
      'rate',
      where: 'customer_id IS NULL AND unit = ? AND effective_from <= ?',
      whereArgs: [unit.code, dateKey],
      orderBy: 'effective_from DESC',
      limit: 1,
    );
    if (def.isNotEmpty) return Rate.fromMap(def.first);
    return null;
  }

  /// The price per unit for a customer on a given date, or 0 if none is set.
  Future<double> priceOn(int customerId, MilkUnit unit, String dateKey) async {
    final r = await _resolve(customerId, unit, dateKey);
    return r?.price ?? 0;
  }

  /// The current default price for a unit (used for walk-in loose sales).
  Future<double> defaultPrice(MilkUnit unit, String dateKey) async {
    final db = await AppDatabase.instance.database;
    final def = await db.query(
      'rate',
      where: 'customer_id IS NULL AND unit = ? AND effective_from <= ?',
      whereArgs: [unit.code, dateKey],
      orderBy: 'effective_from DESC',
      limit: 1,
    );
    return def.isEmpty ? 0 : Rate.fromMap(def.first).price;
  }

  /// Distinct rates a customer was charged across a date range, in order.
  /// Used to print "Rs 210 till 14th, Rs 220 from 15th" on a bill.
  Future<List<Rate>> customerRateChangesInRange(
    int customerId,
    MilkUnit unit,
    String fromKey,
    String toKey,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'rate',
      where:
          '(customer_id = ? OR customer_id IS NULL) AND unit = ? AND effective_from <= ?',
      whereArgs: [customerId, unit.code, toKey],
      orderBy: 'effective_from ASC',
    );
    return rows.map(Rate.fromMap).toList();
  }

  /// Set a new default rate from today.
  Future<void> setDefaultRate(
      MilkUnit unit, double price, String effectiveFrom) async {
    final db = await AppDatabase.instance.database;
    await db.insert('rate', {
      'customer_id': null,
      'unit': unit.code,
      'price': price,
      'effective_from': effectiveFrom,
    });
  }

  /// Record a customer-specific rate change effective from a date.
  Future<void> setCustomerRate(
    int customerId,
    MilkUnit unit,
    double price,
    String effectiveFrom,
  ) async {
    final db = await AppDatabase.instance.database;
    await db.insert('rate', {
      'customer_id': customerId,
      'unit': unit.code,
      'price': price,
      'effective_from': effectiveFrom,
    });
  }
}
