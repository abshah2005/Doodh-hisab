import '../../services/bill.dart';
import '../../util/date_util.dart';
import '../app_database.dart';
import '../enums.dart';
import '../models/customer.dart';
import '../models/daily_entry.dart';
import 'customer_repository.dart';
import 'entry_repository.dart';
import 'payment_repository.dart';

/// Overall numbers for one customer, shown in the Customers list and khata.
class CustomerBalance {
  final Customer customer;
  final double balance; // positive = owes
  const CustomerBalance(this.customer, this.balance);
}

/// Aggregates for the Hisaab (Reports) screen.
class ReportSummary {
  final double todaySales; // milk + loose, by amount
  final double monthSales;
  final int monthNagaCount;
  final int monthNagaCustomerAway;
  final int monthNagaSupplierMissed;
  final double monthPayments;
  final double totalOutstanding;

  const ReportSummary({
    required this.todaySales,
    required this.monthSales,
    required this.monthNagaCount,
    required this.monthNagaCustomerAway,
    required this.monthNagaSupplierMissed,
    required this.monthPayments,
    required this.totalOutstanding,
  });
}

/// Pulls stored rows and produces bills, balances and report aggregates.
class BillingRepository {
  final CustomerRepository _customers = CustomerRepository();
  final EntryRepository _entries = EntryRepository();
  final PaymentRepository _payments = PaymentRepository();

  /// Balance carried in at the start of [fromKey]: opening balance plus all
  /// milk charged before the range, minus all payments before the range.
  Future<double> _previousBalance(Customer c, String fromKey) async {
    final db = await AppDatabase.instance.database;

    final milkRow = await db.rawQuery(
      "SELECT COALESCE(SUM(quantity * rate),0) s FROM daily_entry "
      "WHERE customer_id = ? AND date < ? AND status != 'naga'",
      [c.id, fromKey],
    );
    final priorMilk = (milkRow.first['s'] as num?)?.toDouble() ?? 0;
    final priorPaid = await _payments.paidBefore(c.id!, fromKey);

    return c.openingBalance + priorMilk - priorPaid;
  }

  /// Build a bill for one customer over an arbitrary date range.
  Future<BillResult> bill(
    Customer c,
    DateTime from,
    DateTime to,
  ) async {
    final fromKey = DateUtil.toKey(from);
    final toKey = DateUtil.toKey(to);

    final entries =
        await _entries.entriesForCustomerRange(c.id!, fromKey, toKey);
    final payments =
        await _payments.forCustomerRange(c.id!, fromKey, toKey);
    final prev = await _previousBalance(c, fromKey);

    return BillCalculator.compute(
      customer: c,
      from: from,
      to: to,
      entries: entries,
      payments: payments,
      previousBalance: prev,
    );
  }

  /// Convenience: bill for the calendar month that [anyDayInMonth] falls in.
  Future<BillResult> monthlyBill(Customer c, DateTime anyDayInMonth) {
    return bill(
      c,
      DateUtil.firstOfMonth(anyDayInMonth),
      DateUtil.lastOfMonth(anyDayInMonth),
    );
  }

  /// Current balance for a customer as of today (all history).
  Future<double> currentBalance(Customer c) async {
    final db = await AppDatabase.instance.database;
    final milkRow = await db.rawQuery(
      "SELECT COALESCE(SUM(quantity * rate),0) s FROM daily_entry "
      "WHERE customer_id = ? AND status != 'naga'",
      [c.id],
    );
    final milk = (milkRow.first['s'] as num?)?.toDouble() ?? 0;

    final paidRow = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) s FROM payment WHERE customer_id = ?',
      [c.id],
    );
    final paid = (paidRow.first['s'] as num?)?.toDouble() ?? 0;

    return c.openingBalance + milk - paid;
  }

  /// Balances for every active customer (for the Customers list).
  Future<List<CustomerBalance>> allBalances() async {
    final customers = await _customers.all();
    final result = <CustomerBalance>[];
    for (final c in customers) {
      result.add(CustomerBalance(c, await currentBalance(c)));
    }
    return result;
  }

  /// Totals for the Hisaab screen.
  Future<ReportSummary> reportSummary(DateTime now) async {
    final db = await AppDatabase.instance.database;
    final todayKey = DateUtil.toKey(DateUtil.today());
    final monthFrom = DateUtil.toKey(DateUtil.firstOfMonth(now));
    final monthTo = DateUtil.toKey(DateUtil.lastOfMonth(now));

    Future<double> milkBetween(String a, String b) async {
      final r = await db.rawQuery(
        "SELECT COALESCE(SUM(quantity * rate),0) s FROM daily_entry "
        "WHERE date >= ? AND date <= ? AND status != 'naga'",
        [a, b],
      );
      return (r.first['s'] as num?)?.toDouble() ?? 0;
    }

    Future<double> looseBetween(String a, String b) async {
      final r = await db.rawQuery(
        'SELECT COALESCE(SUM(amount_rs),0) s FROM loose_sale '
        'WHERE date >= ? AND date <= ?',
        [a, b],
      );
      return (r.first['s'] as num?)?.toDouble() ?? 0;
    }

    final todaySales =
        await milkBetween(todayKey, todayKey) + await looseBetween(todayKey, todayKey);
    final monthSales =
        await milkBetween(monthFrom, monthTo) + await looseBetween(monthFrom, monthTo);

    final nagaRows = await db.rawQuery(
      "SELECT naga_reason, COUNT(*) c FROM daily_entry "
      "WHERE date >= ? AND date <= ? AND status = 'naga' GROUP BY naga_reason",
      [monthFrom, monthTo],
    );
    int nagaTotal = 0, away = 0, missed = 0;
    for (final row in nagaRows) {
      final c = (row['c'] as int?) ?? 0;
      nagaTotal += c;
      final reason = NagaReason.fromCode(row['naga_reason'] as String?);
      if (reason == NagaReason.customerRefused) away += c;
      if (reason == NagaReason.supplierMissed) missed += c;
    }

    final payRow = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) s FROM payment WHERE date >= ? AND date <= ?',
      [monthFrom, monthTo],
    );
    final monthPayments = (payRow.first['s'] as num?)?.toDouble() ?? 0;

    // Total outstanding across all customers = sum of positive balances.
    final balances = await allBalances();
    final outstanding = balances
        .where((b) => b.balance > 0)
        .fold<double>(0, (sum, b) => sum + b.balance);

    return ReportSummary(
      todaySales: todaySales,
      monthSales: monthSales,
      monthNagaCount: nagaTotal,
      monthNagaCustomerAway: away,
      monthNagaSupplierMissed: missed,
      monthPayments: monthPayments,
      totalOutstanding: outstanding,
    );
  }

  /// Entries for a customer in a month, keyed by `date` -> list of entries,
  /// for the khata calendar.
  Future<Map<String, List<DailyEntry>>> monthEntriesByDate(
      Customer c, DateTime anyDayInMonth) async {
    final from = DateUtil.toKey(DateUtil.firstOfMonth(anyDayInMonth));
    final to = DateUtil.toKey(DateUtil.lastOfMonth(anyDayInMonth));
    final entries = await _entries.entriesForCustomerRange(c.id!, from, to);
    final map = <String, List<DailyEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    return map;
  }
}
