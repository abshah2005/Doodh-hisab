import '../app_database.dart';
import '../models/payment.dart';

class PaymentRepository {
  Future<int> add(Payment p) async {
    final db = await AppDatabase.instance.database;
    return db.insert('payment', p.toMap()..remove('id'));
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('payment', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Payment>> forCustomer(int customerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('payment',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'date DESC, id DESC');
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> forCustomerRange(
      int customerId, String fromKey, String toKey) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('payment',
        where: 'customer_id = ? AND date >= ? AND date <= ?',
        whereArgs: [customerId, fromKey, toKey],
        orderBy: 'date ASC, id ASC');
    return rows.map(Payment.fromMap).toList();
  }

  /// Total paid by a customer strictly before a date (for previous balance).
  Future<double> paidBefore(int customerId, String dateKey) async {
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) s FROM payment WHERE customer_id = ? AND date < ?',
      [customerId, dateKey],
    );
    return (r.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalOutstandingToday(String todayKey) async {
    // Computed in the billing service; this is a convenience for reports.
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) s FROM payment WHERE date = ?',
        [todayKey]);
    return (r.first['s'] as num?)?.toDouble() ?? 0;
  }
}
