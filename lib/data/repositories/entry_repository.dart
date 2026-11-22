import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../enums.dart';
import '../models/customer.dart';
import '../models/daily_entry.dart';
import '../models/loose_sale.dart';
import 'rate_repository.dart';

class EntryRepository {
  final RateRepository _rates = RateRepository();

  // ---- Daily entries ---------------------------------------------------

  /// All entries for one date + shift, keyed by customer id.
  Future<Map<int, DailyEntry>> entriesFor(String dateKey, Shift shift) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'daily_entry',
      where: 'date = ? AND shift = ?',
      whereArgs: [dateKey, shift.code],
    );
    return {
      for (final r in rows)
        (r['customer_id'] as int): DailyEntry.fromMap(r),
    };
  }

  Future<DailyEntry?> entryFor(
      int customerId, String dateKey, Shift shift) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'daily_entry',
      where: 'customer_id = ? AND date = ? AND shift = ?',
      whereArgs: [customerId, dateKey, shift.code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyEntry.fromMap(rows.first);
  }

  /// Insert or replace an entry (UNIQUE on customer+date+shift upserts).
  Future<void> upsert(DailyEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'daily_entry',
      entry.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteEntry(int customerId, String dateKey, Shift shift) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'daily_entry',
      where: 'customer_id = ? AND date = ? AND shift = ?',
      whereArgs: [customerId, dateKey, shift.code],
    );
  }

  /// Mark a naga for one customer on one shift. Quantity is zero, no charge.
  Future<void> markNaga(
    Customer c,
    String dateKey,
    Shift shift,
    NagaReason? reason,
  ) async {
    final rate = await _rates.priceOn(c.id!, c.unit, dateKey);
    await upsert(DailyEntry(
      customerId: c.id!,
      date: dateKey,
      shift: shift,
      status: EntryStatus.naga,
      quantity: 0,
      rate: rate,
      unit: c.unit,
      nagaReason: reason,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  /// Record an extra. [totalQty] is the full quantity for the shift
  /// (fixed order + extra).
  Future<void> markExtra(
    Customer c,
    String dateKey,
    Shift shift,
    double totalQty,
  ) async {
    final rate = await _rates.priceOn(c.id!, c.unit, dateKey);
    await upsert(DailyEntry(
      customerId: c.id!,
      date: dateKey,
      shift: shift,
      status: EntryStatus.extra,
      quantity: totalQty,
      rate: rate,
      unit: c.unit,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  /// Record a plain delivered entry at the fixed order quantity.
  Future<void> markDelivered(
      Customer c, String dateKey, Shift shift) async {
    final qty = c.qtyForShift(shift);
    final rate = await _rates.priceOn(c.id!, c.unit, dateKey);
    await upsert(DailyEntry(
      customerId: c.id!,
      date: dateKey,
      shift: shift,
      status: EntryStatus.delivered,
      quantity: qty,
      rate: rate,
      unit: c.unit,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  /// Close the round: every active customer with a fixed order for this shift
  /// and no entry yet is saved as delivered. Returns how many were filled.
  Future<int> closeRound(
    List<Customer> customers,
    String dateKey,
    Shift shift,
  ) async {
    final existing = await entriesFor(dateKey, shift);
    int filled = 0;
    for (final c in customers) {
      if (c.qtyForShift(shift) <= 0) continue; // not on this shift
      if (existing.containsKey(c.id)) continue; // already naga/extra/delivered
      await markDelivered(c, dateKey, shift);
      filled++;
    }
    return filled;
  }

  /// True if the round for this date+shift has at least one saved delivered
  /// (or extra) entry — a rough "was this round closed?" signal.
  Future<bool> roundHasDeliveries(String dateKey, Shift shift) async {
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery(
      "SELECT COUNT(*) c FROM daily_entry WHERE date = ? AND shift = ? AND status != 'naga'",
      [dateKey, shift.code],
    );
    return ((r.first['c'] as int?) ?? 0) > 0;
  }

  /// Entries for one customer within a date range (inclusive), for billing and
  /// the khata calendar.
  Future<List<DailyEntry>> entriesForCustomerRange(
    int customerId,
    String fromKey,
    String toKey,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'daily_entry',
      where: 'customer_id = ? AND date >= ? AND date <= ?',
      whereArgs: [customerId, fromKey, toKey],
      orderBy: 'date ASC, shift ASC',
    );
    return rows.map(DailyEntry.fromMap).toList();
  }

  // ---- Loose sales -----------------------------------------------------

  /// Record a khula sale from a rupee amount; quantity is derived from rate.
  Future<void> addLooseSale({
    required String dateKey,
    required Shift shift,
    required double amountRs,
    required MilkUnit unit,
    required double rateUsed,
    int? customerId,
    String? note,
  }) async {
    final db = await AppDatabase.instance.database;
    final qty = rateUsed > 0 ? amountRs / rateUsed : 0.0;
    await db.insert('loose_sale', LooseSale(
      date: dateKey,
      shift: shift,
      amountRs: amountRs,
      rateUsed: rateUsed,
      quantityCalc: qty,
      unit: unit,
      customerId: customerId,
      note: note,
      createdAt: DateTime.now().toIso8601String(),
    ).toMap()..remove('id'));
  }

  Future<List<LooseSale>> looseSalesOn(String dateKey) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('loose_sale',
        where: 'date = ?', whereArgs: [dateKey], orderBy: 'created_at ASC');
    return rows.map(LooseSale.fromMap).toList();
  }

  Future<double> looseTotalOn(String dateKey) async {
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(amount_rs),0) s FROM loose_sale WHERE date = ?',
        [dateKey]);
    return (r.first['s'] as num?)?.toDouble() ?? 0;
  }
}
